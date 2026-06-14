from datetime import datetime
from typing import Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_, func
from sqlalchemy.orm import joinedload

from app.db.models.card import Card, CardType
from app.db.models.srs_record import SRSRecord
from app.db.models.topic import Topic
from app.schemas.feed import FeedCard


async def get_learn_feed(
    db: AsyncSession,
    user_id: str,
    topic_id: Optional[str] = None,
    limit: int = 20,
) -> list[FeedCard]:
    query = (
        select(Card, Topic, SRSRecord)
        .join(Topic, Card.topic_id == Topic.id)
        .outerjoin(SRSRecord, Card.id == SRSRecord.card_id)
        .where(Card.user_id == user_id)
        .where(Card.card_type == CardType.learn)
    )
    if topic_id:
        query = query.where(Card.topic_id == topic_id)

    query = query.order_by(
        func.coalesce(SRSRecord.repetitions, 0).asc(),
        func.coalesce(SRSRecord.last_review_at, datetime.min).asc(),
    ).limit(limit)

    result = await db.execute(query)
    rows = result.all()

    feed = []
    for card, topic, srs in rows:
        feed.append(FeedCard(
            id=card.id,
            topic_id=card.topic_id,
            topic_title=topic.title,
            topic_color=topic.color_tag,
            question=card.question,
            answer=card.answer,
            hint=card.hint,
            difficulty=card.difficulty,
            card_type=card.card_type,
            interval_days=srs.interval_days if srs else 1,
            repetitions=srs.repetitions if srs else 0,
            next_review_at=srs.next_review_at if srs else datetime.utcnow(),
        ))
    return feed


async def get_revision_feed(
    db: AsyncSession,
    user_id: str,
    limit: int = 50,
) -> tuple[list[FeedCard], int, int]:
    now = datetime.utcnow()

    query = (
        select(Card, Topic, SRSRecord)
        .join(Topic, Card.topic_id == Topic.id)
        .join(SRSRecord, Card.id == SRSRecord.card_id)
        .where(Card.user_id == user_id)
        .where(SRSRecord.next_review_at <= now)
        .order_by(SRSRecord.next_review_at.asc())
    )

    result = await db.execute(query)
    rows = result.all()

    today_start = now.replace(hour=0, minute=0, second=0, microsecond=0)
    due_today = sum(1 for _, _, srs in rows if srs.next_review_at >= today_start)
    overdue = len(rows) - due_today

    feed = []
    for card, topic, srs in rows[:limit]:
        feed.append(FeedCard(
            id=card.id,
            topic_id=card.topic_id,
            topic_title=topic.title,
            topic_color=topic.color_tag,
            question=card.question,
            answer=card.answer,
            hint=card.hint,
            difficulty=card.difficulty,
            card_type=card.card_type,
            interval_days=srs.interval_days,
            repetitions=srs.repetitions,
            next_review_at=srs.next_review_at,
        ))

    return feed, due_today, overdue


async def get_interview_feed(
    db: AsyncSession,
    user_id: str,
    topic_id: Optional[str] = None,
    difficulty: Optional[int] = None,
    limit: int = 20,
) -> list[FeedCard]:
    query = (
        select(Card, Topic, SRSRecord)
        .join(Topic, Card.topic_id == Topic.id)
        .outerjoin(SRSRecord, Card.id == SRSRecord.card_id)
        .where(Card.user_id == user_id)
        .where(Card.card_type == CardType.interview)
    )
    if topic_id:
        query = query.where(Card.topic_id == topic_id)
    if difficulty:
        query = query.where(Card.difficulty == difficulty)

    query = query.order_by(
        func.coalesce(SRSRecord.last_review_at, datetime.min).asc(),
    ).limit(limit)

    result = await db.execute(query)
    rows = result.all()

    feed = []
    for card, topic, srs in rows:
        feed.append(FeedCard(
            id=card.id,
            topic_id=card.topic_id,
            topic_title=topic.title,
            topic_color=topic.color_tag,
            question=card.question,
            answer=card.answer,
            hint=card.hint,
            difficulty=card.difficulty,
            card_type=card.card_type,
            interval_days=srs.interval_days if srs else 1,
            repetitions=srs.repetitions if srs else 0,
            next_review_at=srs.next_review_at if srs else datetime.utcnow(),
        ))
    return feed
