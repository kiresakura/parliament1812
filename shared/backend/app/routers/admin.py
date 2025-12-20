"""管理員 API 路由"""
from fastapi import APIRouter, Depends, HTTPException, status, Query

from app.config import settings
from app.services.player_service import generate_all_nfc_urls, generate_nfc_hash
from app.data.missions import NFC_CARD_MAPPING, get_mission_by_card_id
from app.data.roles import get_role_info


router = APIRouter(prefix="/api/admin", tags=["admin"])


@router.get(
    "/nfc-cards",
    summary="生成所有 NFC 卡片 URL",
    description="生成所有 20 張 NFC 卡片的 URL，用於製作實體卡片",
)
async def get_all_nfc_cards(
    admin_key: str = Query(..., description="管理員金鑰"),
) -> dict:
    """
    生成所有 NFC 卡片 URL（需要管理員金鑰）
    
    Args:
        admin_key: 管理員金鑰（應與 SECRET_KEY 相同）
        
    Returns:
        所有卡片的 URL 和相關資訊
    """
    # 簡單的管理員驗證
    if admin_key != settings.secret_key:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="管理員金鑰錯誤",
        )
    
    # 生成所有 URL
    urls = generate_all_nfc_urls()
    
    # 加入詳細資訊
    cards = []
    for card_id, url in urls.items():
        mission = get_mission_by_card_id(card_id)
        role_type = mission["role_type"] if mission else None
        role = get_role_info(role_type) if role_type else None
        
        cards.append({
            "card_id": card_id,
            "url": url,
            "role_type": role_type,
            "role_name": role["name"] if role else None,
            "mission_title": mission["title"] if mission else None,
            "mission_difficulty": mission["difficulty"] if mission else None,
        })
    
    # 按角色分組
    grouped = {}
    for card in cards:
        role_type = card["role_type"]
        if role_type not in grouped:
            grouped[role_type] = []
        grouped[role_type].append(card)
    
    return {
        "total_cards": len(cards),
        "cards_by_role": grouped,
        "all_cards": cards,
    }


@router.get(
    "/nfc-card/{card_id}",
    summary="生成單張 NFC 卡片 URL",
)
async def get_single_nfc_card(
    card_id: str,
    admin_key: str = Query(..., description="管理員金鑰"),
) -> dict:
    """
    生成單張 NFC 卡片 URL
    
    Args:
        card_id: 卡片 ID（如 WORKER01）
        admin_key: 管理員金鑰
        
    Returns:
        卡片 URL 和詳細資訊
    """
    # 簡單的管理員驗證
    if admin_key != settings.secret_key:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="管理員金鑰錯誤",
        )
    
    card_id = card_id.upper()
    
    if card_id not in NFC_CARD_MAPPING:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="找不到此卡片 ID",
        )
    
    # 生成 hash 和 URL
    hash_value = generate_nfc_hash(card_id)
    url = f"parliament1812://role?id={card_id}&secret={hash_value}"
    
    # 取得任務和角色資訊
    mission = get_mission_by_card_id(card_id)
    role = get_role_info(mission["role_type"]) if mission else None
    
    return {
        "card_id": card_id,
        "url": url,
        "hash": hash_value,
        "role": {
            "type": role["type"],
            "name": role["name"],
            "occupation": role["occupation"],
            "description": role["description"],
        } if role else None,
        "mission": {
            "id": mission["id"],
            "title": mission["title"],
            "description": mission["description"],
            "success_condition": mission["success_condition"],
            "difficulty": mission["difficulty"],
        } if mission else None,
    }
