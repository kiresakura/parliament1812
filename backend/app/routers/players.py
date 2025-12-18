"""玩家管理 API 路由"""
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.schemas import (
    NFCScanRequest,
    NFCScanResponse,
    PlayerResponse,
    PlayerDetailResponse,
    SecretMissionResponse,
    RoleInfo,
)
from app.services import room_service, player_service
from app.data.roles import ROLES, get_role_info
from app.websocket import notify_player_join


router = APIRouter(tags=["players"])


@router.post(
    "/api/rooms/{code}/scan-nfc",
    response_model=dict,
    summary="NFC 掃卡分配角色",
)
async def scan_nfc(
    code: str,
    request: NFCScanRequest,
    player_id: UUID,
    db: AsyncSession = Depends(get_db),
) -> dict:
    """
    NFC 掃卡分配角色
    
    玩家掃描 NFC 卡片後，根據卡片 ID 分配對應的角色和秘密任務。
    
    NFC URL 格式：`parliament1812://role?id={card_id}&secret={hash}`
    
    Args:
        code: 房間碼
        request: NFC 掃卡請求（card_id, secret_hash）
        player_id: 玩家 ID
        db: 資料庫 session
        
    Returns:
        角色分配結果（包含角色資訊，但不包含秘密任務）
    """
    # 取得房間
    room = await room_service.get_room_by_code(db, code)
    if not room:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="找不到此房間",
        )
    
    # 取得玩家
    player = await player_service.get_player_by_id(db, player_id)
    if not player:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="找不到此玩家",
        )
    
    # 檢查玩家是否在此房間
    if player.room_id != room.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="你不在這個房間中",
        )
    
    # 掃卡分配角色
    try:
        result = await player_service.scan_nfc_card(
            db=db,
            player=player,
            card_id=request.card_id,
            secret_hash=request.secret_hash,
        )
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e),
        )
    
    # 通知其他玩家（透過 WebSocket）
    await notify_player_join(
        room_code=code,
        player_id=str(player.id),
        nickname=player.nickname,
        role_type=result["role_type"],
        is_host=player.is_host,
    )
    
    return {
        "message": f"角色分配成功！你是 {result['role_name']}",
        **result,
    }


@router.get(
    "/api/rooms/{code}/players",
    response_model=list[PlayerResponse],
    summary="取得房間內所有玩家",
)
async def get_room_players(
    code: str,
    db: AsyncSession = Depends(get_db),
) -> list[PlayerResponse]:
    """
    取得房間內所有玩家列表
    
    Args:
        code: 房間碼
        db: 資料庫 session
        
    Returns:
        玩家列表（不包含秘密任務）
    """
    # 取得房間
    room = await room_service.get_room_by_code(db, code)
    if not room:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="找不到此房間",
        )
    
    # 取得玩家列表
    players = await player_service.get_players_by_room(db, room.id)
    
    return [
        PlayerResponse(
            id=p.id,
            nickname=p.nickname,
            role_type=p.role_type,
            role_index=p.role_index,
            is_host=p.is_host,
            joined_at=p.joined_at,
        )
        for p in players
    ]


@router.get(
    "/api/players/{player_id}",
    response_model=PlayerDetailResponse,
    summary="取得玩家詳細資訊",
)
async def get_player_detail(
    player_id: UUID,
    db: AsyncSession = Depends(get_db),
) -> PlayerDetailResponse:
    """
    取得玩家詳細資訊（包含角色背景故事）
    
    Args:
        player_id: 玩家 ID
        db: 資料庫 session
        
    Returns:
        玩家詳細資訊
    """
    player = await player_service.get_player_by_id(db, player_id)
    if not player:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="找不到此玩家",
        )
    
    # 取得完整資訊
    info = await player_service.get_player_full_info(db, player)
    
    return PlayerDetailResponse(
        id=info["id"],
        nickname=info["nickname"],
        role_type=info.get("role_type"),
        role_index=info.get("role_index"),
        is_host=info["is_host"],
        joined_at=info["joined_at"],
        role_name=info.get("role_name"),
        role_description=info.get("role_description"),
        role_background=info.get("role_background"),
    )


@router.get(
    "/api/players/{player_id}/secret",
    response_model=SecretMissionResponse,
    summary="取得自己的秘密任務",
)
async def get_player_secret(
    player_id: UUID,
    requesting_player_id: UUID,
    db: AsyncSession = Depends(get_db),
) -> SecretMissionResponse:
    """
    取得自己的秘密任務
    
    注意：只能查看自己的秘密任務！
    
    Args:
        player_id: 要查詢的玩家 ID
        requesting_player_id: 請求者的玩家 ID（用於驗證）
        db: 資料庫 session
        
    Returns:
        秘密任務資訊
    """
    # 驗證是否查詢自己的任務
    if player_id != requesting_player_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="你只能查看自己的秘密任務",
        )
    
    player = await player_service.get_player_by_id(db, player_id)
    if not player:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="找不到此玩家",
        )
    
    # 取得秘密任務
    mission = await player_service.get_player_secret_mission(db, player)
    if not mission:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="你還沒有秘密任務，請先掃描 NFC 卡片",
        )
    
    return SecretMissionResponse(
        id=mission["id"],
        title=mission["title"],
        description=mission["description"],
        success_condition=mission["success_condition"],
        points=mission["points"],
    )


@router.get(
    "/api/roles",
    response_model=list[RoleInfo],
    summary="取得所有角色資訊",
)
async def get_all_roles() -> list[RoleInfo]:
    """
    取得所有角色的公開資訊
    
    Returns:
        所有角色資訊列表
    """
    return [
        RoleInfo(
            type=role["type"],
            name=role["name"],
            age=role["age"],
            occupation=role["occupation"],
            description=role["description"],
            background=role["background"],
            public_stance=role["public_stance"],
        )
        for role in ROLES.values()
    ]


@router.get(
    "/api/roles/{role_type}",
    response_model=RoleInfo,
    summary="取得特定角色資訊",
)
async def get_role(role_type: str) -> RoleInfo:
    """
    取得特定角色的公開資訊
    
    Args:
        role_type: 角色類型（worker/factory/luddite/reformer/mp）
        
    Returns:
        角色資訊
    """
    role = get_role_info(role_type.lower())
    if not role:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="找不到此角色",
        )
    
    return RoleInfo(
        type=role["type"],
        name=role["name"],
        age=role["age"],
        occupation=role["occupation"],
        description=role["description"],
        background=role["background"],
        public_stance=role["public_stance"],
    )
