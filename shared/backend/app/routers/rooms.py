"""房間管理 API 路由"""
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.schemas import (
    RoomCreate,
    RoomJoin,
    RoomResponse,
    RoomDetailResponse,
    PhaseChangeRequest,
    TimerRequest,
    PlayerBrief,
)
from app.services import room_service


router = APIRouter(prefix="/api/rooms", tags=["rooms"])


@router.post("", response_model=dict, status_code=status.HTTP_201_CREATED)
async def create_room(
    request: RoomCreate,
    db: AsyncSession = Depends(get_db),
) -> dict:
    """
    建立新房間
    
    Args:
        request: 建立房間請求（包含主持人暱稱）
        db: 資料庫 session
        
    Returns:
        房間碼和主持人玩家 ID
    """
    room, host = await room_service.create_room(
        db=db,
        host_nickname=request.host_nickname,
    )
    
    return {
        "code": room.code,
        "room_id": str(room.id),
        "player_id": str(host.id),
        "message": f"房間建立成功！房間碼：{room.code}",
    }


@router.get("/{code}", response_model=RoomDetailResponse)
async def get_room(
    code: str,
    db: AsyncSession = Depends(get_db),
) -> RoomDetailResponse:
    """
    取得房間資訊
    
    Args:
        code: 6 位房間碼
        db: 資料庫 session
        
    Returns:
        房間詳細資訊（包含玩家列表）
    """
    room = await room_service.get_room_by_code(db, code)
    
    if not room:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="找不到此房間",
        )
    
    # 轉換玩家列表
    players = [
        PlayerBrief(
            id=p.id,
            nickname=p.nickname,
            role_type=p.role_type,
            is_host=p.is_host,
        )
        for p in room.players
    ]
    
    return RoomDetailResponse(
        id=room.id,
        code=room.code,
        status=room.status,
        phase=room.phase,
        current_round=room.current_round,
        timer_end_at=room.timer_end_at,
        created_at=room.created_at,
        player_count=len(players),
        players=players,
    )


@router.post("/{code}/join", response_model=dict)
async def join_room(
    code: str,
    request: RoomJoin,
    db: AsyncSession = Depends(get_db),
) -> dict:
    """
    加入房間
    
    Args:
        code: 6 位房間碼
        request: 加入房間請求（包含玩家暱稱）
        db: 資料庫 session
        
    Returns:
        玩家 ID 和房間資訊
    """
    room = await room_service.get_room_by_code(db, code)
    
    if not room:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="找不到此房間",
        )
    
    try:
        player = await room_service.join_room(
            db=db,
            room=room,
            nickname=request.nickname,
        )
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e),
        )
    
    return {
        "player_id": str(player.id),
        "room_code": room.code,
        "message": f"成功加入房間 {room.code}",
    }


@router.post("/{code}/phase", response_model=RoomResponse)
async def change_phase(
    code: str,
    request: PhaseChangeRequest,
    player_id: UUID,  # 從查詢參數取得，之後可改為從 JWT 取得
    db: AsyncSession = Depends(get_db),
) -> RoomResponse:
    """
    切換遊戲階段（僅主持人）
    
    Args:
        code: 6 位房間碼
        request: 切換階段請求
        player_id: 玩家 ID（需為主持人）
        db: 資料庫 session
        
    Returns:
        更新後的房間資訊
    """
    room = await room_service.get_room_by_code(db, code)
    
    if not room:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="找不到此房間",
        )
    
    # 檢查是否為主持人
    host = next((p for p in room.players if p.id == player_id and p.is_host), None)
    if not host:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="只有主持人可以切換階段",
        )
    
    room = await room_service.change_phase(db, room, request.phase)
    
    return RoomResponse(
        id=room.id,
        code=room.code,
        status=room.status,
        phase=room.phase,
        current_round=room.current_round,
        timer_end_at=room.timer_end_at,
        created_at=room.created_at,
        player_count=len(room.players),
    )


@router.post("/{code}/timer", response_model=RoomResponse)
async def set_timer(
    code: str,
    request: TimerRequest,
    player_id: UUID,
    db: AsyncSession = Depends(get_db),
) -> RoomResponse:
    """
    設定計時器（僅主持人）
    
    Args:
        code: 6 位房間碼
        request: 計時器請求
        player_id: 玩家 ID（需為主持人）
        db: 資料庫 session
        
    Returns:
        更新後的房間資訊
    """
    room = await room_service.get_room_by_code(db, code)
    
    if not room:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="找不到此房間",
        )
    
    # 檢查是否為主持人
    host = next((p for p in room.players if p.id == player_id and p.is_host), None)
    if not host:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="只有主持人可以設定計時器",
        )
    
    room = await room_service.set_timer(db, room, request.duration_seconds)
    
    return RoomResponse(
        id=room.id,
        code=room.code,
        status=room.status,
        phase=room.phase,
        current_round=room.current_round,
        timer_end_at=room.timer_end_at,
        created_at=room.created_at,
        player_count=len(room.players),
    )


@router.post("/{code}/start", response_model=RoomResponse)
async def start_game(
    code: str,
    player_id: UUID,
    db: AsyncSession = Depends(get_db),
) -> RoomResponse:
    """
    開始遊戲（僅主持人）

    驗證條件：
    - 必須是主持人
    - 所有玩家必須已分配角色
    - 所有玩家必須已準備

    Args:
        code: 6 位房間碼
        player_id: 玩家 ID（需為主持人）
        db: 資料庫 session

    Returns:
        更新後的房間資訊
    """
    room = await room_service.get_room_by_code(db, code)

    if not room:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="找不到此房間",
        )

    # 檢查是否為主持人
    host = next((p for p in room.players if p.id == player_id and p.is_host), None)
    if not host:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="只有主持人可以開始遊戲",
        )

    # 檢查房間狀態
    if room.phase != 1:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="遊戲已經開始",
        )

    try:
        # 切換到準備階段（phase 2），內部會驗證所有玩家已準備
        room = await room_service.change_phase(db, room, 2)
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e),
        )

    return RoomResponse(
        id=room.id,
        code=room.code,
        status=room.status,
        phase=room.phase,
        current_round=room.current_round,
        timer_end_at=room.timer_end_at,
        created_at=room.created_at,
        player_count=len(room.players),
    )


@router.delete("/{code}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_room(
    code: str,
    player_id: UUID,
    db: AsyncSession = Depends(get_db),
) -> None:
    """
    關閉房間（僅主持人）
    
    Args:
        code: 6 位房間碼
        player_id: 玩家 ID（需為主持人）
        db: 資料庫 session
    """
    room = await room_service.get_room_by_code(db, code)
    
    if not room:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="找不到此房間",
        )
    
    # 檢查是否為主持人
    host = next((p for p in room.players if p.id == player_id and p.is_host), None)
    if not host:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="只有主持人可以關閉房間",
        )
    
    await room_service.delete_room(db, room)
