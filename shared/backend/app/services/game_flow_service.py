"""自動遊戲流程服務

負責管理遊戲的自動進行，包括：
- 階段自動推進
- 計時器管理
- 事件自動觸發
- 投票自動結算
"""
import asyncio
import random
from datetime import datetime, timedelta, timezone
from typing import Optional
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import async_session_maker
from app.models import Room, Player
from app.services import event_service, vote_service
from app.websocket.handlers import (
    notify_phase_change,
    notify_timer_sync,
    notify_event_trigger,
    notify_vote_result,
)


# 各階段時長配置（秒）- 可根據需要調整
PHASE_DURATIONS = {
    2: 15 * 60,    # 準備階段: 15 分鐘
    3: 10 * 60,    # 密謀階段: 10 分鐘
    4: 25 * 60,    # 開場辯論: 25 分鐘
    5: 5 * 60,     # 國內事件: 5 分鐘
    6: 30 * 60,    # 自由辯論: 30 分鐘
    7: 5 * 60,     # 國際事件: 5 分鐘
    8: 5 * 60,     # 第一輪投票: 5 分鐘
    9: 10 * 60,    # 最後攻防: 10 分鐘
    10: 5 * 60,    # 第二輪投票: 5 分鐘
    11: 10 * 60,   # 結果揭曉: 10 分鐘
    12: 0,         # 遊戲結束: 無計時
}

# 階段名稱對應
PHASE_NAMES = {
    1: "waiting",
    2: "preparing",
    3: "conspiracy",
    4: "debate",
    5: "event1",
    6: "debate2",
    7: "event2",
    8: "vote_round1",
    9: "final_debate",
    10: "vote_round2",
    11: "reveal",
    12: "finished",
}

# 儲存各房間的計時器任務
_room_timers: dict[str, asyncio.Task] = {}


async def start_game_flow(room_code: str, room_id: UUID) -> None:
    """
    開始自動遊戲流程

    從準備階段（phase 2）開始，自動推進遊戲直到結束。

    Args:
        room_code: 房間碼
        room_id: 房間 UUID
    """
    # 取消該房間可能存在的舊計時器
    await cancel_room_timer(room_code)

    # 開始推進到第一個遊戲階段
    await advance_to_phase(room_code, room_id, 2)


async def advance_to_phase(room_code: str, room_id: UUID, phase: int) -> None:
    """
    推進到指定階段

    Args:
        room_code: 房間碼
        room_id: 房間 UUID
        phase: 目標階段
    """
    async with async_session_maker() as db:
        # 取得房間
        result = await db.execute(select(Room).where(Room.id == room_id))
        room = result.scalar_one_or_none()

        if not room:
            return

        # 更新階段
        room.phase = phase

        # 設定計時器結束時間
        duration = PHASE_DURATIONS.get(phase, 0)
        if duration > 0:
            room.timer_end_at = datetime.now(timezone.utc) + timedelta(seconds=duration)
        else:
            room.timer_end_at = None

        # 如果是遊戲結束階段，更新狀態
        if phase == 12:
            room.status = "finished"
        elif phase > 1:
            room.status = "playing"

        await db.commit()

        # 廣播階段變更
        phase_name = PHASE_NAMES.get(phase, "unknown")
        await notify_phase_change(
            room_code=room_code,
            phase=phase,
            phase_name=phase_name,
            status=room.status,
        )

        # 廣播計時器同步
        if room.timer_end_at:
            await notify_timer_sync(
                room_code=room_code,
                end_at=room.timer_end_at.isoformat(),
                duration=duration,
            )

        # 執行階段特定邏輯
        await execute_phase_logic(room_code, room_id, phase, db)

    # 啟動自動推進計時器（在 db session 外）
    if duration > 0 and phase < 12:
        await start_auto_advance_timer(room_code, room_id, phase, duration)


async def execute_phase_logic(
    room_code: str,
    room_id: UUID,
    phase: int,
    db: AsyncSession,
) -> None:
    """
    執行階段特定邏輯

    Args:
        room_code: 房間碼
        room_id: 房間 UUID
        phase: 當前階段
        db: 資料庫 session
    """
    if phase == 5:
        # 國內事件：自動觸發一個事件
        await trigger_domestic_event(room_code, room_id, db)

    elif phase == 7:
        # 國際事件：擲骰決定是否觸發
        await trigger_international_event(room_code, room_id, db)

    elif phase == 8:
        # 第一輪投票：初始化投票
        await initialize_voting(room_code, room_id, 1, db)

    elif phase == 10:
        # 第二輪投票：初始化投票
        await initialize_voting(room_code, room_id, 2, db)

    elif phase == 11:
        # 結果揭曉：計算最終結果
        await calculate_final_results(room_code, room_id, db)


async def trigger_domestic_event(
    room_code: str,
    room_id: UUID,
    db: AsyncSession,
) -> None:
    """
    觸發國內事件（Phase 5）

    自動從事件池中選擇一個國內事件觸發。
    """
    try:
        # 觸發一個中等嚴重程度的事件
        event = await event_service.random_trigger_event(
            db=db,
            room_id=room_id,
            min_severity=1,
            max_severity=3,
        )

        if event:
            await notify_event_trigger(
                room_code=room_code,
                event_id=event.get("id", ""),
                event_title=event.get("title", "未知事件"),
                event_description=event.get("description", ""),
                effect_type=event.get("effect_type"),
            )
    except Exception as e:
        print(f"[GameFlow] Error triggering domestic event: {e}")


async def trigger_international_event(
    room_code: str,
    room_id: UUID,
    db: AsyncSession,
) -> None:
    """
    觸發國際事件（Phase 7）

    擲骰子決定是否觸發國際事件：
    - 骰子值 >= 4：觸發國際事件
    - 骰子值 < 4：本輪無國際事件
    """
    # 擲骰子 (1-6)
    dice_roll = random.randint(1, 6)

    # 廣播骰子結果
    from app.websocket.manager import manager
    await manager.broadcast(
        room_code=room_code,
        message={
            "type": "dice_roll",
            "data": {
                "value": dice_roll,
                "threshold": 4,
                "triggered": dice_roll >= 4,
            },
        },
    )

    # 如果骰子值 >= 4，觸發事件
    if dice_roll >= 4:
        try:
            # 觸發一個較嚴重的國際事件
            event = await event_service.random_trigger_event(
                db=db,
                room_id=room_id,
                min_severity=2,
                max_severity=4,
            )

            if event:
                await asyncio.sleep(2)  # 等待骰子動畫
                await notify_event_trigger(
                    room_code=room_code,
                    event_id=event.get("id", ""),
                    event_title=event.get("title", "未知事件"),
                    event_description=event.get("description", ""),
                    effect_type=event.get("effect_type"),
                )
        except Exception as e:
            print(f"[GameFlow] Error triggering international event: {e}")


async def initialize_voting(
    room_code: str,
    room_id: UUID,
    round_num: int,
    db: AsyncSession,
) -> None:
    """
    初始化投票階段

    Args:
        room_code: 房間碼
        room_id: 房間 UUID
        round_num: 投票輪次（1 或 2）
        db: 資料庫 session
    """
    # 更新房間的當前輪次
    result = await db.execute(select(Room).where(Room.id == room_id))
    room = result.scalar_one_or_none()
    if room:
        room.current_round = round_num
        await db.commit()

    # 廣播投票開始
    from app.websocket.manager import manager
    await manager.broadcast(
        room_code=room_code,
        message={
            "type": "vote_start",
            "data": {
                "round": round_num,
                "is_anonymous": round_num == 1,  # 第一輪匿名
            },
        },
    )


async def calculate_final_results(
    room_code: str,
    room_id: UUID,
    db: AsyncSession,
) -> None:
    """
    計算最終結果（Phase 11）

    統計兩輪投票結果並揭曉秘密任務完成情況。
    """
    try:
        # 取得兩輪投票結果
        result = await db.execute(select(Room).where(Room.id == room_id))
        room = result.scalar_one_or_none()

        if not room:
            return

        round1_result = await vote_service.get_round1_result(db, room.id)
        round2_result = await vote_service.get_round2_result(db, room.id)

        # 廣播最終結果
        from app.websocket.manager import manager
        await manager.broadcast(
            room_code=room_code,
            message={
                "type": "final_results",
                "data": {
                    "round1": round1_result,
                    "round2": round2_result,
                    "winning_choice": round2_result.get("winning_choice") if round2_result else None,
                },
            },
        )
    except Exception as e:
        print(f"[GameFlow] Error calculating final results: {e}")


async def start_auto_advance_timer(
    room_code: str,
    room_id: UUID,
    current_phase: int,
    duration: int,
) -> None:
    """
    啟動自動推進計時器

    Args:
        room_code: 房間碼
        room_id: 房間 UUID
        current_phase: 當前階段
        duration: 持續時間（秒）
    """
    # 取消可能存在的舊計時器
    await cancel_room_timer(room_code)

    async def timer_task():
        try:
            await asyncio.sleep(duration)

            # 檢查是否應該自動推進
            next_phase = current_phase + 1
            if next_phase <= 12:
                await advance_to_phase(room_code, room_id, next_phase)
        except asyncio.CancelledError:
            pass  # 計時器被取消
        except Exception as e:
            print(f"[GameFlow] Timer error for room {room_code}: {e}")
        finally:
            # 清理計時器引用
            if room_code in _room_timers:
                del _room_timers[room_code]

    # 創建並儲存計時器任務
    task = asyncio.create_task(timer_task())
    _room_timers[room_code] = task


async def cancel_room_timer(room_code: str) -> None:
    """
    取消房間的計時器

    Args:
        room_code: 房間碼
    """
    if room_code in _room_timers:
        task = _room_timers[room_code]
        if not task.done():
            task.cancel()
            try:
                await task
            except asyncio.CancelledError:
                pass
        del _room_timers[room_code]


async def check_vote_completion(room_code: str, room_id: UUID) -> None:
    """
    檢查投票是否完成，若完成則提前結束投票階段

    此函數在每次投票後調用，用於實現「全員投票完成即結算」的功能。

    Args:
        room_code: 房間碼
        room_id: 房間 UUID
    """
    async with async_session_maker() as db:
        result = await db.execute(select(Room).where(Room.id == room_id))
        room = result.scalar_one_or_none()

        if not room:
            return

        # 只在投票階段檢查
        if room.phase not in (8, 10):
            return

        # 檢查投票進度
        round_num = 1 if room.phase == 8 else 2
        progress = await vote_service.get_vote_progress(db, room.id, round_num)

        if progress.get("is_complete", False):
            # 投票完成，取消計時器並提前推進到下一階段
            # 注意：votes.py 已經廣播了投票結果，這裡只處理階段推進
            await cancel_room_timer(room_code)

            # 短暫延遲讓玩家看到結果
            await asyncio.sleep(3)

            next_phase = room.phase + 1
            await advance_to_phase(room_code, room_id, next_phase)


async def skip_to_next_phase(room_code: str, room_id: UUID) -> bool:
    """
    跳過當前階段，直接進入下一階段（主持人緊急操作用）

    Args:
        room_code: 房間碼
        room_id: 房間 UUID

    Returns:
        是否成功跳過
    """
    async with async_session_maker() as db:
        result = await db.execute(select(Room).where(Room.id == room_id))
        room = result.scalar_one_or_none()

        if not room or room.phase >= 12:
            return False

        next_phase = room.phase + 1

    # 取消當前計時器
    await cancel_room_timer(room_code)

    # 推進到下一階段
    await advance_to_phase(room_code, room_id, next_phase)

    return True
