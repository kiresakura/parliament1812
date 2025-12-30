"""投票模型"""
import uuid
from datetime import datetime, timezone
from enum import Enum

from sqlalchemy import String, DateTime, Integer, ForeignKey, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class VoteChoice(str, Enum):
    """投票選項"""
    A = "A"  # 禁止機器 - 立法禁止工廠使用省力機器
    B = "B"  # 保護財產 - 嚴厲打擊破壞機器的暴民
    C = "C"  # 折衷改革 - 允許機器但立法保障工人權益
    D = "D"  # 皇家調查 - 隱藏選項，由突發事件觸發


class Vote(Base):
    """
    投票表
    
    第一輪匿名（只顯示比例）、第二輪記名（公開唱票）
    
    Attributes:
        id: 投票記錄唯一識別碼
        room_id: 所屬房間 ID
        player_id: 投票玩家 ID
        round: 投票輪次（1 或 2）
        choice: 投票選項（A/B/C/D）
        voted_at: 投票時間
    """
    __tablename__ = "votes"
    
    __table_args__ = (
        UniqueConstraint("room_id", "player_id", "round", name="uq_vote_room_player_round"),
    )
    
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
    player_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("players.id"),
        nullable=False,
    )
    round: Mapped[int] = mapped_column(
        Integer,
        nullable=False,
    )
    choice: Mapped[str | None] = mapped_column(
        String(1),
        nullable=True,
    )
    voted_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
    )
    
    # 關聯
    room: Mapped["Room"] = relationship(
        "Room",
        back_populates="votes",
        lazy="selectin",
    )
    player: Mapped["Player"] = relationship(
        "Player",
        back_populates="votes",
        lazy="selectin",
    )
