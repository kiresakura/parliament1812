"""私訊 API 路由"""
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.schemas import (
    MessageCreate,
    MessageResponse,
    MessageListResponse,
    MarkReadRequest,
)
from app.services import room_service, player_service
from app.services import message_service
from app.websocket import manager
from app.schemas.websocket import WSEventType


router = APIRouter(prefix="/api/messages", tags=["messages"])


@router.post(
    "",
    response_model=MessageResponse,
    summary="發送私訊",
)
async def send_message(
    request: MessageCreate,
    sender_id: UUID = Query(..., description="發送者玩家 ID"),
    room_code: str = Query(..., description="房間碼"),
    db: AsyncSession = Depends(get_db),
) -> MessageResponse:
    """
    發送私訊給另一位玩家

    Args:
        request: 私訊內容（接收者 ID 和訊息內容）
        sender_id: 發送者玩家 ID
        room_code: 房間碼
        db: 資料庫 session

    Returns:
        已發送的私訊資訊
    """
    # 取得房間
    room = await room_service.get_room_by_code(db, room_code)
    if not room:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="找不到此房間",
        )

    # 驗證發送者在房間中
    sender = await player_service.get_player_by_id(db, sender_id)
    if not sender or sender.room_id != room.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="你不在這個房間中",
        )

    # 發送訊息
    try:
        message = await message_service.send_message(
            db=db,
            room_id=room.id,
            sender_id=sender_id,
            receiver_id=request.receiver_id,
            content=request.content,
        )
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e),
        )

    await db.commit()

    # 透過 WebSocket 通知接收者
    await manager.send_to_player(
        room_code=room_code,
        player_id=str(request.receiver_id),
        event_type=WSEventType.PRIVATE_MESSAGE,
        data={
            "message_id": str(message.id),
            "from_id": str(sender_id),
            "from_nickname": sender.nickname,
            "content": message.content,
            "sent_at": message.sent_at.isoformat(),
        },
    )

    return MessageResponse(
        id=message.id,
        sender_id=message.sender_id,
        sender_nickname=message.sender.nickname,
        receiver_id=message.receiver_id,
        receiver_nickname=message.receiver.nickname,
        content=message.content,
        is_read=message.is_read,
        sent_at=message.sent_at,
    )


@router.get(
    "",
    response_model=MessageListResponse,
    summary="取得私訊列表",
)
async def get_messages(
    player_id: UUID = Query(..., description="玩家 ID"),
    room_code: str = Query(..., description="房間碼"),
    other_player_id: UUID | None = Query(None, description="對話對象 ID（可選）"),
    limit: int = Query(50, ge=1, le=100, description="每頁數量"),
    offset: int = Query(0, ge=0, description="偏移量"),
    db: AsyncSession = Depends(get_db),
) -> MessageListResponse:
    """
    取得玩家的私訊列表

    如果指定 other_player_id，只回傳與該玩家的對話記錄。

    Args:
        player_id: 玩家 ID
        room_code: 房間碼
        other_player_id: 對話對象 ID（可選）
        limit: 每頁數量
        offset: 偏移量
        db: 資料庫 session

    Returns:
        私訊列表
    """
    # 取得房間
    room = await room_service.get_room_by_code(db, room_code)
    if not room:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="找不到此房間",
        )

    # 驗證玩家在房間中
    player = await player_service.get_player_by_id(db, player_id)
    if not player or player.room_id != room.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="你不在這個房間中",
        )

    # 取得訊息列表
    messages, total, unread_count = await message_service.get_messages_for_player(
        db=db,
        player_id=player_id,
        room_id=room.id,
        other_player_id=other_player_id,
        limit=limit,
        offset=offset,
    )

    return MessageListResponse(
        messages=[
            MessageResponse(
                id=msg.id,
                sender_id=msg.sender_id,
                sender_nickname=msg.sender.nickname,
                receiver_id=msg.receiver_id,
                receiver_nickname=msg.receiver.nickname,
                content=msg.content,
                is_read=msg.is_read,
                sent_at=msg.sent_at,
            )
            for msg in messages
        ],
        total=total,
        unread_count=unread_count,
    )


@router.get(
    "/conversations",
    summary="取得對話列表",
)
async def get_conversations(
    player_id: UUID = Query(..., description="玩家 ID"),
    room_code: str = Query(..., description="房間碼"),
    db: AsyncSession = Depends(get_db),
) -> dict:
    """
    取得玩家的對話列表（按對話對象分組）

    Args:
        player_id: 玩家 ID
        room_code: 房間碼
        db: 資料庫 session

    Returns:
        對話列表
    """
    # 取得房間
    room = await room_service.get_room_by_code(db, room_code)
    if not room:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="找不到此房間",
        )

    # 驗證玩家在房間中
    player = await player_service.get_player_by_id(db, player_id)
    if not player or player.room_id != room.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="你不在這個房間中",
        )

    # 取得對話列表
    conversations = await message_service.get_conversation_list(
        db=db,
        player_id=player_id,
        room_id=room.id,
    )

    # 取得總未讀數
    total_unread = await message_service.get_unread_count(
        db=db,
        player_id=player_id,
        room_id=room.id,
    )

    return {
        "conversations": conversations,
        "total_unread": total_unread,
    }


@router.put(
    "/read",
    summary="標記訊息為已讀",
)
async def mark_as_read(
    request: MarkReadRequest,
    player_id: UUID = Query(..., description="玩家 ID"),
    sender_id: UUID | None = Query(None, description="發送者 ID（標記與該玩家的所有對話為已讀）"),
    db: AsyncSession = Depends(get_db),
) -> dict:
    """
    標記訊息為已讀

    可以指定訊息 ID 列表，或指定發送者 ID 來標記與該玩家的所有對話為已讀。

    Args:
        request: 標記已讀請求（訊息 ID 列表）
        player_id: 玩家 ID
        sender_id: 發送者 ID（可選）
        db: 資料庫 session

    Returns:
        已標記的訊息數量
    """
    # 驗證玩家存在
    player = await player_service.get_player_by_id(db, player_id)
    if not player:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="找不到此玩家",
        )

    # 標記已讀
    count = await message_service.mark_messages_as_read(
        db=db,
        player_id=player_id,
        message_ids=request.message_ids if request.message_ids else None,
        sender_id=sender_id,
    )

    await db.commit()

    return {
        "marked_count": count,
        "message": f"已標記 {count} 則訊息為已讀",
    }


@router.get(
    "/unread-count",
    summary="取得未讀訊息數量",
)
async def get_unread_count(
    player_id: UUID = Query(..., description="玩家 ID"),
    room_code: str = Query(..., description="房間碼"),
    db: AsyncSession = Depends(get_db),
) -> dict:
    """
    取得玩家的未讀訊息數量

    Args:
        player_id: 玩家 ID
        room_code: 房間碼
        db: 資料庫 session

    Returns:
        未讀數量
    """
    # 取得房間
    room = await room_service.get_room_by_code(db, room_code)
    if not room:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="找不到此房間",
        )

    # 驗證玩家在房間中
    player = await player_service.get_player_by_id(db, player_id)
    if not player or player.room_id != room.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="你不在這個房間中",
        )

    # 取得未讀數量
    unread_count = await message_service.get_unread_count(
        db=db,
        player_id=player_id,
        room_id=room.id,
    )

    return {
        "unread_count": unread_count,
    }
