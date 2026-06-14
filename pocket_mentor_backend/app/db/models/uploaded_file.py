import enum
from sqlalchemy import Column, String, Integer, DateTime, ForeignKey, Text, Enum
from sqlalchemy.orm import relationship
from app.db.base import Base, generate_uuid, utcnow


class FileType(str, enum.Enum):
    pdf = "pdf"
    docx = "docx"
    txt = "txt"


class ParseStatus(str, enum.Enum):
    pending = "pending"
    processing = "processing"
    done = "done"
    failed = "failed"


class UploadedFile(Base):
    __tablename__ = "uploaded_files"

    id = Column(String, primary_key=True, default=generate_uuid)
    user_id = Column(String, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    topic_id = Column(String, ForeignKey("topics.id", ondelete="SET NULL"), nullable=True, index=True)
    original_filename = Column(String(255), nullable=False)
    file_type = Column(Enum(FileType), nullable=False)
    storage_path = Column(String(500), nullable=False)
    file_size_bytes = Column(Integer, nullable=True)
    parse_status = Column(Enum(ParseStatus), default=ParseStatus.pending, nullable=False)
    extracted_text = Column(Text, nullable=True)
    error_message = Column(Text, nullable=True)
    cards_generated = Column(Integer, default=0)
    uploaded_at = Column(DateTime, default=utcnow, nullable=False)
    processed_at = Column(DateTime, nullable=True)

    # Relationships
    user = relationship("User", back_populates="uploaded_files")
    cards = relationship("Card", back_populates="source_file")

    def __repr__(self):
        return f"<UploadedFile id={self.id} name={self.original_filename} status={self.parse_status}>"
