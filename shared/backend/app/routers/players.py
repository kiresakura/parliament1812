"""玩家管理 API 路由"""
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.schemas import (
    NFCScanRequest,
    ManualRoleRequest,
    NFCScanResponse,
    PlayerResponse,
    PlayerDetailResponse,
    SecretMissionResponse,
    RoleInfo,
    PlayerReadyRequest,
)
from app.services import room_service, player_service, game_flow_service
from app.data.roles import ROLES, get_role_info
from app.websocket import notify_player_join, notify_player_leave, notify_player_ready


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

    NFC URL 格式：`parliament1812://role?id={card_id}&sig={signature}&uid={uid}`

    使用 UID 綁定防止卡片複製。

    Args:
        code: 房間碼
        request: NFC 掃卡請求（card_id, signature, uid）
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
            signature=request.signature,
            uid=request.uid,
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
        is_ready=player.is_ready,
    )

    return {
        "message": f"角色分配成功！你是 {result['role_name']}",
        **result,
    }


@router.post(
    "/api/rooms/{code}/assign-role-manual",
    response_model=dict,
    summary="手動分配角色（NFC 備用方案）",
)
async def assign_role_manual(
    code: str,
    request: ManualRoleRequest,
    db: AsyncSession = Depends(get_db),
) -> dict:
    """
    手動分配角色（NFC 備用方案）

    當 NFC 掃描無法使用時，玩家可以輸入角色代碼手動選擇角色。

    角色代碼格式：
    - W01, W02, W03, W04 - 紡織工人（4 張卡）
    - F01, F02, F03, F04 - 工廠主（4 張卡）
    - L01, L02, L03, L04 - 盧德派成員（4 張卡）
    - R01, R02, R03, R04 - 社會改革者（4 張卡）
    - M01, M02, M03, M04 - 國會議員（4 張卡）

    Args:
        code: 房間碼
        request: 手動角色分配請求（player_id, role_code）
        db: 資料庫 session

    Returns:
        角色分配結果（包含角色資訊）
    """
    from uuid import UUID

    # 取得房間
    room = await room_service.get_room_by_code(db, code)
    if not room:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="找不到此房間",
        )

    # 取得玩家
    try:
        player_uuid = UUID(request.player_id)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="無效的玩家 ID 格式",
        )

    player = await player_service.get_player_by_id(db, player_uuid)
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

    # 手動分配角色
    try:
        result = await player_service.assign_role_manually(
            db=db,
            player=player,
            role_code=request.role_code,
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
        is_ready=player.is_ready,
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
            is_ready=p.is_ready,
            joined_at=p.joined_at,
        )
        for p in players
    ]


@router.delete(
    "/api/rooms/{code}/leave",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="離開房間",
)
async def leave_room(
    code: str,
    player_id: UUID,
    db: AsyncSession = Depends(get_db),
) -> None:
    """
    玩家離開房間

    Args:
        code: 房間碼
        player_id: 玩家 ID
        db: 資料庫 session
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

    # 如果是主持人，不能離開（需要先關閉房間）
    if player.is_host:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="主持人不能離開房間，請使用關閉房間功能",
        )

    # 儲存玩家資訊用於通知
    player_nickname = player.nickname

    # 刪除玩家
    await player_service.delete_player(db, player)
    await db.commit()

    # 通知其他玩家
    await notify_player_leave(
        room_code=code,
        player_id=str(player_id),
        nickname=player_nickname,
    )


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
        is_ready=info.get("is_ready", False),
        joined_at=info["joined_at"],
        role_name=info.get("role_name"),
        role_description=info.get("role_description"),
        role_background=info.get("role_background"),
    )


@router.put(
    "/api/players/{player_id}/ready",
    response_model=PlayerResponse,
    summary="設定玩家準備狀態",
)
async def set_player_ready(
    player_id: UUID,
    request: PlayerReadyRequest,
    db: AsyncSession = Depends(get_db),
) -> PlayerResponse:
    """
    設定玩家的準備狀態

    玩家在確認角色後，需要點擊「準備」按鈕確認準備狀態。
    當所有玩家都準備完成後，房主才能開始遊戲。

    Args:
        player_id: 玩家 ID
        request: 準備狀態請求
        db: 資料庫 session

    Returns:
        更新後的玩家資訊
    """
    player = await player_service.get_player_by_id(db, player_id)
    if not player:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="找不到此玩家",
        )

    # 更新準備狀態（不再需要先分配角色）
    player = await player_service.set_player_ready(db, player, request.is_ready)

    # 取得房間代碼並通知其他玩家
    room = await room_service.get_room_by_id(db, player.room_id)
    if room:
        await notify_player_ready(
            room_code=room.code,
            player_id=str(player.id),
            is_ready=player.is_ready,
        )

        # 自動開始遊戲檢查：當所有玩家都準備就緒且都有角色時
        if request.is_ready and room.phase == 1:
            await _check_and_auto_start_game(db, room)

    return PlayerResponse(
        id=player.id,
        nickname=player.nickname,
        role_type=player.role_type,
        role_index=player.role_index,
        is_host=player.is_host,
        is_ready=player.is_ready,
        joined_at=player.joined_at,
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


# ============== 私有輔助函數 ==============

async def _check_and_auto_start_game(db: AsyncSession, room) -> None:
    """
    檢查是否滿足自動開始遊戲的條件，若滿足則自動開始

    條件：
    1. 房間狀態為 waiting (phase == 1)
    2. 至少有 2 名玩家
    3. 所有玩家都已準備就緒

    注意：角色分配現在在所有玩家準備就緒後進行

    Args:
        db: 資料庫 session
        room: 房間物件
    """
    from app.websocket.manager import manager

    players = room.players

    # 條件 1: 至少 2 名玩家
    if len(players) < 2:
        return

    # 條件 2: 所有玩家都準備就緒（不再需要先分配角色）
    all_ready = all(p.is_ready for p in players)
    if not all_ready:
        return

    # 所有條件滿足，自動開始遊戲！
    print(f"[AutoStart] 房間 {room.code} 所有玩家就緒，自動開始遊戲")

    # 廣播即將開始的通知
    await manager.broadcast(
        room_code=room.code,
        message={
            "type": "game_auto_starting",
            "data": {
                "message": "所有玩家已就緒，遊戲即將開始！",
                "countdown": 3,
            },
        },
    )

    # 短暫延遲讓玩家看到通知
    import asyncio
    await asyncio.sleep(3)

    # 啟動遊戲流程
    await game_flow_service.start_game_flow(
        room_code=room.code,
        room_id=room.id,
    )
