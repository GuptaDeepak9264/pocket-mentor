from pydantic import BaseModel
from typing import Optional
from datetime import datetime
from app.db.models.card import CardType


class FeedCard(BaseModel):
    id: str
    topic_id: str
    topic_title: str
    topic_color: str
    question: str
    answer: str
    hint: Optional[str]
    difficulty: int
    card_type: CardType
    interval_days: int
    repetitions: int
    next_review_at: datetime

    class Config:
        from_attributes = True


class LearnFeedResponse(BaseModel):
    cards: list[FeedCard]
    total: int
    topic_id: Optional[str]


class RevisionFeedResponse(BaseModel):
    cards: list[FeedCard]
    due_today: int
    overdue: int


class InterviewFeedResponse(BaseModel):
    cards: list[FeedCard]
    total: int
    topic_id: Optional[str]
    difficulty_filter: Optional[int]
