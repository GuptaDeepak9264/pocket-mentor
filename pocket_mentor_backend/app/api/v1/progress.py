from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from typing import Optional
from datetime import datetime

from app.db.session import get_db
from app.db.models.session import StudySession
from app.db.models.user import User
from app.db.base import generate_uuid
from app.core.dependencies import get_current_active_user
from app.schemas.progress import (
    SessionCreate, SessionResponse, SessionListResponse,
    StreakResponse, HeatmapResponse, ProgressSummaryResponse,
)
from app.services.analytics_service import (
    get_progress_summary,
    update_streak_after_session,
    get_heatmap,
    get_or_create_streak,
)

router = APIRouter(prefix="/progress", tags=["progress"])


def _session_to_response(session: StudySession) -> SessionResponse:
    accuracy = 0.0
    if session.cards_reviewed > 0:
        accuracy = round(session.cards_known / session.cards_reviewed * 100, 1)
    return SessionResponse(
        id=session.id,
        user_id=session.user_id,
        topic_id=session.topic_id,
        mode=session.mode,
        cards_reviewed=session.cards_reviewed,
        cards_known=session.cards_known,
        cards_unknown=session.cards_unknown,
        duration_seconds=session.duration_seconds,
        accuracy_percent=accuracy,
        started_at=session.started_at,
        ended_at=session.ended_at,
    )


@router.get("/summary", response_model=ProgressSummaryResponse)
async def progress_summary(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Returns full progress overview: streak, today goal, topic breakdown, due cards."""
    daily_goal = current_user.settings.get("daily_goal", 20)
    return await get_progress_summary(db, current_user.id, daily_goal)


@router.post("/sessions", response_model=SessionResponse, status_code=status.HTTP_201_CREATED)
async def create_session(
    body: SessionCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Called by the Flutter app when a study session ends."""
    session = StudySession(
        id=generate_uuid(),
        user_id=current_user.id,
        topic_id=body.topic_id,
        mode=body.mode,
        cards_reviewed=body.cards_reviewed,
        cards_known=body.cards_known,
        cards_unknown=body.cards_unknown,
        duration_seconds=body.duration_seconds,
        started_at=body.started_at,
        ended_at=body.ended_at or datetime.utcnow(),
    )
    db.add(session)
    await db.flush()

    # Update streak
    await update_streak_after_session(db, current_user.id, body.cards_reviewed)

    return _session_to_response(session)


@router.get("/sessions", response_model=SessionListResponse)
async def list_sessions(
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
    topic_id: Optional[str] = Query(None),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    query = (
        select(StudySession)
        .where(StudySession.user_id == current_user.id)
        .order_by(StudySession.started_at.desc())
    )
    if topic_id:
        query = query.where(StudySession.topic_id == topic_id)

    count_result = await db.execute(
        select(func.count()).select_from(query.subquery())
    )
    total = count_result.scalar() or 0

    query = query.limit(limit).offset(offset)
    result = await db.execute(query)
    sessions = result.scalars().all()

    return SessionListResponse(
        sessions=[_session_to_response(s) for s in sessions],
        total=total,
    )


@router.get("/streak", response_model=StreakResponse)
async def get_streak(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    streak = await get_or_create_streak(db, current_user.id)
    return StreakResponse(
        current_streak=streak.current_streak,
        longest_streak=streak.longest_streak,
        last_active_date=streak.last_active_date,
        total_cards_reviewed=streak.total_cards_reviewed,
        total_sessions=streak.total_sessions,
    )


@router.get("/heatmap", response_model=HeatmapResponse)
async def get_heatmap_data(
    days: int = Query(90, ge=7, le=365),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    entries = await get_heatmap(db, current_user.id, days=days)
    return HeatmapResponse(entries=entries, period_days=days)
