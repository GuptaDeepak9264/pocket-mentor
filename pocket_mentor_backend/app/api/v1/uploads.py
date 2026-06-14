import asyncio
from datetime import datetime
from fastapi import APIRouter, Depends, UploadFile, File, Form, status, BackgroundTasks
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from typing import Optional

from app.db.session import get_db, AsyncSessionLocal
from app.db.models.uploaded_file import UploadedFile, ParseStatus
from app.db.models.card import Card, CardType, CardSource
from app.db.models.user import User
from app.db.base import generate_uuid
from app.core.dependencies import get_current_active_user
from app.core.exceptions import NotFoundException, ForbiddenException
from app.schemas.upload import UploadResponse, UploadStatusResponse, UploadListResponse
from app.schemas.card import CardListResponse, CardResponse, SRSInfo
from app.schemas.auth import MessageResponse
from app.services.file_service import validate_and_save_file, extract_text_from_file, delete_file
from app.services.ai_service import get_ai_service
from app.services.srs_service import create_initial_srs_record
from app.db.models.srs_record import SRSRecord

router = APIRouter(prefix="/uploads", tags=["uploads"])


async def _process_file_background(
    file_id: str,
    storage_path: str,
    file_type: str,
    topic_id: Optional[str],
    user_id: str,
) -> None:
    """
    Opens its own DB session — safe to run as a background task
    after the request session has closed.
    """
    async with AsyncSessionLocal() as db:
        try:
            result = await db.execute(
                select(UploadedFile).where(UploadedFile.id == file_id)
            )
            upload = result.scalar_one_or_none()
            if not upload:
                return

            upload.parse_status = ParseStatus.processing
            await db.commit()

            # Extract text (CPU-bound — run in executor)
            loop = asyncio.get_event_loop()
            extracted_text = await loop.run_in_executor(
                None, extract_text_from_file, storage_path, file_type
            )
            upload.extracted_text = extracted_text

            cards_created = 0
            if topic_id:
                from app.db.models.topic import Topic
                topic_result = await db.execute(
                    select(Topic).where(Topic.id == topic_id)
                )
                topic = topic_result.scalar_one_or_none()
                topic_title = topic.title if topic else "General"

                ai = get_ai_service()
                generated = await ai.generate_cards(
                    text=extracted_text,
                    topic=topic_title,
                    count=30,
                )

                for gen_card in generated:
                    card = Card(
                        id=generate_uuid(),
                        topic_id=topic_id,
                        user_id=user_id,
                        question=gen_card.question,
                        answer=gen_card.answer,
                        hint=gen_card.hint,
                        difficulty=gen_card.difficulty,
                        card_type=CardType.learn,
                        source=CardSource.upload,
                        source_file_id=file_id,
                    )
                    db.add(card)
                    await db.flush()

                    srs_data = create_initial_srs_record(card.id, user_id)
                    srs = SRSRecord(id=generate_uuid(), **srs_data)
                    db.add(srs)
                    cards_created += 1

            upload.cards_generated = cards_created
            upload.parse_status = ParseStatus.done
            upload.processed_at = datetime.utcnow()
            await db.commit()

        except Exception as e:
            try:
                upload.parse_status = ParseStatus.failed
                upload.error_message = str(e)[:500]
                await db.commit()
            except Exception:
                await db.rollback()


@router.post("", response_model=UploadResponse, status_code=status.HTTP_201_CREATED)
async def upload_file(
    background_tasks: BackgroundTasks,
    file: UploadFile = File(...),
    topic_id: Optional[str] = Form(None),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    storage_path, file_type, file_size = await validate_and_save_file(
        file, current_user.id
    )

    upload = UploadedFile(
        id=generate_uuid(),
        user_id=current_user.id,
        topic_id=topic_id,
        original_filename=file.filename or "upload",
        file_type=file_type,
        storage_path=storage_path,
        file_size_bytes=file_size,
        parse_status=ParseStatus.pending,
    )
    db.add(upload)
    await db.commit()
    await db.refresh(upload)

    # FastAPI BackgroundTasks — runs after response is sent, with its own session
    background_tasks.add_task(
        _process_file_background,
        upload.id,
        storage_path,
        file_type,
        topic_id,
        current_user.id,
    )

    return upload


@router.get("", response_model=UploadListResponse)
async def list_uploads(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    result = await db.execute(
        select(UploadedFile)
        .where(UploadedFile.user_id == current_user.id)
        .order_by(UploadedFile.uploaded_at.desc())
    )
    uploads = result.scalars().all()
    return UploadListResponse(uploads=list(uploads), total=len(uploads))


@router.get("/{upload_id}/status", response_model=UploadStatusResponse)
async def get_upload_status(
    upload_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    result = await db.execute(
        select(UploadedFile).where(UploadedFile.id == upload_id)
    )
    upload = result.scalar_one_or_none()
    if not upload:
        raise NotFoundException("Upload")
    if upload.user_id != current_user.id:
        raise ForbiddenException()
    return upload


@router.get("/{upload_id}/cards", response_model=CardListResponse)
async def get_upload_cards(
    upload_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    result = await db.execute(
        select(UploadedFile).where(UploadedFile.id == upload_id)
    )
    upload = result.scalar_one_or_none()
    if not upload:
        raise NotFoundException("Upload")
    if upload.user_id != current_user.id:
        raise ForbiddenException()

    cards_result = await db.execute(
        select(Card)
        .where(Card.source_file_id == upload_id)
        .where(Card.user_id == current_user.id)
        .order_by(Card.created_at.asc())
    )
    cards = cards_result.scalars().all()

    card_responses = []
    for card in cards:
        srs_result = await db.execute(
            select(SRSRecord).where(SRSRecord.card_id == card.id)
        )
        srs = srs_result.scalar_one_or_none()
        srs_info = None
        if srs:
            srs_info = SRSInfo(
                ease_factor=srs.ease_factor,
                interval_days=srs.interval_days,
                repetitions=srs.repetitions,
                next_review_at=srs.next_review_at,
                last_review_at=srs.last_review_at,
                last_response=srs.last_response,
            )
        card_responses.append(CardResponse(
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
        ))

    return CardListResponse(cards=card_responses, total=len(card_responses))


@router.delete("/{upload_id}", response_model=MessageResponse)
async def delete_upload(
    upload_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    result = await db.execute(
        select(UploadedFile).where(UploadedFile.id == upload_id)
    )
    upload = result.scalar_one_or_none()
    if not upload:
        raise NotFoundException("Upload")
    if upload.user_id != current_user.id:
        raise ForbiddenException()

    delete_file(upload.storage_path)
    await db.delete(upload)
    return MessageResponse(message="Upload deleted successfully")
