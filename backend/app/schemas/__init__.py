"""
Pydantic Schemas

匯出所有 Schema 供其他模組使用
"""
from app.schemas.base import BaseSchema, TimestampMixin
from app.schemas.room import (
    RoomCreate,
    RoomJoin,
    RoomResponse,
    RoomDetailResponse,
    PhaseChangeRequest,
    TimerRequest,
    PlayerBrief,
)
from app.schemas.player import (
    PlayerCreate,
    NFCScanRequest,
    ManualRoleRequest,
    NFCScanResponse,
    PlayerResponse,
    PlayerDetailResponse,
    SecretMissionResponse,
    RoleInfo,
)
from app.schemas.message import (
    MessageCreate,
    MessageResponse,
    MessageListResponse,
    MarkReadRequest,
)
from app.schemas.vote import (
    VoteCreate,
    VoteResponse,
    VoteResultRound1,
    VoteResultRound2,
    VoteProgress,
    VoteOption,
    VOTE_OPTIONS,
)
from app.schemas.event import (
    EventResponse,
    TriggerEventRequest,
    GameEventResponse,
)
from app.schemas.websocket import (
    WSEventType,
    WSMessage,
    WSPlayerJoinData,
    WSPlayerLeaveData,
    WSPhaseChangeData,
    WSTimerSyncData,
    WSPrivateMessageData,
    WSEventTriggerData,
    WSVoteUpdateData,
    WSVoteResultData,
    WSSecretRevealedData,
    WSSyncData,
    WSErrorData,
)

__all__ = [
    # Base
    "BaseSchema",
    "TimestampMixin",
    # Room
    "RoomCreate",
    "RoomJoin",
    "RoomResponse",
    "RoomDetailResponse",
    "PhaseChangeRequest",
    "TimerRequest",
    "PlayerBrief",
    # Player
    "PlayerCreate",
    "NFCScanRequest",
    "ManualRoleRequest",
    "NFCScanResponse",
    "PlayerResponse",
    "PlayerDetailResponse",
    "SecretMissionResponse",
    "RoleInfo",
    # Message
    "MessageCreate",
    "MessageResponse",
    "MessageListResponse",
    "MarkReadRequest",
    # Vote
    "VoteCreate",
    "VoteResponse",
    "VoteResultRound1",
    "VoteResultRound2",
    "VoteProgress",
    "VoteOption",
    "VOTE_OPTIONS",
    # Event
    "EventResponse",
    "TriggerEventRequest",
    "GameEventResponse",
    # WebSocket
    "WSEventType",
    "WSMessage",
    "WSPlayerJoinData",
    "WSPlayerLeaveData",
    "WSPhaseChangeData",
    "WSTimerSyncData",
    "WSPrivateMessageData",
    "WSEventTriggerData",
    "WSVoteUpdateData",
    "WSVoteResultData",
    "WSSecretRevealedData",
    "WSSyncData",
    "WSErrorData",
]
