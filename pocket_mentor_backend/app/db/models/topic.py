from sqlalchemy import Column, String, Boolean, DateTime, ForeignKey, Text
from sqlalchemy.orm import relationship
from app.db.base import Base, generate_uuid, utcnow


class Topic(Base):
    __tablename__ = "topics"

    id = Column(String, primary_key=True, default=generate_uuid)
    user_id = Column(String, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    title = Column(String(200), nullable=False)
    description = Column(Text, nullable=True)
    color_tag = Column(String(7), default="#6366F1")   # hex colour
    icon = Column(String(50), default="book")
    is_public = Column(Boolean, default=False)
    created_at = Column(DateTime, default=utcnow, nullable=False)
    updated_at = Column(DateTime, default=utcnow, onupdate=utcnow, nullable=False)

    # Relationships
    user = relationship("User", back_populates="topics")
    cards = relationship("Card", back_populates="topic", cascade="all, delete-orphan")

    def __repr__(self):
        return f"<Topic id={self.id} title={self.title}>"
