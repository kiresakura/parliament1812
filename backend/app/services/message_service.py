"""私訊服務層"""
from uuid import UUID
from datetime import datetime

from sqlalchemy import select, and_, or_, func
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models import PrivateMessage, Player, Room


async def send_message(
    db: AsyncSession,
    room_id: UUID,
    sender_id: UUID,
    receiver_id: UUID,
    content: str,
) -> PrivateMessage:
    """
    發送私訊

    Args:
        db: 資料庫 session
        room_id: 房間 ID
        sender_id: 發送者 ID
        receiver_id: 接收者 ID
        content: 訊息內容

    Returns:
        私訊物件

    Raises:
        ValueError: 發送者或接收者不存在
    """
    # 驗證發送者
    sender = await db.get(Player, sender_id)
    if not sender:
        raise ValueError("找不到發送者")

    # 驗證接收者
    receiver = await db.get(Player, receiver_id)
    if not receiver:
        raise ValueError("找不到接收者")

    # 驗證兩人在同一房間
    if sender.room_id != receiver.room_id:
        raise ValueError("接收者不在同一房間")

    if sender.room_id != room_id:
        raise ValueError("你不在這個房間中")

    # 不能發訊息給自己
    if sender_id == receiver_id:
        raise ValueError("不能發訊息給自己")

    # 建立私訊
    message = PrivateMessage(
        room_id=room_id,
        sender_id=sender_id,
        receiver_id=receiver_id,
        content=content,
    )
    db.add(message)
    await db.flush()
    await db.refresh(message, ["sender", "receiver"])

    return message


async def get_messages_for_player(
    db: AsyncSession,
    player_id: UUID,
    room_id: UUID,
    other_player_id: UUID | None = None,
    limit: int = 50,
    offset: int = 0,
) -> tuple[list[PrivateMessage], int, int]:
    """
    取得玩家的私訊列表

    Args:
        db: 資料庫 session
        player_id: 玩家 ID
        room_id: 房間 ID
        other_player_id: 對話對象（如果有，只取得與該玩家的對話）
        limit: 每頁數量
        offset: 偏移量

    Returns:
        (訊息列表, 總數, 未讀數) 元組
    """
    # 基本條件：與該玩家相關的訊息（發送或接收）
    base_condition = and_(
        PrivateMessage.room_id == room_id,
        or_(
            PrivateMessage.sender_id == player_id,
            PrivateMessage.receiver_id == player_id,
        ),
    )

    # 如果指定對話對象
    if other_player_id:
        base_condition = and_(
            base_condition,
            or_(
                and_(
                    PrivateMessage.sender_id == player_id,
                    PrivateMessage.receiver_id == other_player_id,
                ),
                and_(
                    PrivateMessage.sender_id == other_player_id,
                    PrivateMessage.receiver_id == player_id,
                ),
            ),
        )

    # 查詢訊息
    result = await db.execute(
        select(PrivateMessage)
        .options(
            selectinload(PrivateMessage.sender),
            selectinload(PrivateMessage.receiver),
        )
        .where(base_condition)
        .order_by(PrivateMessage.sent_at.desc())
        .offset(offset)
        .limit(limit)
    )
    messages = list(result.scalars().all())

    # 計算總數
    count_result = await db.execute(
        select(func.count(PrivateMessage.id)).where(base_condition)
    )
    total = count_result.scalar() or 0

    # 計算未讀數（接收的訊息中未讀的）
    unread_condition = and_(
        PrivateMessage.room_id == room_id,
        PrivateMessage.receiver_id == player_id,
        PrivateMessage.is_read == False,
    )
    if other_player_id:
        unread_condition = and_(
            unread_condition,
            PrivateMessage.sender_id == other_player_id,
        )

    unread_result = await db.execute(
        select(func.count(PrivateMessage.id)).where(unread_condition)
    )
    unread_count = unread_result.scalar() or 0

    return messages, total, unread_count


async def get_conversation_list(
    db: AsyncSession,
    player_id: UUID,
    room_id: UUID,
) -> list[dict]:
    """
    取得玩家的對話列表（按對話對象分組）

    Args:
        db: 資料庫 session
        player_id: 玩家 ID
        room_id: 房間 ID

    Returns:
        對話列表，每個對話包含對方資訊和最新訊息
    """
    # 取得所有相關訊息的對話對象
    result = await db.execute(
        select(PrivateMessage)
        .options(
            selectinload(PrivateMessage.sender),
            selectinload(PrivateMessage.receiver),
        )
        .where(
            and_(
                PrivateMessage.room_id == room_id,
                or_(
                    PrivateMessage.sender_id == player_id,
                    PrivateMessage.receiver_id == player_id,
                ),
            )
        )
        .order_by(PrivateMessage.sent_at.desc())
    )
    messages = result.scalars().all()

    # 按對話對象分組
    conversations: dict[UUID, dict] = {}
    for msg in messages:
        # 找出對話對象
        other_id = msg.receiver_id if msg.sender_id == player_id else msg.sender_id
        other_player = msg.receiver if msg.sender_id == player_id else msg.sender

        if other_id not in conversations:
            conversations[other_id] = {
                "player_id": str(other_id),
                "nickname": other_player.nickname,
                "role_type": other_player.role_type,
                "last_message": {
                    "content": msg.content,
                    "sent_at": msg.sent_at.isoformat(),
                    "is_from_me": msg.sender_id == player_id,
                },
                "unread_count": 0,
            }

        # 計算未讀數（對方發給我的未讀訊息）
        if msg.receiver_id == player_id and not msg.is_read:
            conversations[other_id]["unread_count"] += 1

    return list(conversations.values())


async def mark_messages_as_read(
    db: AsyncSession,
    player_id: UUID,
    message_ids: list[UUID] | None = None,
    sender_id: UUID | None = None,
) -> int:
    """
    標記訊息為已讀

    Args:
        db: 資料庫 session
        player_id: 玩家 ID（接收者）
        message_ids: 要標記的訊息 ID 列表（如果有）
        sender_id: 發送者 ID（如果有，標記該發送者的所有訊息為已讀）

    Returns:
        已更新的訊息數量
    """
    # 基本條件：只能標記發給自己的訊息
    conditions = [
        PrivateMessage.receiver_id == player_id,
        PrivateMessage.is_read == False,
    ]

    if message_ids:
        conditions.append(PrivateMessage.id.in_(message_ids))

    if sender_id:
        conditions.append(PrivateMessage.sender_id == sender_id)

    # 查詢符合條件的訊息
    result = await db.execute(
        select(PrivateMessage).where(and_(*conditions))
    )
    messages = result.scalars().all()

    # 更新為已讀
    count = 0
    for msg in messages:
        msg.is_read = True
        count += 1

    await db.flush()
    return count


async def get_message_by_id(
    db: AsyncSession,
    message_id: UUID,
) -> PrivateMessage | None:
    """
    根據 ID 取得私訊

    Args:
        db: 資料庫 session
        message_id: 訊息 ID

    Returns:
        私訊物件或 None
    """
    result = await db.execute(
        select(PrivateMessage)
        .options(
            selectinload(PrivateMessage.sender),
            selectinload(PrivateMessage.receiver),
        )
        .where(PrivateMessage.id == message_id)
    )
    return result.scalar_one_or_none()


async def get_unread_count(
    db: AsyncSession,
    player_id: UUID,
    room_id: UUID,
) -> int:
    """
    取得玩家的未讀訊息數量

    Args:
        db: 資料庫 session
        player_id: 玩家 ID
        room_id: 房間 ID

    Returns:
        未讀數量
    """
    result = await db.execute(
        select(func.count(PrivateMessage.id)).where(
            and_(
                PrivateMessage.room_id == room_id,
                PrivateMessage.receiver_id == player_id,
                PrivateMessage.is_read == False,
            )
        )
    )
    return result.scalar() or 0
