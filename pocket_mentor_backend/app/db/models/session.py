import enum
from sqlalchemy import Column, String, Integer, DateTime, ForeignKey, Enum
from sqlalchemy.orm import relationship
from app.db.base import Base, generate_uuid, utcnow


class SessionMode(str, enum.Enum):
    learn = "learn"
    revision = "revision"
    interview = "interview"


class StudySession(Base):
    __tablename__ = "study_sessions"

    id = Column(String, primary_key=True, default=generate_uuid)
    user_id = Column(String, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    topic_id = Column(String, ForeignKey("topics.id", ondelete="SET NULL"), nullable=True, index=True)
    mode = Column(Enum(SessionMode), nullable=False)
    cards_reviewed = Column(Integer, default=0)
    cards_known = Column(Integer, default=0)
    cards_unknown = Column(Integer, default=0)
    duration_seconds = Column(Integer, default=0)
    started_at = Column(DateTime, default=utcnow, nullable=False)
    ended_at = Column(DateTime, nullable=True)

    # Relationships
    user = relationship("User", back_populates="sessions")

    def __repr__(self):
        return f"<StudySession id={self.id} mode={self.mode} cards={self.cards_reviewed}>"
