"""
Sync Service — handles offline-first push/pull reconciliation.

Conflict resolution strategy: server_wins on timestamp conflict,
unless the client change is strictly newer than the server record.
"""

from datetime import datetime
from typing import Any
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, text

from app.schemas.sync import SyncChange, SyncConflict, SyncPushResponse, SyncPullResponse

SYNCABLE_TABLES = {"cards", "srs_records", "topics", "study_sessions"}


async def process_push(
    db: AsyncSession,
    user_id: str,
    changes: list[SyncChange],
    last_sync_at: datetime | None,
) -> SyncPushResponse:
    accepted = 0
    rejected = 0
    conflicts: list[SyncConflict] = []

    for change in changes:
        if change.table not in SYNCABLE_TABLES:
            rejected += 1
            continue

        try:
            conflict = await _apply_change(db, user_id, change)
            if conflict:
                conflicts.append(conflict)
                rejected += 1
            else:
                accepted += 1
        except Exception:
            rejected += 1

    return SyncPushResponse(
        accepted=accepted,
        rejected=rejected,
        conflicts=conflicts,
        server_time=datetime.utcnow(),
    )


async def _apply_change(
    db: AsyncSession,
    user_id: str,
    change: SyncChange,
) -> SyncConflict | None:
    """
    Apply a single client change to the server DB.
    Returns a SyncConflict if the change could not be applied cleanly.
    """
    table = change.table
    record_id = change.record_id
    payload = change.payload

    # Safety: strip user_id from payload and force server's user_id
    payload["user_id"] = user_id

    if change.operation == "delete":
        await db.execute(
            text(f"DELETE FROM {table} WHERE id = :id AND user_id = :user_id"),
            {"id": record_id, "user_id": user_id},
        )
        return None

    # Check server timestamp to detect conflicts
    existing = await db.execute(
        text(f"SELECT updated_at FROM {table} WHERE id = :id AND user_id = :user_id"),
        {"id": record_id, "user_id": user_id},
    )
    row = existing.fetchone()

    if row is not None:
        server_updated_at: datetime = row[0]
        client_updated_at: datetime = change.client_updated_at

        if server_updated_at and server_updated_at > client_updated_at:
            # Server is newer — server wins
            server_row = await db.execute(
                text(f"SELECT * FROM {table} WHERE id = :id"),
                {"id": record_id},
            )
            server_data = dict(server_row.mappings().fetchone() or {})
            return SyncConflict(
                record_id=record_id,
                table=table,
                resolution="server_wins",
                server_value=server_data,
                client_value=payload,
            )

        # Client is newer or same — update server
        set_clause = ", ".join(f"{k} = :{k}" for k in payload if k != "id")
        params = {**payload, "id": record_id, "user_id": user_id}
        await db.execute(
            text(f"UPDATE {table} SET {set_clause} WHERE id = :id AND user_id = :user_id"),
            params,
        )
    else:
        # Insert new record
        payload["id"] = record_id
        cols = ", ".join(payload.keys())
        vals = ", ".join(f":{k}" for k in payload.keys())
        await db.execute(
            text(f"INSERT INTO {table} ({cols}) VALUES ({vals})"),
            payload,
        )

    return None


async def process_pull(
    db: AsyncSession,
    user_id: str,
    since: datetime | None,
) -> SyncPullResponse:
    """
    Return all server-side records updated since `since` timestamp.
    """
    changes = []
    server_time = datetime.utcnow()
    since_ts = since or datetime(2000, 1, 1)

    for table in SYNCABLE_TABLES:
        try:
            result = await db.execute(
                text(
                    f"SELECT * FROM {table} "
                    f"WHERE user_id = :user_id AND updated_at > :since "
                    f"ORDER BY updated_at ASC LIMIT 500"
                ),
                {"user_id": user_id, "since": since_ts},
            )
            rows = result.mappings().fetchall()
            for row in rows:
                changes.append({"table": table, "record": dict(row)})
        except Exception:
            pass  # Table may not have updated_at — skip

    return SyncPullResponse(
        changes=changes,
        server_time=server_time,
        has_more=False,
    )
