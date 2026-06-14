from pydantic import BaseModel
from typing import Optional
from datetime import datetime
from app.db.models.uploaded_file import FileType, ParseStatus


class UploadResponse(BaseModel):
    id: str
    user_id: str
    topic_id: Optional[str]
    original_filename: str
    file_type: FileType
    file_size_bytes: Optional[int]
    parse_status: ParseStatus
    cards_generated: int
    error_message: Optional[str]
    uploaded_at: datetime
    processed_at: Optional[datetime]

    class Config:
        from_attributes = True


class UploadStatusResponse(BaseModel):
    id: str
    parse_status: ParseStatus
    cards_generated: int
    error_message: Optional[str]
    processed_at: Optional[datetime]

    class Config:
        from_attributes = True


class UploadListResponse(BaseModel):
    uploads: list[UploadResponse]
    total: int
