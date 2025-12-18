"""突發事件服務層"""
import random
from uuid import UUID
from datetime import datetime

from sqlalchemy import select, and_
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models import Event, GameEvent, Room, RoomStatus
from app.data.events import EVENTS, get_event_by_id, get_all_events


async def init_events(db: AsyncSession) -> None:
    """
    初始化事件資料到資料庫

    Args:
        db: 資料庫 session
    """
    for event_data in EVENTS.values():
        # 檢查是否已存在
        existing = await db.get(Event, event_data["id"])
        if not existing:
            event = Event(
                id=event_data["id"],
                title=event_data["title"],
                description=event_data["description"],
                effect_type=event_data["effect_type"],
                severity=event_data["severity"],
            )
            db.add(event)

    await db.flush()


async def get_available_events(
    db: AsyncSession,
    room_id: UUID,
) -> list[dict]:
    """
    取得房間可用的事件（排除已觸發的）

    Args:
        db: 資料庫 session
        room_id: 房間 ID

    Returns:
        可用事件列表
    """
    # 取得已觸發的事件 ID
    result = await db.execute(
        select(GameEvent.event_id).where(GameEvent.room_id == room_id)
    )
    triggered_ids = set(result.scalars().all())

    # 過濾出未觸發的事件
    available = [
        e for e in get_all_events()
        if e["id"] not in triggered_ids
    ]

    return available


async def trigger_event(
    db: AsyncSession,
    room_id: UUID,
    event_id: str,
) -> GameEvent:
    """
    觸發突發事件

    Args:
        db: 資料庫 session
        room_id: 房間 ID
        event_id: 事件 ID

    Returns:
        遊戲事件記錄

    Raises:
        ValueError: 觸發失敗
    """
    # 驗證房間
    room = await db.get(Room, room_id)
    if not room:
        raise ValueError("找不到此房間")

    # 驗證房間階段（只能在事件階段觸發）
    valid_phases = [RoomStatus.EVENT1.value, RoomStatus.EVENT2.value]
    if room.status not in valid_phases:
        raise ValueError("目前不是突發事件階段")

    # 驗證事件存在
    event_data = get_event_by_id(event_id)
    if not event_data:
        raise ValueError("找不到此事件")

    # 檢查事件是否已觸發
    existing = await db.execute(
        select(GameEvent).where(
            and_(
                GameEvent.room_id == room_id,
                GameEvent.event_id == event_id,
            )
        )
    )
    if existing.scalar_one_or_none():
        raise ValueError("此事件已經觸發過")

    # 確保事件存在於資料庫
    event = await db.get(Event, event_id)
    if not event:
        event = Event(
            id=event_data["id"],
            title=event_data["title"],
            description=event_data["description"],
            effect_type=event_data["effect_type"],
            severity=event_data["severity"],
        )
        db.add(event)
        await db.flush()

    # 建立遊戲事件記錄
    game_event = GameEvent(
        room_id=room_id,
        event_id=event_id,
    )
    db.add(game_event)
    await db.flush()
    await db.refresh(game_event, ["event"])

    return game_event


async def random_trigger_event(
    db: AsyncSession,
    room_id: UUID,
    min_severity: int = 1,
    max_severity: int = 5,
) -> GameEvent:
    """
    隨機觸發一個突發事件

    Args:
        db: 資料庫 session
        room_id: 房間 ID
        min_severity: 最低嚴重程度
        max_severity: 最高嚴重程度

    Returns:
        遊戲事件記錄

    Raises:
        ValueError: 沒有可用的事件
    """
    # 取得可用事件
    available = await get_available_events(db, room_id)

    # 根據嚴重程度篩選
    filtered = [
        e for e in available
        if min_severity <= e["severity"] <= max_severity
    ]

    if not filtered:
        raise ValueError("沒有可用的突發事件")

    # 隨機選擇
    selected = random.choice(filtered)

    # 觸發事件
    return await trigger_event(db, room_id, selected["id"])


async def get_triggered_events(
    db: AsyncSession,
    room_id: UUID,
) -> list[GameEvent]:
    """
    取得房間已觸發的事件列表

    Args:
        db: 資料庫 session
        room_id: 房間 ID

    Returns:
        已觸發的事件列表
    """
    result = await db.execute(
        select(GameEvent)
        .options(selectinload(GameEvent.event))
        .where(GameEvent.room_id == room_id)
        .order_by(GameEvent.triggered_at.desc())
    )
    return list(result.scalars().all())


async def get_event_detail(event_id: str) -> dict | None:
    """
    取得事件詳細資訊（包含效果說明）

    Args:
        event_id: 事件 ID

    Returns:
        事件詳細資訊
    """
    return get_event_by_id(event_id)
