"""玩家相關 Schema"""
from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, Field

from app.schemas.base import BaseSchema, TimestampMixin


class PlayerCreate(BaseModel):
    """建立玩家請求"""
    nickname: str = Field(..., min_length=1, max_length=50, description="玩家暱稱")


class NFCScanRequest(BaseModel):
    """NFC 掃卡請求"""
    card_id: str = Field(..., description="NFC 卡片 ID")
    secret_hash: str = Field(..., description="秘密驗證碼")


class NFCScanResponse(BaseModel):
    """NFC 掃卡回應"""
    player_id: UUID
    role_type: str
    role_index: int
    role_name: str
    role_description: str


class PlayerResponse(BaseSchema):
    """玩家資訊回應"""
    id: UUID
    nickname: str
    role_type: str | None = None
    role_index: int | None = None
    is_host: bool = False
    joined_at: datetime


class PlayerDetailResponse(PlayerResponse):
    """玩家詳細資訊回應（包含角色資訊）"""
    role_name: str | None = None
    role_description: str | None = None
    role_background: str | None = None


class SecretMissionResponse(BaseModel):
    """秘密任務回應（只有自己能看到）"""
    id: str
    title: str
    description: str
    success_condition: str | None = None
    points: int


class RoleInfo(BaseModel):
    """角色資訊"""
    type: str
    name: str
    age: int
    occupation: str
    description: str
    background: str
    public_stance: str
