from pydantic import BaseModel
from typing import Optional
from datetime import datetime, date
from app.db.models.session import SessionMode


class SessionCreate(BaseModel):
    topic_id: Optional[str] = None
    mode: SessionMode
    cards_reviewed: int
    cards_known: int
    cards_unknown: int
    duration_seconds: int
    started_at: datetime
    ended_at: Optional[datetime] = None


class SessionResponse(BaseModel):
    id: str
    user_id: str
    topic_id: Optional[str]
    mode: SessionMode
    cards_reviewed: int
    cards_known: int
    cards_unknown: int
    duration_seconds: int
    accuracy_percent: float
    started_at: datetime
    ended_at: Optional[datetime]

    class Config:
        from_attributes = True


class StreakResponse(BaseModel):
    current_streak: int
    longest_streak: int
    last_active_date: Optional[date]
    total_cards_reviewed: int
    total_sessions: int


class HeatmapEntry(BaseModel):
    date: date
    cards_reviewed: int
    sessions: int


class TopicProgress(BaseModel):
    topic_id: str
    topic_title: str
    topic_color: str
    total_cards: int
    cards_known: int
    cards_due_today: int
    mastery_percent: float


class ProgressSummaryResponse(BaseModel):
    streak: StreakResponse
    today_cards_reviewed: int
    today_goal: int
    today_goal_met: bool
    sessions_this_week: int
    total_cards_in_library: int
    cards_due_today: int
    topic_progress: list[TopicProgress]


class SessionListResponse(BaseModel):
    sessions: list[SessionResponse]
    total: int


class HeatmapResponse(BaseModel):
    entries: list[HeatmapEntry]
    period_days: int
