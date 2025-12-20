"""私訊相關 Schema"""
from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, Field

from app.schemas.base import BaseSchema


class MessageCreate(BaseModel):
    """發送私訊請求"""
    receiver_id: UUID = Field(..., description="接收者玩家 ID")
    content: str = Field(..., min_length=1, max_length=500, description="訊息內容")


class MessageResponse(BaseSchema):
    """私訊回應"""
    id: UUID
    sender_id: UUID
    sender_nickname: str
    receiver_id: UUID
    receiver_nickname: str
    content: str
    is_read: bool
    sent_at: datetime


class MessageListResponse(BaseModel):
    """私訊列表回應"""
    messages: list[MessageResponse]
    total: int
    unread_count: int


class MarkReadRequest(BaseModel):
    """標記已讀請求"""
    message_ids: list[UUID] = Field(default=[], description="要標記為已讀的訊息 ID 列表")
