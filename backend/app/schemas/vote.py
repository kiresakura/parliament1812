"""投票相關 Schema"""
from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, Field

from app.schemas.base import BaseSchema


class VoteCreate(BaseModel):
    """投票請求"""
    choice: str = Field(..., pattern="^[ABCD]$", description="投票選項（A/B/C/D）")


class VoteResponse(BaseSchema):
    """投票記錄回應"""
    id: UUID
    player_id: UUID
    round: int
    choice: str | None
    voted_at: datetime


class VoteResultRound1(BaseModel):
    """
    第一輪匿名投票結果（只顯示百分比）
    """
    round: int = 1
    total_votes: int
    percentages: dict[str, float]  # {"A": 25.0, "B": 40.0, "C": 35.0}
    is_complete: bool


class VoteResultRound2(BaseModel):
    """
    第二輪記名投票結果（公開唱票）
    """
    round: int = 2
    total_votes: int
    results: dict[str, list[str]]  # {"A": ["玩家1", "玩家2"], "B": ["玩家3"]}
    counts: dict[str, int]  # {"A": 2, "B": 1, "C": 0}
    winner: str | None  # 最高票選項
    is_complete: bool


class VoteProgress(BaseModel):
    """投票進度"""
    round: int
    voted_count: int
    total_players: int
    progress: float  # 0.0 - 1.0


class VoteOption(BaseModel):
    """投票選項說明"""
    key: str
    title: str
    description: str
    is_hidden: bool = False


VOTE_OPTIONS = [
    VoteOption(
        key="A",
        title="禁止機器",
        description="立法禁止工廠使用省力機器",
    ),
    VoteOption(
        key="B",
        title="保護財產",
        description="嚴厲打擊破壞機器的暴民",
    ),
    VoteOption(
        key="C",
        title="折衷改革",
        description="允許機器但立法保障工人權益",
    ),
    VoteOption(
        key="D",
        title="皇家調查",
        description="由皇家委員會進行調查（隱藏選項）",
        is_hidden=True,
    ),
]
