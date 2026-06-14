from pydantic import BaseModel, EmailStr, Field
from typing import Optional
from datetime import datetime


class RegisterRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=8, max_length=100)
    display_name: str = Field(min_length=1, max_length=100)


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int  # seconds


class RefreshRequest(BaseModel):
    refresh_token: str


class UserSettingsUpdate(BaseModel):
    daily_goal: Optional[int] = Field(None, ge=1, le=200)
    notification_enabled: Optional[bool] = None
    notification_time: Optional[str] = None   # "HH:MM"
    theme: Optional[str] = None


class UserResponse(BaseModel):
    id: str
    email: str
    display_name: str
    avatar_url: Optional[str]
    is_active: bool
    is_verified: bool
    settings: dict
    created_at: datetime

    class Config:
        from_attributes = True


class UserUpdate(BaseModel):
    display_name: Optional[str] = Field(None, min_length=1, max_length=100)
    avatar_url: Optional[str] = None
    settings: Optional[dict] = None


class MessageResponse(BaseModel):
    message: str
