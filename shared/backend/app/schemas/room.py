"""房間相關 Schema"""
from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, Field

from app.schemas.base import BaseSchema, TimestampMixin


class RoomCreate(BaseModel):
    """建立房間請求"""
    host_nickname: str = Field(..., min_length=1, max_length=50, description="主持人暱稱")


class RoomJoin(BaseModel):
    """加入房間請求"""
    nickname: str = Field(..., min_length=1, max_length=50, description="玩家暱稱")


class RoomResponse(BaseSchema, TimestampMixin):
    """房間資訊回應"""
    id: UUID
    code: str
    status: str
    phase: int
    current_round: int
    timer_end_at: datetime | None = None
    player_count: int = 0


class RoomDetailResponse(RoomResponse):
    """房間詳細資訊回應（包含玩家列表）"""
    players: list["PlayerBrief"] = []


class PhaseChangeRequest(BaseModel):
    """切換階段請求"""
    phase: int = Field(..., ge=1, le=12, description="目標階段（1-12）")


class TimerRequest(BaseModel):
    """設定計時器請求"""
    duration_seconds: int = Field(..., ge=0, description="計時器持續時間（秒）")


# 為了避免循環引用，這裡前向引用 PlayerBrief
class PlayerBrief(BaseSchema):
    """玩家簡要資訊"""
    id: UUID
    nickname: str
    role_type: str | None = None
    is_host: bool = False
    is_ready: bool = False


# 更新前向引用
RoomDetailResponse.model_rebuild()
