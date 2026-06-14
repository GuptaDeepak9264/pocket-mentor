from pydantic import BaseModel
from typing import Optional, Any
from datetime import datetime


class SyncChange(BaseModel):
    table: str           # "cards", "srs_records", "topics", "study_sessions"
    operation: str       # "create", "update", "delete"
    record_id: str
    payload: dict[str, Any]
    client_updated_at: datetime


class SyncPushRequest(BaseModel):
    changes: list[SyncChange]
    last_sync_at: Optional[datetime] = None


class SyncConflict(BaseModel):
    record_id: str
    table: str
    resolution: str      # "server_wins" | "client_wins"
    server_value: dict[str, Any]
    client_value: dict[str, Any]


class SyncPushResponse(BaseModel):
    accepted: int
    rejected: int
    conflicts: list[SyncConflict]
    server_time: datetime


class SyncPullResponse(BaseModel):
    changes: list[dict[str, Any]]
    server_time: datetime
    has_more: bool
