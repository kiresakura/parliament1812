"""玩家服務層"""
import hashlib
import hmac
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.config import settings
from app.models import Player, Room, SecretMission
from app.data.roles import ROLES, get_role_info
from app.data.missions import (
    get_mission_by_card_id,
    get_role_from_card_id,
    NFC_CARD_MAPPING,
)


def verify_nfc_hash(card_id: str, secret_hash: str) -> bool:
    """
    驗證 NFC 卡片的 hash 是否正確
    
    Args:
        card_id: 卡片 ID
        secret_hash: 客戶端提供的 hash
        
    Returns:
        是否驗證通過
    """
    # 使用 HMAC-SHA256 驗證
    expected_hash = hmac.new(
        settings.secret_key.encode(),
        card_id.upper().encode(),
        hashlib.sha256,
    ).hexdigest()[:16]  # 只取前 16 個字元
    
    return hmac.compare_digest(expected_hash, secret_hash.lower())


async def get_player_by_id(
    db: AsyncSession,
    player_id: UUID,
) -> Player | None:
    """
    根據 ID 取得玩家
    
    Args:
        db: 資料庫 session
        player_id: 玩家 ID
        
    Returns:
        玩家物件或 None
    """
    result = await db.execute(
        select(Player)
        .options(selectinload(Player.room))
        .where(Player.id == player_id)
    )
    return result.scalar_one_or_none()


async def get_players_by_room(
    db: AsyncSession,
    room_id: UUID,
) -> list[Player]:
    """
    取得房間內所有玩家
    
    Args:
        db: 資料庫 session
        room_id: 房間 ID
        
    Returns:
        玩家列表
    """
    result = await db.execute(
        select(Player)
        .where(Player.room_id == room_id)
        .order_by(Player.joined_at)
    )
    return list(result.scalars().all())


async def scan_nfc_card(
    db: AsyncSession,
    player: Player,
    card_id: str,
    secret_hash: str,
) -> dict:
    """
    NFC 掃卡分配角色
    
    Args:
        db: 資料庫 session
        player: 玩家物件
        card_id: NFC 卡片 ID
        secret_hash: 驗證 hash
        
    Returns:
        角色分配結果
        
    Raises:
        ValueError: 驗證失敗或卡片無效
    """
    # 驗證 hash
    if not verify_nfc_hash(card_id, secret_hash):
        raise ValueError("卡片驗證失敗")
    
    # 檢查玩家是否已有角色
    if player.role_type:
        raise ValueError("你已經有角色了")
    
    # 解析卡片 ID
    role_info = get_role_from_card_id(card_id)
    if not role_info:
        raise ValueError("無效的卡片 ID")
    
    role_type, role_index = role_info
    
    # 取得角色資料
    role_data = get_role_info(role_type)
    if not role_data:
        raise ValueError("找不到角色資料")
    
    # 取得秘密任務
    mission = get_mission_by_card_id(card_id)
    if not mission:
        raise ValueError("找不到秘密任務")
    
    # 檢查同房間是否有人使用相同卡片
    room_players = await get_players_by_room(db, player.room_id)
    for p in room_players:
        if p.id != player.id and p.role_type == role_type and p.role_index == role_index:
            raise ValueError("這張卡片已被其他玩家使用")
    
    # 更新玩家角色
    player.role_type = role_type
    player.role_index = role_index
    player.secret_mission_id = mission["id"]
    
    await db.flush()
    
    return {
        "player_id": player.id,
        "role_type": role_type,
        "role_index": role_index,
        "role_name": role_data["name"],
        "role_occupation": role_data["occupation"],
        "role_description": role_data["description"],
        "role_background": role_data["background"],
        "role_public_stance": role_data["public_stance"],
        "avatar_color": role_data["avatar_color"],
    }


async def get_player_secret_mission(
    db: AsyncSession,
    player: Player,
) -> dict | None:
    """
    取得玩家的秘密任務
    
    Args:
        db: 資料庫 session
        player: 玩家物件
        
    Returns:
        秘密任務資料或 None
    """
    if not player.secret_mission_id:
        return None
    
    from app.data.missions import get_mission_by_id
    mission = get_mission_by_id(player.secret_mission_id)
    
    if not mission:
        return None
    
    return {
        "id": mission["id"],
        "title": mission["title"],
        "description": mission["description"],
        "success_condition": mission["success_condition"],
        "points": mission["points"],
        "difficulty": mission["difficulty"],
    }


async def get_player_full_info(
    db: AsyncSession,
    player: Player,
) -> dict:
    """
    取得玩家完整資訊（包含角色詳情）
    
    Args:
        db: 資料庫 session
        player: 玩家物件
        
    Returns:
        玩家完整資訊
    """
    result = {
        "id": player.id,
        "nickname": player.nickname,
        "is_host": player.is_host,
        "joined_at": player.joined_at,
        "role_type": player.role_type,
        "role_index": player.role_index,
    }
    
    # 如果有角色，加入角色詳情
    if player.role_type:
        role_data = get_role_info(player.role_type)
        if role_data:
            result.update({
                "role_name": role_data["name"],
                "role_occupation": role_data["occupation"],
                "role_description": role_data["description"],
                "role_background": role_data["background"],
                "role_public_stance": role_data["public_stance"],
                "avatar_color": role_data["avatar_color"],
            })
    
    return result


async def assign_role_manually(
    db: AsyncSession,
    player: Player,
    role_code: str,
) -> dict:
    """
    手動分配角色（NFC 備用方案）

    Args:
        db: 資料庫 session
        player: 玩家物件
        role_code: 角色代碼（支援兩種格式）
            - 短格式：W01, F02, L03, R04, M01 等
            - 長格式：WORKER01, FACTORY02 等

    Returns:
        角色分配結果

    Raises:
        ValueError: 代碼無效或角色已被使用
    """
    # 檢查玩家是否已有角色
    if player.role_type:
        raise ValueError("你已經有角色了")

    # 代碼格式轉換映射（短碼 -> 長碼前綴）
    short_to_long = {
        'W': 'WORKER',
        'F': 'FACTORY',
        'L': 'LUDDITE',
        'R': 'REFORMER',
        'M': 'MP',
    }

    import re
    role_code = role_code.upper().strip()

    # 嘗試解析短格式 (W01, F02 等)
    short_match = re.match(r'^([WFLRM])(\d{2})$', role_code)
    if short_match:
        prefix = short_match.group(1)
        number = short_match.group(2)
        card_id = f"{short_to_long[prefix]}{number}"
    # 嘗試解析長格式 (WORKER01, FACTORY02 等)
    elif re.match(r'^(WORKER|FACTORY|LUDDITE|REFORMER|MP)\d{2}$', role_code):
        card_id = role_code
    else:
        raise ValueError("角色代碼格式錯誤，請輸入如 W01、WORKER01 等格式")

    # 解析卡片 ID
    role_info = get_role_from_card_id(card_id)
    if not role_info:
        raise ValueError("無效的角色代碼")

    role_type, role_index = role_info

    # 取得角色資料
    role_data = get_role_info(role_type)
    if not role_data:
        raise ValueError("找不到角色資料")

    # 取得秘密任務
    mission = get_mission_by_card_id(card_id)
    if not mission:
        raise ValueError("找不到秘密任務")

    # 檢查同房間是否有人使用相同角色
    room_players = await get_players_by_room(db, player.room_id)
    for p in room_players:
        if p.id != player.id and p.role_type == role_type and p.role_index == role_index:
            raise ValueError("這個角色已被其他玩家使用")

    # 更新玩家角色
    player.role_type = role_type
    player.role_index = role_index
    player.secret_mission_id = mission["id"]

    await db.flush()

    return {
        "player_id": player.id,
        "role_type": role_type,
        "role_index": role_index,
        "role_name": role_data["name"],
        "role_occupation": role_data["occupation"],
        "role_description": role_data["description"],
        "role_background": role_data["background"],
        "role_public_stance": role_data["public_stance"],
        "avatar_color": role_data["avatar_color"],
        "secret_mission_id": mission["id"],
    }


def generate_nfc_hash(card_id: str) -> str:
    """
    為卡片生成驗證 hash（用於製作 NFC 卡片）
    
    Args:
        card_id: 卡片 ID
        
    Returns:
        hash 字串
    """
    return hmac.new(
        settings.secret_key.encode(),
        card_id.upper().encode(),
        hashlib.sha256,
    ).hexdigest()[:16]


def generate_all_nfc_urls() -> dict[str, str]:
    """
    生成所有 NFC 卡片的 URL（用於製作卡片）
    
    Returns:
        {card_id: url} 映射
    """
    urls = {}
    for card_id in NFC_CARD_MAPPING.keys():
        hash_value = generate_nfc_hash(card_id)
        urls[card_id] = f"parliament1812://role?id={card_id}&secret={hash_value}"
    return urls
