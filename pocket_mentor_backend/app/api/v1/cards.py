from fastapi import APIRouter, Depends, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.db.session import get_db
from app.db.models.card import Card, CardType, CardSource
from app.db.models.srs_record import SRSRecord
from app.db.models.topic import Topic
from app.db.models.user import User
from app.db.base import generate_uuid
from app.core.dependencies import get_current_active_user
from app.core.exceptions import NotFoundException, ForbiddenException
from app.schemas.card import (
    CardCreate, CardUpdate, CardResponse, CardListResponse,
    CardResponseRequest, CardResponseResult, SRSInfo,
)
from app.schemas.auth import MessageResponse
from app.services.srs_service import calculate_next_review, create_initial_srs_record

router = APIRouter(tags=["cards"])


# ─── Helpers ──────────────────────────────────────────────────────────────────

async def _get_card_or_404(card_id: str, user_id: str, db: AsyncSession) -> Card:
    result = await db.execute(select(Card).where(Card.id == card_id))
    card = result.scalar_one_or_none()
    if not card:
        raise NotFoundException("Card")
    if card.user_id != user_id:
        raise ForbiddenException("You do not own this card")
    return card


async def _get_topic_or_404(topic_id: str, user_id: str, db: AsyncSession) -> Topic:
    result = await db.execute(select(Topic).where(Topic.id == topic_id))
    topic = result.scalar_one_or_none()
    if not topic:
        raise NotFoundException("Topic")
    if topic.user_id != user_id:
        raise ForbiddenException("You do not own this topic")
    return topic


def _build_card_response(card: Card) -> CardResponse:
    srs_info = None
    if card.srs_record:
        srs = card.srs_record
        srs_info = SRSInfo(
            ease_factor=srs.ease_factor,
            interval_days=srs.interval_days,
            repetitions=srs.repetitions,
            next_review_at=srs.next_review_at,
            last_review_at=srs.last_review_at,
            last_response=srs.last_response,
        )
    return CardResponse(
        id=card.id,
        topic_id=card.topic_id,
        user_id=card.user_id,
        question=card.question,
        answer=card.answer,
        hint=card.hint,
        difficulty=card.difficulty,
        card_type=card.card_type,
        source=card.source,
        source_file_id=card.source_file_id,
        srs_info=srs_info,
        created_at=card.created_at,
        updated_at=card.updated_at,
    )


# ─── Routes ───────────────────────────────────────────────────────────────────

@router.get("/topics/{topic_id}/cards", response_model=CardListResponse)
async def list_cards(
    topic_id: str,
    card_type: CardType | None = Query(None),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    await _get_topic_or_404(topic_id, current_user.id, db)

    query = (
        select(Card)
        .where(Card.topic_id == topic_id)
        .where(Card.user_id == current_user.id)
        .order_by(Card.created_at.desc())
    )
    if card_type:
        query = query.where(Card.card_type == card_type)

    result = await db.execute(query)
    cards = result.scalars().all()

    # Eagerly load SRS records
    for card in cards:
        srs_result = await db.execute(
            select(SRSRecord).where(SRSRecord.card_id == card.id)
        )
        card.srs_record = srs_result.scalar_one_or_none()

    return CardListResponse(
        cards=[_build_card_response(c) for c in cards],
        total=len(cards),
    )


@router.post("/topics/{topic_id}/cards", response_model=CardResponse, status_code=status.HTTP_201_CREATED)
async def create_card(
    topic_id: str,
    body: CardCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    await _get_topic_or_404(topic_id, current_user.id, db)

    card = Card(
        id=generate_uuid(),
        topic_id=topic_id,
        user_id=current_user.id,
        question=body.question,
        answer=body.answer,
        hint=body.hint,
        difficulty=body.difficulty,
        card_type=body.card_type,
        source=CardSource.manual,
    )
    db.add(card)
    await db.flush()

    # Create initial SRS record
    srs_data = create_initial_srs_record(card.id, current_user.id)
    srs = SRSRecord(id=generate_uuid(), **srs_data)
    db.add(srs)
    await db.flush()

    card.srs_record = srs
    return _build_card_response(card)


@router.get("/cards/{card_id}", response_model=CardResponse)
async def get_card(
    card_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    card = await _get_card_or_404(card_id, current_user.id, db)
    srs_result = await db.execute(select(SRSRecord).where(SRSRecord.card_id == card.id))
    card.srs_record = srs_result.scalar_one_or_none()
    return _build_card_response(card)


@router.patch("/cards/{card_id}", response_model=CardResponse)
async def update_card(
    card_id: str,
    body: CardUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    card = await _get_card_or_404(card_id, current_user.id, db)

    if body.question is not None:
        card.question = body.question
    if body.answer is not None:
        card.answer = body.answer
    if body.hint is not None:
        card.hint = body.hint
    if body.difficulty is not None:
        card.difficulty = body.difficulty
    if body.card_type is not None:
        card.card_type = body.card_type

    srs_result = await db.execute(select(SRSRecord).where(SRSRecord.card_id == card.id))
    card.srs_record = srs_result.scalar_one_or_none()
    return _build_card_response(card)


@router.delete("/cards/{card_id}", response_model=MessageResponse)
async def delete_card(
    card_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    card = await _get_card_or_404(card_id, current_user.id, db)
    await db.delete(card)
    return MessageResponse(message="Card deleted successfully")


@router.post("/cards/{card_id}/response", response_model=CardResponseResult)
async def submit_card_response(
    card_id: str,
    body: CardResponseRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """
    Submit Know / Don't Know for a card.
    Triggers SM-2 SRS recalculation and returns the updated schedule.
    """
    card = await _get_card_or_404(card_id, current_user.id, db)

    srs_result = await db.execute(
        select(SRSRecord).where(SRSRecord.card_id == card.id)
    )
    srs = srs_result.scalar_one_or_none()

    if not srs:
        srs_data = create_initial_srs_record(card.id, current_user.id)
        srs = SRSRecord(id=generate_uuid(), **srs_data)
        db.add(srs)
        await db.flush()

    updates = calculate_next_review(srs, body.result)
    for key, value in updates.items():
        setattr(srs, key, value)

    return CardResponseResult(
        card_id=card.id,
        result=body.result,
        next_review_at=srs.next_review_at,
        interval_days=srs.interval_days,
        ease_factor=srs.ease_factor,
        message=f"Card scheduled for review in {srs.interval_days} day(s)",
    )
