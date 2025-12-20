"""秘密任務模型"""
from sqlalchemy import String, Text, Integer
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class SecretMission(Base):
    """
    秘密任務表
    
    每種角色有 4 種不同任務，分配給 4 張 NFC 卡片：
    - _01: 內心衝突型（私人利益 vs 公開立場）
    - _02: 復仇/恩怨型
    - _03: 雙面人/臥底型
    - _04: 理想主義/覺醒型
    
    Attributes:
        id: 任務 ID（格式：{role_type}_{index}，如 worker_01）
        role_type: 所屬角色類型
        title: 任務標題
        description: 任務描述
        success_condition: 成功條件
        points: 完成任務可獲得的分數
    """
    __tablename__ = "secret_missions"
    
    id: Mapped[str] = mapped_column(
        String(50),
        primary_key=True,
    )
    role_type: Mapped[str] = mapped_column(
        String(20),
        nullable=False,
        index=True,
    )
    title: Mapped[str] = mapped_column(
        String(100),
        nullable=False,
    )
    description: Mapped[str] = mapped_column(
        Text,
        nullable=False,
    )
    success_condition: Mapped[str | None] = mapped_column(
        Text,
        nullable=True,
    )
    points: Mapped[int] = mapped_column(
        Integer,
        default=50,
    )
    
    # 關聯
    players: Mapped[list["Player"]] = relationship(
        "Player",
        back_populates="secret_mission",
        lazy="selectin",
    )
