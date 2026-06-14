from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from typing import Optional

from app.db.session import get_db
from app.db.models.user import User
from app.core.dependencies import get_current_active_user
from app.schemas.feed import LearnFeedResponse, RevisionFeedResponse, InterviewFeedResponse
from app.services.feed_service import get_learn_feed, get_revision_feed, get_interview_feed

router = APIRouter(prefix="/feed", tags=["feed"])


@router.get("/learn", response_model=LearnFeedResponse)
async def learn_feed(
    topic_id: Optional[str] = Query(None, description="Filter by topic ID"),
    limit: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """
    Returns the Learn feed for the current user.
    Cards are ordered: unseen first, then least-recently reviewed.
    """
    cards = await get_learn_feed(db, current_user.id, topic_id=topic_id, limit=limit)
    return LearnFeedResponse(
        cards=cards,
        total=len(cards),
        topic_id=topic_id,
    )


@router.get("/revision", response_model=RevisionFeedResponse)
async def revision_feed(
    limit: int = Query(50, ge=1, le=200),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """
    Returns cards scheduled for revision today using SM-2 SRS.
    Includes overdue cards sorted by most-overdue first.
    """
    cards, due_today, overdue = await get_revision_feed(db, current_user.id, limit=limit)
    return RevisionFeedResponse(
        cards=cards,
        due_today=due_today,
        overdue=overdue,
    )


@router.get("/interview", response_model=InterviewFeedResponse)
async def interview_feed(
    topic_id: Optional[str] = Query(None),
    difficulty: Optional[int] = Query(None, ge=1, le=5),
    limit: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """
    Returns cards for Interview Prep mode.
    Optionally filtered by topic and difficulty level.
    """
    cards = await get_interview_feed(
        db, current_user.id,
        topic_id=topic_id,
        difficulty=difficulty,
        limit=limit,
    )
    return InterviewFeedResponse(
        cards=cards,
        total=len(cards),
        topic_id=topic_id,
        difficulty_filter=difficulty,
    )
