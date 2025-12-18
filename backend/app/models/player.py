"""玩家模型"""
import uuid
from datetime import datetime
from enum import Enum

from sqlalchemy import String, DateTime, Integer, Boolean, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class RoleType(str, Enum):
    """角色類型"""
    WORKER = "worker"      # 紡織工人 湯瑪斯
    FACTORY = "factory"    # 工廠主 理查·威爾森
    LUDDITE = "luddite"    # 盧德派 喬治
    REFORMER = "reformer"  # 改革者 羅伯特·烏爾文
    MP = "mp"              # 議員 威廉·菲茨傑拉德


class Player(Base):
    """
    玩家表
    
    Attributes:
        id: 玩家唯一識別碼
        room_id: 所屬房間 ID
        user_id: 關聯用戶 ID（可選）
        nickname: 玩家暱稱
        role_type: 角色類型
        role_index: 同類角色的索引（1-4）
        secret_mission_id: 秘密任務 ID
        is_host: 是否為主持人
        joined_at: 加入時間
    """
    __tablename__ = "players"
    
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
    user_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id"),
        nullable=True,
    )
    nickname: Mapped[str] = mapped_column(
        String(50),
        nullable=False,
    )
    role_type: Mapped[str | None] = mapped_column(
        String(20),
        nullable=True,
    )
    role_index: Mapped[int | None] = mapped_column(
        Integer,
        nullable=True,
    )
    secret_mission_id: Mapped[str | None] = mapped_column(
        String(50),
        ForeignKey("secret_missions.id"),
        nullable=True,
    )
    is_host: Mapped[bool] = mapped_column(
        Boolean,
        default=False,
    )
    joined_at: Mapped[datetime] = mapped_column(
        DateTime,
        default=datetime.utcnow,
    )
    
    # 關聯
    room: Mapped["Room"] = relationship(
        "Room",
        back_populates="players",
        lazy="selectin",
    )
    user: Mapped["User"] = relationship(
        "User",
        back_populates="players",
        lazy="selectin",
    )
    secret_mission: Mapped["SecretMission"] = relationship(
        "SecretMission",
        back_populates="players",
        lazy="selectin",
    )
    sent_messages: Mapped[list["PrivateMessage"]] = relationship(
        "PrivateMessage",
        back_populates="sender",
        foreign_keys="PrivateMessage.sender_id",
        lazy="selectin",
    )
    received_messages: Mapped[list["PrivateMessage"]] = relationship(
        "PrivateMessage",
        back_populates="receiver",
        foreign_keys="PrivateMessage.receiver_id",
        lazy="selectin",
    )
    votes: Mapped[list["Vote"]] = relationship(
        "Vote",
        back_populates="player",
        lazy="selectin",
    )
