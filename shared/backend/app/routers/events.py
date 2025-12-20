"""突發事件 API 路由"""
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.schemas import EventResponse, TriggerEventRequest, GameEventResponse
from app.services import room_service, player_service
from app.services import event_service
from app.websocket import manager, notify_event_trigger
from app.data.events import get_all_events, get_event_by_id


router = APIRouter(prefix="/api/rooms/{code}/events", tags=["events"])


@router.get(
    "",
    response_model=list[EventResponse],
    summary="取得可用的突發事件",
)
async def get_available_events(
    code: str,
    player_id: UUID = Query(..., description="玩家 ID（需為主持人）"),
    db: AsyncSession = Depends(get_db),
) -> list[EventResponse]:
    """
    取得房間可用的突發事件（僅主持人）

    Args:
        code: 房間碼
        player_id: 玩家 ID
        db: 資料庫 session

    Returns:
        可用事件列表
    """
    # 取得房間
    room = await room_service.get_room_by_code(db, code)
    if not room:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="找不到此房間",
        )

    # 驗證主持人
    player = await player_service.get_player_by_id(db, player_id)
    if not player or player.room_id != room.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="你不在這個房間中",
        )
    if not player.is_host:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="只有主持人可以查看事件",
        )

    # 取得可用事件
    events = await event_service.get_available_events(db, room.id)

    return [
        EventResponse(
            id=e["id"],
            title=e["title"],
            description=e["description"],
            effect_type=e["effect_type"],
            severity=e["severity"],
        )
        for e in events
    ]


@router.post(
    "/trigger",
    response_model=GameEventResponse,
    summary="觸發突發事件",
)
async def trigger_event(
    code: str,
    request: TriggerEventRequest,
    player_id: UUID = Query(..., description="玩家 ID（需為主持人）"),
    db: AsyncSession = Depends(get_db),
) -> GameEventResponse:
    """
    觸發指定的突發事件（僅主持人）

    Args:
        code: 房間碼
        request: 觸發請求（事件 ID）
        player_id: 玩家 ID
        db: 資料庫 session

    Returns:
        遊戲事件記錄
    """
    # 取得房間
    room = await room_service.get_room_by_code(db, code)
    if not room:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="找不到此房間",
        )

    # 驗證主持人
    player = await player_service.get_player_by_id(db, player_id)
    if not player or player.room_id != room.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="你不在這個房間中",
        )
    if not player.is_host:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="只有主持人可以觸發事件",
        )

    # 觸發事件
    try:
        game_event = await event_service.trigger_event(
            db=db,
            room_id=room.id,
            event_id=request.event_id,
        )
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e),
        )

    await db.commit()

    # 透過 WebSocket 通知所有玩家
    await notify_event_trigger(
        room_code=code,
        event_id=game_event.event.id,
        title=game_event.event.title,
        description=game_event.event.description,
        effect_type=game_event.event.effect_type,
    )

    return GameEventResponse(
        id=game_event.id,
        event=EventResponse(
            id=game_event.event.id,
            title=game_event.event.title,
            description=game_event.event.description,
            effect_type=game_event.event.effect_type,
            severity=game_event.event.severity,
        ),
        triggered_at=game_event.triggered_at,
    )


@router.post(
    "/random",
    response_model=GameEventResponse,
    summary="隨機觸發突發事件",
)
async def random_trigger_event(
    code: str,
    player_id: UUID = Query(..., description="玩家 ID（需為主持人）"),
    min_severity: int = Query(1, ge=1, le=5, description="最低嚴重程度"),
    max_severity: int = Query(5, ge=1, le=5, description="最高嚴重程度"),
    db: AsyncSession = Depends(get_db),
) -> GameEventResponse:
    """
    隨機觸發一個突發事件（僅主持人）

    Args:
        code: 房間碼
        player_id: 玩家 ID
        min_severity: 最低嚴重程度
        max_severity: 最高嚴重程度
        db: 資料庫 session

    Returns:
        遊戲事件記錄
    """
    # 取得房間
    room = await room_service.get_room_by_code(db, code)
    if not room:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="找不到此房間",
        )

    # 驗證主持人
    player = await player_service.get_player_by_id(db, player_id)
    if not player or player.room_id != room.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="你不在這個房間中",
        )
    if not player.is_host:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="只有主持人可以觸發事件",
        )

    # 隨機觸發事件
    try:
        game_event = await event_service.random_trigger_event(
            db=db,
            room_id=room.id,
            min_severity=min_severity,
            max_severity=max_severity,
        )
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e),
        )

    await db.commit()

    # 透過 WebSocket 通知所有玩家
    await notify_event_trigger(
        room_code=code,
        event_id=game_event.event.id,
        title=game_event.event.title,
        description=game_event.event.description,
        effect_type=game_event.event.effect_type,
    )

    return GameEventResponse(
        id=game_event.id,
        event=EventResponse(
            id=game_event.event.id,
            title=game_event.event.title,
            description=game_event.event.description,
            effect_type=game_event.event.effect_type,
            severity=game_event.event.severity,
        ),
        triggered_at=game_event.triggered_at,
    )


@router.get(
    "/history",
    response_model=list[GameEventResponse],
    summary="取得已觸發的事件歷史",
)
async def get_event_history(
    code: str,
    db: AsyncSession = Depends(get_db),
) -> list[GameEventResponse]:
    """
    取得房間已觸發的事件歷史

    Args:
        code: 房間碼
        db: 資料庫 session

    Returns:
        已觸發的事件列表
    """
    # 取得房間
    room = await room_service.get_room_by_code(db, code)
    if not room:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="找不到此房間",
        )

    # 取得已觸發的事件
    game_events = await event_service.get_triggered_events(db, room.id)

    return [
        GameEventResponse(
            id=ge.id,
            event=EventResponse(
                id=ge.event.id,
                title=ge.event.title,
                description=ge.event.description,
                effect_type=ge.event.effect_type,
                severity=ge.event.severity,
            ),
            triggered_at=ge.triggered_at,
        )
        for ge in game_events
    ]


@router.get(
    "/{event_id}",
    response_model=dict,
    summary="取得事件詳細資訊",
)
async def get_event_detail(event_id: str) -> dict:
    """
    取得事件詳細資訊（包含效果說明）

    Args:
        event_id: 事件 ID

    Returns:
        事件詳細資訊
    """
    event = get_event_by_id(event_id)
    if not event:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="找不到此事件",
        )

    return event
