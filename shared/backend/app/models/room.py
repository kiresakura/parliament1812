"""遊戲房間模型"""
import uuid
from datetime import datetime
from enum import Enum

from sqlalchemy import String, DateTime, Integer, Boolean, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class RoomStatus(str, Enum):
    """房間狀態"""
    WAITING = "waiting"           # 等待玩家加入
    PREPARING = "preparing"       # 角色研究 + 陣營策略
    CONSPIRACY = "conspiracy"     # 私下密謀時間
    DEBATE = "debate"            # 開場陳述
    EVENT1 = "event1"            # 突發事件 #1
    DEBATE2 = "debate2"          # 自由辯論
    EVENT2 = "event2"            # 突發事件 #2
    VOTE_ROUND1 = "vote_round1"  # 第一輪匿名投票
    FINAL_DEBATE = "final_debate"  # 最後攻防
    VOTE_ROUND2 = "vote_round2"  # 第二輪記名投票
    REVEAL = "reveal"            # 結果揭曉 + 秘密任務公開
    FINISHED = "finished"        # 遊戲結束


class Room(Base):
    """
    遊戲房間表
    
    Attributes:
        id: 房間唯一識別碼
        code: 6 位房間碼（避免混淆字元）
        host_id: 主持人用戶 ID
        status: 房間狀態
        phase: 當前階段（1-12）
        current_round: 當前投票輪次
        timer_end_at: 計時器結束時間
        created_at: 建立時間
    """
    __tablename__ = "rooms"
    
    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
    )
    code: Mapped[str] = mapped_column(
        String(6),
        unique=True,
        nullable=False,
        index=True,
    )
    host_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id"),
        nullable=True,
    )
    status: Mapped[str] = mapped_column(
        String(20),
        default=RoomStatus.WAITING.value,
    )
    phase: Mapped[int] = mapped_column(
        Integer,
        default=1,
    )
    current_round: Mapped[int] = mapped_column(
        Integer,
        default=0,
    )
    timer_end_at: Mapped[datetime | None] = mapped_column(
        DateTime,
        nullable=True,
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime,
        default=datetime.utcnow,
    )
    
    # 關聯
    host: Mapped["User"] = relationship(
        "User",
        back_populates="hosted_rooms",
        lazy="selectin",
    )
    players: Mapped[list["Player"]] = relationship(
        "Player",
        back_populates="room",
        lazy="selectin",
        cascade="all, delete-orphan",
    )
    messages: Mapped[list["PrivateMessage"]] = relationship(
        "PrivateMessage",
        back_populates="room",
        lazy="selectin",
        cascade="all, delete-orphan",
    )
    votes: Mapped[list["Vote"]] = relationship(
        "Vote",
        back_populates="room",
        lazy="selectin",
        cascade="all, delete-orphan",
    )
    game_events: Mapped[list["GameEvent"]] = relationship(
        "GameEvent",
        back_populates="room",
        lazy="selectin",
        cascade="all, delete-orphan",
    )
