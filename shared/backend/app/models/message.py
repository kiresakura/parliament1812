"""私訊模型"""
import uuid
from datetime import datetime

from sqlalchemy import String, Text, DateTime, Boolean, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class PrivateMessage(Base):
    """
    私訊表
    
    玩家間可以發送悄悄話密謀
    
    Attributes:
        id: 訊息唯一識別碼
        room_id: 所屬房間 ID
        sender_id: 發送者玩家 ID
        receiver_id: 接收者玩家 ID
        content: 訊息內容
        is_read: 是否已讀
        sent_at: 發送時間
    """
    __tablename__ = "private_messages"
    
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
    sender_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("players.id"),
        nullable=False,
    )
    receiver_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("players.id"),
        nullable=False,
    )
    content: Mapped[str] = mapped_column(
        Text,
        nullable=False,
    )
    is_read: Mapped[bool] = mapped_column(
        Boolean,
        default=False,
    )
    sent_at: Mapped[datetime] = mapped_column(
        DateTime,
        default=datetime.utcnow,
    )
    
    # 關聯
    room: Mapped["Room"] = relationship(
        "Room",
        back_populates="messages",
        lazy="selectin",
    )
    sender: Mapped["Player"] = relationship(
        "Player",
        back_populates="sent_messages",
        foreign_keys=[sender_id],
        lazy="selectin",
    )
    receiver: Mapped["Player"] = relationship(
        "Player",
        back_populates="received_messages",
        foreign_keys=[receiver_id],
        lazy="selectin",
    )
