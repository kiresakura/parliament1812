"""投票 API 路由"""
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.schemas import (
    VoteCreate,
    VoteResponse,
    VoteResultRound1,
    VoteResultRound2,
    VoteProgress,
    VoteOption,
    VOTE_OPTIONS,
)
from app.services import room_service, player_service
from app.services import vote_service
from app.websocket import manager
from app.schemas.websocket import WSEventType


router = APIRouter(prefix="/api/rooms/{code}/votes", tags=["votes"])


@router.post(
    "",
    response_model=VoteResponse,
    summary="投票",
)
async def cast_vote(
    code: str,
    request: VoteCreate,
    player_id: UUID = Query(..., description="玩家 ID"),
    vote_round: int = Query(..., ge=1, le=2, description="投票輪次（1 或 2）"),
    db: AsyncSession = Depends(get_db),
) -> VoteResponse:
    """
    投票

    第一輪為匿名投票，只顯示百分比結果。
    第二輪為記名投票，公開唱票顯示每個人的選擇。

    Args:
        code: 房間碼
        request: 投票選項
        player_id: 玩家 ID
        vote_round: 投票輪次
        db: 資料庫 session

    Returns:
        投票記錄
    """
    # 取得房間
    room = await room_service.get_room_by_code(db, code)
    if not room:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="找不到此房間",
        )

    # 投票
    try:
        vote = await vote_service.cast_vote(
            db=db,
            room_id=room.id,
            player_id=player_id,
            vote_round=vote_round,
            choice=request.choice,
        )
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e),
        )

    await db.commit()

    # 取得投票進度並廣播
    progress = await vote_service.get_vote_progress(db, room.id, vote_round)
    await manager.broadcast(
        code,
        WSEventType.VOTE_UPDATE,
        progress,
    )

    # 如果投票完成，廣播結果
    if progress["is_complete"]:
        if vote_round == 1:
            result = await vote_service.get_round1_result(db, room.id)
        else:
            result = await vote_service.get_round2_result(db, room.id)

        await manager.broadcast(
            code,
            WSEventType.VOTE_RESULT,
            result,
        )

    return VoteResponse(
        id=vote.id,
        player_id=vote.player_id,
        round=vote.round,
        choice=vote.choice,
        voted_at=vote.voted_at,
    )


@router.get(
    "/progress",
    response_model=VoteProgress,
    summary="取得投票進度",
)
async def get_vote_progress(
    code: str,
    vote_round: int = Query(..., ge=1, le=2, description="投票輪次"),
    db: AsyncSession = Depends(get_db),
) -> VoteProgress:
    """
    取得投票進度

    Args:
        code: 房間碼
        vote_round: 投票輪次
        db: 資料庫 session

    Returns:
        投票進度
    """
    # 取得房間
    room = await room_service.get_room_by_code(db, code)
    if not room:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="找不到此房間",
        )

    progress = await vote_service.get_vote_progress(db, room.id, vote_round)

    return VoteProgress(
        round=progress["round"],
        voted_count=progress["voted_count"],
        total_players=progress["total_players"],
        progress=progress["progress"],
    )


@router.get(
    "/result",
    summary="取得投票結果",
)
async def get_vote_result(
    code: str,
    vote_round: int = Query(..., ge=1, le=2, description="投票輪次"),
    db: AsyncSession = Depends(get_db),
) -> dict:
    """
    取得投票結果

    第一輪只回傳百分比，第二輪回傳完整記名結果。

    Args:
        code: 房間碼
        vote_round: 投票輪次
        db: 資料庫 session

    Returns:
        投票結果
    """
    # 取得房間
    room = await room_service.get_room_by_code(db, code)
    if not room:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="找不到此房間",
        )

    if vote_round == 1:
        return await vote_service.get_round1_result(db, room.id)
    else:
        return await vote_service.get_round2_result(db, room.id)


@router.get(
    "/my-vote",
    summary="取得自己的投票記錄",
)
async def get_my_vote(
    code: str,
    player_id: UUID = Query(..., description="玩家 ID"),
    vote_round: int = Query(..., ge=1, le=2, description="投票輪次"),
    db: AsyncSession = Depends(get_db),
) -> dict:
    """
    取得自己的投票記錄

    Args:
        code: 房間碼
        player_id: 玩家 ID
        vote_round: 投票輪次
        db: 資料庫 session

    Returns:
        投票記錄
    """
    # 取得房間
    room = await room_service.get_room_by_code(db, code)
    if not room:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="找不到此房間",
        )

    vote = await vote_service.get_player_vote(db, room.id, player_id, vote_round)

    if not vote:
        return {
            "has_voted": False,
            "vote": None,
        }

    return {
        "has_voted": True,
        "vote": {
            "id": str(vote.id),
            "round": vote.round,
            "choice": vote.choice,
            "voted_at": vote.voted_at.isoformat(),
        },
    }


@router.get(
    "/options",
    response_model=list[VoteOption],
    summary="取得投票選項",
)
async def get_vote_options(
    code: str,
    include_hidden: bool = Query(False, description="是否包含隱藏選項"),
) -> list[VoteOption]:
    """
    取得投票選項列表

    Args:
        code: 房間碼
        include_hidden: 是否包含隱藏選項（D 選項）

    Returns:
        投票選項列表
    """
    if include_hidden:
        return VOTE_OPTIONS

    return [opt for opt in VOTE_OPTIONS if not opt.is_hidden]
