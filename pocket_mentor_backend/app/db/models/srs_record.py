import enum
from sqlalchemy import Column, String, Integer, Float, DateTime, ForeignKey, Enum
from sqlalchemy.orm import relationship
from app.db.base import Base, generate_uuid, utcnow


class SRSResponse(str, enum.Enum):
    know = "know"
    dont_know = "dont_know"


class SRSRecord(Base):
    __tablename__ = "srs_records"

    id = Column(String, primary_key=True, default=generate_uuid)
    card_id = Column(String, ForeignKey("cards.id", ondelete="CASCADE"), nullable=False, unique=True, index=True)
    user_id = Column(String, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    ease_factor = Column(Float, default=2.5, nullable=False)
    interval_days = Column(Integer, default=1, nullable=False)
    repetitions = Column(Integer, default=0, nullable=False)
    next_review_at = Column(DateTime, default=utcnow, nullable=False)
    last_review_at = Column(DateTime, nullable=True)
    last_response = Column(Enum(SRSResponse), nullable=True)
    created_at = Column(DateTime, default=utcnow, nullable=False)
    updated_at = Column(DateTime, default=utcnow, onupdate=utcnow, nullable=False)

    # Relationships
    card = relationship("Card", back_populates="srs_record")
    user = relationship("User", back_populates="srs_records")

    def __repr__(self):
        return f"<SRSRecord card_id={self.card_id} next_review={self.next_review_at}>"
