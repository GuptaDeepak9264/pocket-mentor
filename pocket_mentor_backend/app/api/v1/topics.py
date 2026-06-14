from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func

from app.db.session import get_db
from app.db.models.topic import Topic
from app.db.models.card import Card
from app.db.models.user import User
from app.db.base import generate_uuid
from app.core.dependencies import get_current_active_user
from app.core.exceptions import NotFoundException, ForbiddenException
from app.schemas.topic import TopicCreate, TopicUpdate, TopicResponse, TopicListResponse
from app.schemas.auth import MessageResponse

router = APIRouter(prefix="/topics", tags=["topics"])


async def _get_topic_or_404(topic_id: str, user_id: str, db: AsyncSession) -> Topic:
    result = await db.execute(select(Topic).where(Topic.id == topic_id))
    topic = result.scalar_one_or_none()
    if not topic:
        raise NotFoundException("Topic")
    if topic.user_id != user_id:
        raise ForbiddenException("You do not own this topic")
    return topic


async def _enrich_topic(topic: Topic, db: AsyncSession) -> TopicResponse:
    count_result = await db.execute(
        select(func.count(Card.id)).where(Card.topic_id == topic.id)
    )
    card_count = count_result.scalar() or 0
    return TopicResponse(
        id=topic.id,
        user_id=topic.user_id,
        title=topic.title,
        description=topic.description,
        color_tag=topic.color_tag,
        icon=topic.icon,
        is_public=topic.is_public,
        card_count=card_count,
        created_at=topic.created_at,
        updated_at=topic.updated_at,
    )


@router.get("", response_model=TopicListResponse)
async def list_topics(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    result = await db.execute(
        select(Topic)
        .where(Topic.user_id == current_user.id)
        .order_by(Topic.created_at.desc())
    )
    topics = result.scalars().all()
    enriched = [await _enrich_topic(t, db) for t in topics]
    return TopicListResponse(topics=enriched, total=len(enriched))


@router.post("", response_model=TopicResponse, status_code=status.HTTP_201_CREATED)
async def create_topic(
    body: TopicCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    topic = Topic(
        id=generate_uuid(),
        user_id=current_user.id,
        title=body.title,
        description=body.description,
        color_tag=body.color_tag,
        icon=body.icon,
        is_public=body.is_public,
    )
    db.add(topic)
    await db.flush()
    return await _enrich_topic(topic, db)


@router.get("/{topic_id}", response_model=TopicResponse)
async def get_topic(
    topic_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    topic = await _get_topic_or_404(topic_id, current_user.id, db)
    return await _enrich_topic(topic, db)


@router.patch("/{topic_id}", response_model=TopicResponse)
async def update_topic(
    topic_id: str,
    body: TopicUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    topic = await _get_topic_or_404(topic_id, current_user.id, db)

    if body.title is not None:
        topic.title = body.title
    if body.description is not None:
        topic.description = body.description
    if body.color_tag is not None:
        topic.color_tag = body.color_tag
    if body.icon is not None:
        topic.icon = body.icon
    if body.is_public is not None:
        topic.is_public = body.is_public

    return await _enrich_topic(topic, db)


@router.delete("/{topic_id}", response_model=MessageResponse)
async def delete_topic(
    topic_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    topic = await _get_topic_or_404(topic_id, current_user.id, db)
    await db.delete(topic)
    return MessageResponse(message=f"Topic '{topic.title}' deleted successfully")
