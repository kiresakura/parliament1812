"""WebSocket 訊息 Schema"""
from datetime import datetime
from enum import Enum
from typing import Any
from uuid import UUID

from pydantic import BaseModel


class WSEventType(str, Enum):
    """WebSocket 事件類型"""
    # Server → Client
    PLAYER_JOIN = "player_join"
    PLAYER_LEAVE = "player_leave"
    PLAYER_READY = "player_ready"
    PHASE_CHANGE = "phase_change"
    TIMER_SYNC = "timer_sync"
    PRIVATE_MESSAGE = "private_message"
    EVENT_TRIGGER = "event_trigger"
    VOTE_UPDATE = "vote_update"
    VOTE_RESULT = "vote_result"
    SECRET_REVEALED = "secret_revealed"
    ERROR = "error"
    SYNC = "sync"
    
    # Client → Server
    SEND_MESSAGE = "send_message"
    CAST_VOTE = "cast_vote"
    REQUEST_SYNC = "request_sync"
    HEARTBEAT = "heartbeat"


class WSMessage(BaseModel):
    """WebSocket 訊息基礎結構"""
    type: str
    data: dict[str, Any] = {}
    timestamp: datetime | None = None


class WSPlayerJoinData(BaseModel):
    """玩家加入資料"""
    player_id: UUID
    nickname: str
    role_type: str | None = None
    is_host: bool = False


class WSPlayerLeaveData(BaseModel):
    """玩家離開資料"""
    player_id: UUID
    nickname: str


class WSPlayerReadyData(BaseModel):
    """玩家準備狀態資料"""
    player_id: str
    is_ready: bool


class WSPhaseChangeData(BaseModel):
    """階段變更資料"""
    phase: int
    phase_name: str
    status: str


class WSTimerSyncData(BaseModel):
    """計時器同步資料"""
    end_at: datetime | None
    remaining_seconds: int


class WSPrivateMessageData(BaseModel):
    """私訊資料"""
    message_id: UUID
    from_id: UUID
    from_nickname: str
    content: str
    sent_at: datetime


class WSEventTriggerData(BaseModel):
    """突發事件資料"""
    event_id: str
    title: str
    description: str
    effect_type: str | None


class WSVoteUpdateData(BaseModel):
    """投票進度更新資料"""
    round: int
    progress: float  # 0.0 - 1.0
    voted_count: int
    total_players: int


class WSVoteResultData(BaseModel):
    """投票結果資料"""
    round: int
    results: dict[str, Any]
    winner: str | None = None


class WSSecretRevealedData(BaseModel):
    """秘密任務揭露資料"""
    player_id: UUID
    nickname: str
    mission_title: str
    mission_description: str
    is_success: bool


class WSSyncData(BaseModel):
    """同步資料"""
    room_code: str
    status: str
    phase: int
    current_round: int
    timer_end_at: datetime | None
    players: list[dict[str, Any]]


class WSErrorData(BaseModel):
    """錯誤資料"""
    code: str
    message: str
