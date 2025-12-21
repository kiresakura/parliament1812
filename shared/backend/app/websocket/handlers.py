"""
WebSocket 事件處理器

處理客戶端發送的 WebSocket 訊息
"""
import json
from datetime import datetime
from typing import Any
from uuid import UUID

from fastapi import WebSocket, WebSocketDisconnect
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.schemas.websocket import WSEventType, WSMessage
from app.websocket.manager import manager


async def handle_websocket_message(
    websocket: WebSocket,
    room_code: str,
    player_id: str,
    message: str,
    db: AsyncSession,
) -> None:
    """
    處理 WebSocket 訊息
    
    Args:
        websocket: WebSocket 連線
        room_code: 房間碼
        player_id: 玩家 ID
        message: 收到的訊息（JSON 字串）
        db: 資料庫 session
    """
    try:
        data = json.loads(message)
        msg_type = data.get("type")
        msg_data = data.get("data", {})
        
        if msg_type == WSEventType.SEND_MESSAGE.value:
            await handle_send_message(room_code, player_id, msg_data, db)
        
        elif msg_type == WSEventType.CAST_VOTE.value:
            await handle_cast_vote(room_code, player_id, msg_data, db)
        
        elif msg_type == WSEventType.REQUEST_SYNC.value:
            await handle_request_sync(websocket, room_code, player_id, db)
        
        elif msg_type == WSEventType.HEARTBEAT.value:
            # 心跳回應
            await websocket.send_text(json.dumps({
                "type": "heartbeat_ack",
                "timestamp": datetime.utcnow().isoformat(),
            }))
        
        else:
            # 未知訊息類型
            await manager.send_to_player(
                room_code,
                player_id,
                WSEventType.ERROR,
                {
                    "code": "UNKNOWN_MESSAGE_TYPE",
                    "message": f"未知的訊息類型：{msg_type}",
                },
            )
    
    except json.JSONDecodeError:
        await manager.send_to_player(
            room_code,
            player_id,
            WSEventType.ERROR,
            {
                "code": "INVALID_JSON",
                "message": "無效的 JSON 格式",
            },
        )
    except Exception as e:
        await manager.send_to_player(
            room_code,
            player_id,
            WSEventType.ERROR,
            {
                "code": "INTERNAL_ERROR",
                "message": str(e),
            },
        )


async def handle_send_message(
    room_code: str,
    sender_id: str,
    data: dict[str, Any],
    db: AsyncSession,
) -> None:
    """
    處理發送私訊
    
    Args:
        room_code: 房間碼
        sender_id: 發送者 ID
        data: 訊息資料 {"to": "player_id", "content": "..."}
        db: 資料庫 session
    """
    receiver_id = data.get("to")
    content = data.get("content")
    
    if not receiver_id or not content:
        await manager.send_to_player(
            room_code,
            sender_id,
            WSEventType.ERROR,
            {
                "code": "INVALID_MESSAGE",
                "message": "缺少接收者或訊息內容",
            },
        )
        return
    
    # TODO: 儲存訊息到資料庫
    # TODO: 取得發送者暱稱
    
    # 發送私訊給接收者
    await manager.send_to_player(
        room_code,
        receiver_id,
        WSEventType.PRIVATE_MESSAGE,
        {
            "from_id": sender_id,
            "from_nickname": "玩家",  # TODO: 取得真實暱稱
            "content": content,
            "sent_at": datetime.utcnow().isoformat(),
        },
    )


async def handle_cast_vote(
    room_code: str,
    player_id: str,
    data: dict[str, Any],
    db: AsyncSession,
) -> None:
    """
    處理投票
    
    Args:
        room_code: 房間碼
        player_id: 玩家 ID
        data: 投票資料 {"round": 1, "choice": "A"}
        db: 資料庫 session
    """
    vote_round = data.get("round")
    choice = data.get("choice")
    
    if not vote_round or not choice:
        await manager.send_to_player(
            room_code,
            player_id,
            WSEventType.ERROR,
            {
                "code": "INVALID_VOTE",
                "message": "缺少投票輪次或選項",
            },
        )
        return
    
    # TODO: 儲存投票到資料庫
    # TODO: 計算投票進度並廣播
    
    # 廣播投票進度更新
    await manager.broadcast(
        room_code,
        WSEventType.VOTE_UPDATE,
        {
            "round": vote_round,
            "progress": 0.5,  # TODO: 計算實際進度
            "voted_count": 10,
            "total_players": 20,
        },
    )


async def handle_request_sync(
    websocket: WebSocket,
    room_code: str,
    player_id: str,
    db: AsyncSession,
) -> None:
    """
    處理同步請求
    
    Args:
        websocket: WebSocket 連線
        room_code: 房間碼
        player_id: 玩家 ID
        db: 資料庫 session
    """
    # TODO: 從資料庫取得房間最新狀態
    
    await manager.send_to_player(
        room_code,
        player_id,
        WSEventType.SYNC,
        {
            "room_code": room_code,
            "status": "waiting",  # TODO: 取得真實狀態
            "phase": 1,
            "current_round": 0,
            "timer_end_at": None,
            "players": [],  # TODO: 取得玩家列表
        },
    )


async def notify_player_join(
    room_code: str,
    player_id: str,
    nickname: str,
    role_type: str | None = None,
    is_host: bool = False,
) -> None:
    """
    通知玩家加入
    
    Args:
        room_code: 房間碼
        player_id: 玩家 ID
        nickname: 玩家暱稱
        role_type: 角色類型
        is_host: 是否為主持人
    """
    await manager.broadcast(
        room_code,
        WSEventType.PLAYER_JOIN,
        {
            "player_id": player_id,
            "nickname": nickname,
            "role_type": role_type,
            "is_host": is_host,
        },
    )


async def notify_player_leave(
    room_code: str,
    player_id: str,
    nickname: str,
) -> None:
    """
    通知玩家離開

    Args:
        room_code: 房間碼
        player_id: 玩家 ID
        nickname: 玩家暱稱
    """
    await manager.broadcast(
        room_code,
        WSEventType.PLAYER_LEAVE,
        {
            "player_id": player_id,
            "nickname": nickname,
        },
    )


async def notify_player_ready(
    room_code: str,
    player_id: str,
    is_ready: bool,
) -> None:
    """
    通知玩家準備狀態變更

    Args:
        room_code: 房間碼
        player_id: 玩家 ID
        is_ready: 是否準備
    """
    await manager.broadcast(
        room_code,
        WSEventType.PLAYER_READY,
        {
            "player_id": player_id,
            "is_ready": is_ready,
        },
    )


async def notify_phase_change(
    room_code: str,
    phase: int,
    phase_name: str,
    status: str,
) -> None:
    """
    通知階段變更
    
    Args:
        room_code: 房間碼
        phase: 階段數字
        phase_name: 階段名稱
        status: 狀態字串
    """
    await manager.broadcast(
        room_code,
        WSEventType.PHASE_CHANGE,
        {
            "phase": phase,
            "phase_name": phase_name,
            "status": status,
        },
    )


async def notify_timer_sync(
    room_code: str,
    end_at: datetime | None,
    remaining_seconds: int,
) -> None:
    """
    同步計時器
    
    Args:
        room_code: 房間碼
        end_at: 結束時間
        remaining_seconds: 剩餘秒數
    """
    await manager.broadcast(
        room_code,
        WSEventType.TIMER_SYNC,
        {
            "end_at": end_at.isoformat() if end_at else None,
            "remaining_seconds": remaining_seconds,
        },
    )


async def notify_event_trigger(
    room_code: str,
    event_id: str,
    title: str,
    description: str,
    effect_type: str | None = None,
) -> None:
    """
    通知突發事件觸發

    Args:
        room_code: 房間碼
        event_id: 事件 ID
        title: 事件標題
        description: 事件描述
        effect_type: 效果類型
    """
    await manager.broadcast(
        room_code,
        WSEventType.EVENT_TRIGGER,
        {
            "event_id": event_id,
            "title": title,
            "description": description,
            "effect_type": effect_type,
        },
    )


async def notify_private_message(
    room_code: str,
    receiver_id: str,
    message_id: str,
    sender_id: str,
    sender_nickname: str,
    content: str,
    sent_at: str,
) -> None:
    """
    通知私訊

    Args:
        room_code: 房間碼
        receiver_id: 接收者 ID
        message_id: 訊息 ID
        sender_id: 發送者 ID
        sender_nickname: 發送者暱稱
        content: 訊息內容
        sent_at: 發送時間
    """
    await manager.send_to_player(
        room_code,
        receiver_id,
        WSEventType.PRIVATE_MESSAGE,
        {
            "message_id": message_id,
            "from_id": sender_id,
            "from_nickname": sender_nickname,
            "content": content,
            "sent_at": sent_at,
        },
    )
