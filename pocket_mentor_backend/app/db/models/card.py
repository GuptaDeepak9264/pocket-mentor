import enum
from sqlalchemy import Column, String, Integer, DateTime, ForeignKey, Text, Enum
from sqlalchemy.orm import relationship
from app.db.base import Base, generate_uuid, utcnow


class CardType(str, enum.Enum):
    learn = "learn"
    revision = "revision"
    interview = "interview"


class CardSource(str, enum.Enum):
    manual = "manual"
    ai_generated = "ai_generated"
    upload = "upload"


class Card(Base):
    __tablename__ = "cards"

    id = Column(String, primary_key=True, default=generate_uuid)
    topic_id = Column(String, ForeignKey("topics.id", ondelete="CASCADE"), nullable=False, index=True)
    user_id = Column(String, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    question = Column(Text, nullable=False)
    answer = Column(Text, nullable=False)
    hint = Column(Text, nullable=True)
    difficulty = Column(Integer, default=3)   # 1–5
    card_type = Column(Enum(CardType), default=CardType.learn, nullable=False)
    source = Column(Enum(CardSource), default=CardSource.manual, nullable=False)
    source_file_id = Column(String, ForeignKey("uploaded_files.id", ondelete="SET NULL"), nullable=True)
    created_at = Column(DateTime, default=utcnow, nullable=False)
    updated_at = Column(DateTime, default=utcnow, onupdate=utcnow, nullable=False)

    # Relationships
    topic = relationship("Topic", back_populates="cards")
    user = relationship("User", back_populates="cards")
    srs_record = relationship("SRSRecord", back_populates="card", uselist=False, cascade="all, delete-orphan")
    source_file = relationship("UploadedFile", back_populates="cards")

    def __repr__(self):
        return f"<Card id={self.id} type={self.card_type}>"
