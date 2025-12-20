"""突發事件模型"""
from sqlalchemy import String, Text, Integer
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class Event(Base):
    """
    突發事件表
    
    主持人可以抽取事件卡改變局勢
    
    Attributes:
        id: 事件 ID
        title: 事件標題
        description: 事件描述
        effect_type: 效果類型
        severity: 嚴重程度（1-5）
    """
    __tablename__ = "events"
    
    id: Mapped[str] = mapped_column(
        String(50),
        primary_key=True,
    )
    title: Mapped[str] = mapped_column(
        String(100),
        nullable=False,
    )
    description: Mapped[str] = mapped_column(
        Text,
        nullable=False,
    )
    effect_type: Mapped[str | None] = mapped_column(
        String(50),
        nullable=True,
    )
    severity: Mapped[int] = mapped_column(
        Integer,
        default=1,
    )
    
    # 關聯
    game_events: Mapped[list["GameEvent"]] = relationship(
        "GameEvent",
        back_populates="event",
        lazy="selectin",
    )
