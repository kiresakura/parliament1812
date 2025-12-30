"""遊戲事件紀錄模型"""
import uuid
from datetime import datetime, timezone

from sqlalchemy import String, DateTime, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class GameEvent(Base):
    """
    遊戲事件紀錄表
    
    記錄房間內觸發的突發事件
    
    Attributes:
        id: 紀錄唯一識別碼
        room_id: 所屬房間 ID
        event_id: 突發事件 ID
        triggered_at: 觸發時間
    """
    __tablename__ = "game_events"
    
    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
    )
    room_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("rooms.id", ondelete="CASCADE"),
        nullable=False,
    )
    event_id: Mapped[str] = mapped_column(
        String(50),
        ForeignKey("events.id"),
        nullable=False,
    )
    triggered_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
    )
    
    # 關聯
    room: Mapped["Room"] = relationship(
        "Room",
        back_populates="game_events",
        lazy="selectin",
    )
    event: Mapped["Event"] = relationship(
        "Event",
        back_populates="game_events",
        lazy="selectin",
    )
