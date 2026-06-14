from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime
from app.db.models.card import CardType, CardSource
from app.db.models.srs_record import SRSResponse


class CardCreate(BaseModel):
    question: str = Field(min_length=1, max_length=2000)
    answer: str = Field(min_length=1, max_length=5000)
    hint: Optional[str] = Field(None, max_length=1000)
    difficulty: int = Field(default=3, ge=1, le=5)
    card_type: CardType = CardType.learn


class CardUpdate(BaseModel):
    question: Optional[str] = Field(None, min_length=1, max_length=2000)
    answer: Optional[str] = Field(None, min_length=1, max_length=5000)
    hint: Optional[str] = Field(None, max_length=1000)
    difficulty: Optional[int] = Field(None, ge=1, le=5)
    card_type: Optional[CardType] = None


class SRSInfo(BaseModel):
    ease_factor: float
    interval_days: int
    repetitions: int
    next_review_at: datetime
    last_review_at: Optional[datetime]
    last_response: Optional[SRSResponse]

    class Config:
        from_attributes = True


class CardResponse(BaseModel):
    id: str
    topic_id: str
    user_id: str
    question: str
    answer: str
    hint: Optional[str]
    difficulty: int
    card_type: CardType
    source: CardSource
    source_file_id: Optional[str]
    srs_info: Optional[SRSInfo] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class CardResponseRequest(BaseModel):
    result: SRSResponse


class CardListResponse(BaseModel):
    cards: list[CardResponse]
    total: int


class CardResponseResult(BaseModel):
    card_id: str
    result: SRSResponse
    next_review_at: datetime
    interval_days: int
    ease_factor: float
    message: str
