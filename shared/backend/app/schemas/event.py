"""突發事件相關 Schema"""
from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, Field

from app.schemas.base import BaseSchema


class EventResponse(BaseSchema):
    """突發事件回應"""
    id: str
    title: str
    description: str
    effect_type: str | None
    severity: int


class TriggerEventRequest(BaseModel):
    """觸發突發事件請求"""
    event_id: str = Field(..., description="事件 ID")


class GameEventResponse(BaseSchema):
    """遊戲事件紀錄回應"""
    id: UUID
    event: EventResponse
    triggered_at: datetime
