from datetime import datetime, date, timedelta
from typing import Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_

from app.db.models.streak import UserStreak
from app.db.models.session import StudySession
from app.db.models.card import Card
from app.db.models.srs_record import SRSRecord
from app.db.models.topic import Topic
from app.db.base import generate_uuid
from app.schemas.progress import (
    StreakResponse, HeatmapEntry, TopicProgress, ProgressSummaryResponse,
)


async def get_or_create_streak(db: AsyncSession, user_id: str) -> UserStreak:
    result = await db.execute(
        select(UserStreak).where(UserStreak.user_id == user_id)
    )
    streak = result.scalar_one_or_none()
    if not streak:
        streak = UserStreak(id=generate_uuid(), user_id=user_id)
        db.add(streak)
        await db.flush()
    return streak


async def update_streak_after_session(
    db: AsyncSession,
    user_id: str,
    cards_reviewed: int,
) -> UserStreak:
    streak = await get_or_create_streak(db, user_id)
    today = date.today()

    if streak.last_active_date is None:
        streak.current_streak = 1
    elif streak.last_active_date == today:
        pass  # Already active today, no change
    elif streak.last_active_date == today - timedelta(days=1):
        streak.current_streak += 1
    else:
        # Streak broken
        streak.current_streak = 1

    streak.last_active_date = today
    streak.total_cards_reviewed += cards_reviewed
    streak.total_sessions += 1

    if streak.current_streak > streak.longest_streak:
        streak.longest_streak = streak.current_streak

    return streak


async def get_heatmap(
    db: AsyncSession,
    user_id: str,
    days: int = 90,
) -> list[HeatmapEntry]:
    since = datetime.utcnow() - timedelta(days=days)

    result = await db.execute(
        select(
            func.date(StudySession.started_at).label("day"),
            func.sum(StudySession.cards_reviewed).label("cards"),
            func.count(StudySession.id).label("sessions"),
        )
        .where(StudySession.user_id == user_id)
        .where(StudySession.started_at >= since)
        .group_by(func.date(StudySession.started_at))
        .order_by(func.date(StudySession.started_at).asc())
    )
    rows = result.all()

    return [
        HeatmapEntry(
            date=date.fromisoformat(str(row.day)),
            cards_reviewed=row.cards or 0,
            sessions=row.sessions or 0,
        )
        for row in rows
    ]


async def get_topic_progress(
    db: AsyncSession,
    user_id: str,
) -> list[TopicProgress]:
    now = datetime.utcnow()

    # Topics with card counts
    topics_result = await db.execute(
        select(Topic).where(Topic.user_id == user_id)
    )
    topics = topics_result.scalars().all()

    progress_list = []
    for topic in topics:
        # Total cards in topic
        total_result = await db.execute(
            select(func.count(Card.id))
            .where(Card.topic_id == topic.id)
            .where(Card.user_id == user_id)
        )
        total_cards = total_result.scalar() or 0

        # Cards with repetitions > 2 are considered "known"
        known_result = await db.execute(
            select(func.count(SRSRecord.id))
            .join(Card, SRSRecord.card_id == Card.id)
            .where(Card.topic_id == topic.id)
            .where(SRSRecord.user_id == user_id)
            .where(SRSRecord.repetitions >= 3)
        )
        cards_known = known_result.scalar() or 0

        # Cards due today
        due_result = await db.execute(
            select(func.count(SRSRecord.id))
            .join(Card, SRSRecord.card_id == Card.id)
            .where(Card.topic_id == topic.id)
            .where(SRSRecord.user_id == user_id)
            .where(SRSRecord.next_review_at <= now)
        )
        cards_due = due_result.scalar() or 0

        mastery = (cards_known / total_cards * 100) if total_cards > 0 else 0.0

        progress_list.append(TopicProgress(
            topic_id=topic.id,
            topic_title=topic.title,
            topic_color=topic.color_tag,
            total_cards=total_cards,
            cards_known=cards_known,
            cards_due_today=cards_due,
            mastery_percent=round(mastery, 1),
        ))

    return progress_list


async def get_progress_summary(
    db: AsyncSession,
    user_id: str,
    daily_goal: int = 20,
) -> ProgressSummaryResponse:
    now = datetime.utcnow()
    today_start = now.replace(hour=0, minute=0, second=0, microsecond=0)
    week_start = now - timedelta(days=7)

    # Today's cards reviewed
    today_result = await db.execute(
        select(func.sum(StudySession.cards_reviewed))
        .where(StudySession.user_id == user_id)
        .where(StudySession.started_at >= today_start)
    )
    today_cards = today_result.scalar() or 0

    # Sessions this week
    week_result = await db.execute(
        select(func.count(StudySession.id))
        .where(StudySession.user_id == user_id)
        .where(StudySession.started_at >= week_start)
    )
    sessions_week = week_result.scalar() or 0

    # Total cards in library
    total_result = await db.execute(
        select(func.count(Card.id)).where(Card.user_id == user_id)
    )
    total_cards = total_result.scalar() or 0

    # Total cards due today
    due_result = await db.execute(
        select(func.count(SRSRecord.id))
        .where(SRSRecord.user_id == user_id)
        .where(SRSRecord.next_review_at <= now)
    )
    cards_due = due_result.scalar() or 0

    streak = await get_or_create_streak(db, user_id)
    topic_progress = await get_topic_progress(db, user_id)

    return ProgressSummaryResponse(
        streak=StreakResponse(
            current_streak=streak.current_streak,
            longest_streak=streak.longest_streak,
            last_active_date=streak.last_active_date,
            total_cards_reviewed=streak.total_cards_reviewed,
            total_sessions=streak.total_sessions,
        ),
        today_cards_reviewed=today_cards,
        today_goal=daily_goal,
        today_goal_met=today_cards >= daily_goal,
        sessions_this_week=sessions_week,
        total_cards_in_library=total_cards,
        cards_due_today=cards_due,
        topic_progress=topic_progress,
    )
