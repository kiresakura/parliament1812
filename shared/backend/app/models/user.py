"""用戶模型"""
import uuid
from datetime import datetime, timezone

from sqlalchemy import String, DateTime
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class User(Base):
    """
    用戶表（支援未來上架）
    
    Attributes:
        id: 用戶唯一識別碼
        email: 電子郵件地址
        display_name: 顯示名稱
        created_at: 建立時間
    """
    __tablename__ = "users"
    
    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
    )
    email: Mapped[str | None] = mapped_column(
        String(255),
        unique=True,
        nullable=True,
    )
    display_name: Mapped[str | None] = mapped_column(
        String(50),
        nullable=True,
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
    )
    
    # 關聯
    hosted_rooms: Mapped[list["Room"]] = relationship(
        "Room",
        back_populates="host",
        lazy="selectin",
    )
    players: Mapped[list["Player"]] = relationship(
        "Player",
        back_populates="user",
        lazy="selectin",
    )
