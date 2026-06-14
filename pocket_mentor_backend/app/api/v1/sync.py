from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from typing import Optional
from datetime import datetime

from app.db.session import get_db
from app.db.models.user import User
from app.core.dependencies import get_current_active_user
from app.schemas.sync import SyncPushRequest, SyncPushResponse, SyncPullResponse
from app.services.sync_service import process_push, process_pull

router = APIRouter(prefix="/sync", tags=["sync"])


@router.post("/push", response_model=SyncPushResponse)
async def sync_push(
    body: SyncPushRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """
    Client pushes batched local changes to the server.
    Server applies them and returns accepted/rejected counts + conflict details.
    """
    return await process_push(
        db=db,
        user_id=current_user.id,
        changes=body.changes,
        last_sync_at=body.last_sync_at,
    )


@router.get("/pull", response_model=SyncPullResponse)
async def sync_pull(
    since: Optional[datetime] = Query(None, description="ISO timestamp of last successful pull"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """
    Client pulls all server-side changes since the given timestamp.
    On first sync, omit `since` to pull everything.
    """
    return await process_pull(
        db=db,
        user_id=current_user.id,
        since=since,
    )
