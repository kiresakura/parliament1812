"""
WebSocket 連線管理器

使用 Redis Pub/Sub 處理多房間廣播
支援多伺服器部署時的訊息同步
"""
import asyncio
import json
from datetime import datetime
from typing import Any
from uuid import UUID

from fastapi import WebSocket, WebSocketDisconnect
import redis.asyncio as redis

from app.config import settings
from app.database import redis_manager
from app.schemas.websocket import WSEventType, WSMessage


class ConnectionManager:
    """
    WebSocket 連線管理器
    
    管理所有房間的 WebSocket 連線，使用 Redis Pub/Sub 處理跨伺服器廣播
    """
    
    def __init__(self):
        # 房間連線映射：{room_code: {player_id: WebSocket}}
        self._connections: dict[str, dict[str, WebSocket]] = {}
        # Redis 訂閱器
        self._pubsub: redis.client.PubSub | None = None
        # 訂閱任務
        self._subscribe_task: asyncio.Task | None = None
    
    async def start(self) -> None:
        """啟動連線管理器"""
        # 訂閱所有房間頻道
        self._pubsub = redis_manager.client.pubsub()
        await self._pubsub.psubscribe("room:*")
        # 啟動訂閱監聽任務
        self._subscribe_task = asyncio.create_task(self._listen_messages())
    
    async def stop(self) -> None:
        """停止連線管理器"""
        if self._subscribe_task:
            self._subscribe_task.cancel()
            try:
                await self._subscribe_task
            except asyncio.CancelledError:
                pass
        
        if self._pubsub:
            await self._pubsub.punsubscribe("room:*")
            await self._pubsub.close()
    
    async def _listen_messages(self) -> None:
        """監聽 Redis Pub/Sub 訊息"""
        if not self._pubsub:
            return
        
        try:
            async for message in self._pubsub.listen():
                if message["type"] == "pmessage":
                    # 解析頻道名稱取得房間碼
                    channel = message["channel"]
                    if isinstance(channel, bytes):
                        channel = channel.decode("utf-8")
                    
                    room_code = channel.replace("room:", "")
                    data = message["data"]
                    if isinstance(data, bytes):
                        data = data.decode("utf-8")
                    
                    # 廣播給該房間的所有連線
                    await self._broadcast_local(room_code, data)
        except asyncio.CancelledError:
            pass
    
    async def connect(
        self,
        websocket: WebSocket,
        room_code: str,
        player_id: str,
    ) -> None:
        """
        建立 WebSocket 連線
        
        Args:
            websocket: WebSocket 連線物件
            room_code: 房間碼
            player_id: 玩家 ID
        """
        await websocket.accept()
        
        # 初始化房間連線字典
        if room_code not in self._connections:
            self._connections[room_code] = {}
        
        # 儲存連線
        self._connections[room_code][player_id] = websocket
    
    def disconnect(
        self,
        room_code: str,
        player_id: str,
    ) -> None:
        """
        斷開 WebSocket 連線
        
        Args:
            room_code: 房間碼
            player_id: 玩家 ID
        """
        if room_code in self._connections:
            self._connections[room_code].pop(player_id, None)
            # 如果房間沒有連線了，移除房間
            if not self._connections[room_code]:
                del self._connections[room_code]
    
    async def _broadcast_local(
        self,
        room_code: str,
        message: str,
    ) -> None:
        """
        本地廣播（只廣播給此伺服器的連線）
        
        Args:
            room_code: 房間碼
            message: JSON 訊息字串
        """
        if room_code not in self._connections:
            return
        
        # 複製連線列表避免迭代時修改
        connections = list(self._connections[room_code].items())
        
        for player_id, websocket in connections:
            try:
                await websocket.send_text(message)
            except Exception:
                # 連線已斷開，移除
                self.disconnect(room_code, player_id)
    
    async def broadcast(
        self,
        room_code: str,
        event_type: WSEventType | str,
        data: dict[str, Any],
        exclude_player: str | None = None,
    ) -> None:
        """
        廣播訊息到房間（透過 Redis Pub/Sub）
        
        Args:
            room_code: 房間碼
            event_type: 事件類型
            data: 事件資料
            exclude_player: 要排除的玩家 ID（可選）
        """
        message = WSMessage(
            type=event_type.value if isinstance(event_type, WSEventType) else event_type,
            data=data,
            timestamp=datetime.utcnow(),
        )
        
        # 序列化訊息
        message_json = message.model_dump_json()
        
        # 發布到 Redis
        await redis_manager.publish(f"room:{room_code}", message_json)
    
    async def send_to_player(
        self,
        room_code: str,
        player_id: str,
        event_type: WSEventType | str,
        data: dict[str, Any],
    ) -> bool:
        """
        發送訊息給特定玩家
        
        Args:
            room_code: 房間碼
            player_id: 玩家 ID
            event_type: 事件類型
            data: 事件資料
            
        Returns:
            是否發送成功
        """
        if room_code not in self._connections:
            return False
        
        websocket = self._connections[room_code].get(player_id)
        if not websocket:
            return False
        
        message = WSMessage(
            type=event_type.value if isinstance(event_type, WSEventType) else event_type,
            data=data,
            timestamp=datetime.utcnow(),
        )
        
        try:
            await websocket.send_text(message.model_dump_json())
            return True
        except Exception:
            self.disconnect(room_code, player_id)
            return False
    
    def get_online_players(self, room_code: str) -> list[str]:
        """
        取得房間內在線玩家 ID 列表
        
        Args:
            room_code: 房間碼
            
        Returns:
            玩家 ID 列表
        """
        if room_code not in self._connections:
            return []
        return list(self._connections[room_code].keys())
    
    def get_connection_count(self, room_code: str) -> int:
        """
        取得房間連線數
        
        Args:
            room_code: 房間碼
            
        Returns:
            連線數
        """
        if room_code not in self._connections:
            return 0
        return len(self._connections[room_code])


# 全域連線管理器實例
manager = ConnectionManager()
