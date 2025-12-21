"""玩家相關 Schema"""
from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, Field

from app.schemas.base import BaseSchema, TimestampMixin


class PlayerCreate(BaseModel):
    """建立玩家請求"""
    nickname: str = Field(..., min_length=1, max_length=50, description="玩家暱稱")


class NFCScanRequest(BaseModel):
    """NFC 掃卡請求（UID 綁定防偽格式）"""
    card_id: str = Field(..., description="NFC 卡片 ID")
    signature: str = Field(..., description="防偽簽名")
    uid: str = Field(..., description="卡片 UID（防複製）")


class ManualRoleRequest(BaseModel):
    """手動角色分配請求（NFC 備用方案）"""
    player_id: str = Field(..., description="玩家 ID")
    role_code: str = Field(..., description="角色代碼 (如 W01, F02, L03, R04, M01)")


class NFCScanResponse(BaseModel):
    """NFC 掃卡回應"""
    player_id: UUID
    role_type: str
    role_index: int
    role_name: str
    role_description: str


class PlayerReadyRequest(BaseModel):
    """設定準備狀態請求"""
    is_ready: bool = Field(..., description="是否準備就緒")


class PlayerResponse(BaseSchema):
    """玩家資訊回應"""
    id: UUID
    nickname: str
    role_type: str | None = None
    role_index: int | None = None
    is_host: bool = False
    is_ready: bool = False
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
