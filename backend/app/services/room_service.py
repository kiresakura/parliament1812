"""房間服務層"""
import random
import string
from datetime import datetime, timedelta
from uuid import UUID

from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models import Room, Player, RoomStatus
from app.config import settings


# 避免混淆的字元
ALLOWED_CHARS = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"


def generate_room_code(length: int = 6) -> str:
    """
    生成房間碼（避免混淆字元 0/O, 1/I/L）
    
    Args:
        length: 房間碼長度，預設 6
        
    Returns:
        隨機生成的房間碼
    """
    return "".join(random.choices(ALLOWED_CHARS, k=length))


async def create_room(
    db: AsyncSession,
    host_nickname: str,
) -> tuple[Room, Player]:
    """
    建立新房間
    
    Args:
        db: 資料庫 session
        host_nickname: 主持人暱稱
        
    Returns:
        (房間, 主持人玩家) 元組
    """
    # 生成唯一房間碼
    while True:
        code = generate_room_code()
        existing = await db.execute(
            select(Room).where(Room.code == code)
        )
        if not existing.scalar_one_or_none():
            break
    
    # 建立房間
    room = Room(code=code)
    db.add(room)
    await db.flush()
    
    # 建立主持人玩家
    host = Player(
        room_id=room.id,
        nickname=host_nickname,
        is_host=True,
    )
    db.add(host)
    await db.flush()
    
    return room, host


async def get_room_by_code(
    db: AsyncSession,
    code: str,
) -> Room | None:
    """
    根據房間碼取得房間
    
    Args:
        db: 資料庫 session
        code: 房間碼
        
    Returns:
        房間物件或 None
    """
    result = await db.execute(
        select(Room)
        .options(selectinload(Room.players))
        .where(Room.code == code.upper())
    )
    return result.scalar_one_or_none()


async def get_room_by_id(
    db: AsyncSession,
    room_id: UUID,
) -> Room | None:
    """
    根據 ID 取得房間
    
    Args:
        db: 資料庫 session
        room_id: 房間 ID
        
    Returns:
        房間物件或 None
    """
    result = await db.execute(
        select(Room)
        .options(selectinload(Room.players))
        .where(Room.id == room_id)
    )
    return result.scalar_one_or_none()


async def join_room(
    db: AsyncSession,
    room: Room,
    nickname: str,
) -> Player:
    """
    加入房間
    
    Args:
        db: 資料庫 session
        room: 房間物件
        nickname: 玩家暱稱
        
    Returns:
        玩家物件
        
    Raises:
        ValueError: 房間已滿或狀態不允許加入
    """
    # 檢查房間狀態
    if room.status != RoomStatus.WAITING.value:
        raise ValueError("遊戲已開始，無法加入")
    
    # 檢查人數上限
    player_count = len(room.players) if room.players else 0
    if player_count >= settings.max_players_per_room:
        raise ValueError(f"房間已滿（上限 {settings.max_players_per_room} 人）")
    
    # 建立玩家
    player = Player(
        room_id=room.id,
        nickname=nickname,
    )
    db.add(player)
    await db.flush()
    
    return player


async def change_phase(
    db: AsyncSession,
    room: Room,
    phase: int,
) -> Room:
    """
    切換遊戲階段
    
    Args:
        db: 資料庫 session
        room: 房間物件
        phase: 目標階段
        
    Returns:
        更新後的房間物件
    """
    # 階段對應狀態
    phase_status_map = {
        1: RoomStatus.WAITING,
        2: RoomStatus.PREPARING,
        3: RoomStatus.CONSPIRACY,
        4: RoomStatus.DEBATE,
        5: RoomStatus.EVENT1,
        6: RoomStatus.DEBATE2,
        7: RoomStatus.EVENT2,
        8: RoomStatus.VOTE_ROUND1,
        9: RoomStatus.FINAL_DEBATE,
        10: RoomStatus.VOTE_ROUND2,
        11: RoomStatus.REVEAL,
        12: RoomStatus.FINISHED,
    }
    
    room.phase = phase
    room.status = phase_status_map.get(phase, RoomStatus.WAITING).value
    
    # 進入投票階段時更新輪次
    if phase == 8:
        room.current_round = 1
    elif phase == 10:
        room.current_round = 2
    
    await db.flush()
    return room


async def set_timer(
    db: AsyncSession,
    room: Room,
    duration_seconds: int,
) -> Room:
    """
    設定計時器
    
    Args:
        db: 資料庫 session
        room: 房間物件
        duration_seconds: 持續時間（秒）
        
    Returns:
        更新後的房間物件
    """
    if duration_seconds > 0:
        room.timer_end_at = datetime.utcnow() + timedelta(seconds=duration_seconds)
    else:
        room.timer_end_at = None
    
    await db.flush()
    return room


async def delete_room(
    db: AsyncSession,
    room: Room,
) -> None:
    """
    刪除房間
    
    Args:
        db: 資料庫 session
        room: 房間物件
    """
    await db.delete(room)
    await db.flush()
