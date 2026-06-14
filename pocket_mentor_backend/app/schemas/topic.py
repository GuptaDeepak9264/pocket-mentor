from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime


class TopicCreate(BaseModel):
    title: str = Field(min_length=1, max_length=200)
    description: Optional[str] = None
    color_tag: str = Field(default="#6366F1", pattern=r"^#[0-9A-Fa-f]{6}$")
    icon: str = Field(default="book", max_length=50)
    is_public: bool = False


class TopicUpdate(BaseModel):
    title: Optional[str] = Field(None, min_length=1, max_length=200)
    description: Optional[str] = None
    color_tag: Optional[str] = Field(None, pattern=r"^#[0-9A-Fa-f]{6}$")
    icon: Optional[str] = Field(None, max_length=50)
    is_public: Optional[bool] = None


class TopicResponse(BaseModel):
    id: str
    user_id: str
    title: str
    description: Optional[str]
    color_tag: str
    icon: str
    is_public: bool
    card_count: int = 0
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class TopicListResponse(BaseModel):
    topics: list[TopicResponse]
    total: int
