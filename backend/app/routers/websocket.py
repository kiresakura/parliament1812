"""WebSocket 路由"""
import asyncio
from uuid import UUID

from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.websocket import manager, handle_websocket_message, notify_player_join, notify_player_leave
from app.services import room_service


router = APIRouter(tags=["websocket"])


@router.websocket("/ws/{room_code}")
async def websocket_endpoint(
    websocket: WebSocket,
    room_code: str,
    player_id: str = Query(..., description="玩家 ID"),
):
    """
    WebSocket 連線端點
    
    連線格式：ws://host/ws/{room_code}?player_id={player_id}
    
    Args:
        websocket: WebSocket 連線物件
        room_code: 房間碼
        player_id: 玩家 ID
    """
    # 建立連線
    await manager.connect(websocket, room_code, player_id)
    
    # TODO: 驗證玩家是否在房間中
    # TODO: 取得玩家資訊
    
    try:
        # 通知其他玩家有人加入
        await notify_player_join(
            room_code=room_code,
            player_id=player_id,
            nickname="玩家",  # TODO: 取得真實暱稱
        )
        
        # 持續監聽訊息
        while True:
            try:
                # 接收訊息（帶超時以支援心跳檢測）
                message = await asyncio.wait_for(
                    websocket.receive_text(),
                    timeout=60.0,  # 60 秒超時
                )
                
                # 處理訊息
                # TODO: 取得資料庫 session
                await handle_websocket_message(
                    websocket=websocket,
                    room_code=room_code,
                    player_id=player_id,
                    message=message,
                    db=None,  # TODO: 傳入資料庫 session
                )
            
            except asyncio.TimeoutError:
                # 超時，發送心跳檢測
                try:
                    await websocket.send_text('{"type": "ping"}')
                except Exception:
                    break
    
    except WebSocketDisconnect:
        pass
    
    finally:
        # 斷開連線
        manager.disconnect(room_code, player_id)
        
        # 通知其他玩家有人離開
        await notify_player_leave(
            room_code=room_code,
            player_id=player_id,
            nickname="玩家",  # TODO: 取得真實暱稱
        )
