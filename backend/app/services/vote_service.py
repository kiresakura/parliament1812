"""投票服務層"""
from uuid import UUID
from datetime import datetime

from sqlalchemy import select, and_, func
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models import Vote, Player, Room, RoomStatus


async def cast_vote(
    db: AsyncSession,
    room_id: UUID,
    player_id: UUID,
    vote_round: int,
    choice: str,
) -> Vote:
    """
    投票

    Args:
        db: 資料庫 session
        room_id: 房間 ID
        player_id: 玩家 ID
        vote_round: 投票輪次（1 或 2）
        choice: 投票選項（A/B/C/D）

    Returns:
        投票記錄

    Raises:
        ValueError: 投票失敗
    """
    # 驗證房間
    room = await db.get(Room, room_id)
    if not room:
        raise ValueError("找不到此房間")

    # 驗證投票階段
    if vote_round == 1 and room.status != RoomStatus.VOTE_ROUND1.value:
        raise ValueError("目前不是第一輪投票階段")
    if vote_round == 2 and room.status != RoomStatus.VOTE_ROUND2.value:
        raise ValueError("目前不是第二輪投票階段")

    # 驗證玩家
    player = await db.get(Player, player_id)
    if not player or player.room_id != room_id:
        raise ValueError("玩家不在此房間")

    # 檢查是否已投票
    existing = await db.execute(
        select(Vote).where(
            and_(
                Vote.room_id == room_id,
                Vote.player_id == player_id,
                Vote.round == vote_round,
            )
        )
    )
    if existing.scalar_one_or_none():
        raise ValueError("你已經投過票了")

    # 驗證選項（D 選項需要特殊條件）
    if choice not in ["A", "B", "C", "D"]:
        raise ValueError("無效的投票選項")

    # 建立投票記錄
    vote = Vote(
        room_id=room_id,
        player_id=player_id,
        round=vote_round,
        choice=choice,
    )
    db.add(vote)
    await db.flush()

    return vote


async def get_vote_progress(
    db: AsyncSession,
    room_id: UUID,
    vote_round: int,
) -> dict:
    """
    取得投票進度

    Args:
        db: 資料庫 session
        room_id: 房間 ID
        vote_round: 投票輪次

    Returns:
        投票進度資訊
    """
    # 取得總玩家數
    player_count = await db.execute(
        select(func.count(Player.id)).where(Player.room_id == room_id)
    )
    total_players = player_count.scalar() or 0

    # 取得已投票數
    vote_count = await db.execute(
        select(func.count(Vote.id)).where(
            and_(
                Vote.room_id == room_id,
                Vote.round == vote_round,
            )
        )
    )
    voted_count = vote_count.scalar() or 0

    progress = voted_count / total_players if total_players > 0 else 0

    return {
        "round": vote_round,
        "voted_count": voted_count,
        "total_players": total_players,
        "progress": round(progress, 2),
        "is_complete": voted_count >= total_players,
    }


async def get_round1_result(
    db: AsyncSession,
    room_id: UUID,
) -> dict:
    """
    取得第一輪匿名投票結果（只顯示百分比）

    Args:
        db: 資料庫 session
        room_id: 房間 ID

    Returns:
        第一輪投票結果（百分比）
    """
    # 取得所有第一輪投票
    result = await db.execute(
        select(Vote).where(
            and_(
                Vote.room_id == room_id,
                Vote.round == 1,
            )
        )
    )
    votes = result.scalars().all()

    # 統計各選項票數
    counts = {"A": 0, "B": 0, "C": 0, "D": 0}
    for vote in votes:
        if vote.choice in counts:
            counts[vote.choice] += 1

    total = len(votes)

    # 計算百分比
    percentages = {}
    for key, count in counts.items():
        percentages[key] = round(count / total * 100, 1) if total > 0 else 0

    # 檢查是否完成
    progress = await get_vote_progress(db, room_id, 1)

    return {
        "round": 1,
        "total_votes": total,
        "percentages": percentages,
        "is_complete": progress["is_complete"],
    }


async def get_round2_result(
    db: AsyncSession,
    room_id: UUID,
) -> dict:
    """
    取得第二輪記名投票結果（公開唱票）

    Args:
        db: 資料庫 session
        room_id: 房間 ID

    Returns:
        第二輪投票結果（包含玩家名單）
    """
    # 取得所有第二輪投票（含玩家資訊）
    result = await db.execute(
        select(Vote)
        .options(selectinload(Vote.player))
        .where(
            and_(
                Vote.room_id == room_id,
                Vote.round == 2,
            )
        )
    )
    votes = result.scalars().all()

    # 統計各選項和投票玩家
    results: dict[str, list[str]] = {"A": [], "B": [], "C": [], "D": []}
    counts = {"A": 0, "B": 0, "C": 0, "D": 0}

    for vote in votes:
        if vote.choice in results:
            results[vote.choice].append(vote.player.nickname)
            counts[vote.choice] += 1

    # 找出最高票
    max_count = max(counts.values()) if counts else 0
    winners = [k for k, v in counts.items() if v == max_count and v > 0]
    winner = winners[0] if len(winners) == 1 else None  # 平手則無贏家

    # 檢查是否完成
    progress = await get_vote_progress(db, room_id, 2)

    return {
        "round": 2,
        "total_votes": len(votes),
        "results": results,
        "counts": counts,
        "winner": winner,
        "is_complete": progress["is_complete"],
    }


async def has_player_voted(
    db: AsyncSession,
    room_id: UUID,
    player_id: UUID,
    vote_round: int,
) -> bool:
    """
    檢查玩家是否已投票

    Args:
        db: 資料庫 session
        room_id: 房間 ID
        player_id: 玩家 ID
        vote_round: 投票輪次

    Returns:
        是否已投票
    """
    result = await db.execute(
        select(Vote).where(
            and_(
                Vote.room_id == room_id,
                Vote.player_id == player_id,
                Vote.round == vote_round,
            )
        )
    )
    return result.scalar_one_or_none() is not None


async def get_player_vote(
    db: AsyncSession,
    room_id: UUID,
    player_id: UUID,
    vote_round: int,
) -> Vote | None:
    """
    取得玩家的投票記錄

    Args:
        db: 資料庫 session
        room_id: 房間 ID
        player_id: 玩家 ID
        vote_round: 投票輪次

    Returns:
        投票記錄或 None
    """
    result = await db.execute(
        select(Vote).where(
            and_(
                Vote.room_id == room_id,
                Vote.player_id == player_id,
                Vote.round == vote_round,
            )
        )
    )
    return result.scalar_one_or_none()
