# 1812 國會風雲 - 後端開發指南 (FastAPI + PostgreSQL + Redis)

## 專案概述

這是 1812 國會風雲遊戲的後端 API 服務。
使用 **FastAPI** 框架，**PostgreSQL** 資料庫，**Redis** 快取，部署於 **Railway**。

**生產環境**: `https://1812-production.up.railway.app`
**API 文檔**: `https://1812-production.up.railway.app/docs`

---

## 目錄結構

```
shared/backend/
├── app/
│   ├── __init__.py
│   ├── main.py                 # FastAPI 應用入口
│   ├── config.py               # 環境變數配置
│   ├── database.py             # 資料庫連線
│   ├── api/                    # API 版本管理 (可選)
│   ├── models/                 # SQLAlchemy ORM 模型
│   │   ├── player.py
│   │   ├── room.py
│   │   ├── role.py
│   │   ├── vote.py
│   │   └── event.py
│   ├── schemas/                # Pydantic 驗證模型
│   │   ├── player.py
│   │   ├── room.py
│   │   ├── role.py
│   │   ├── nfc.py
│   │   └── vote.py
│   ├── routers/                # API 路由
│   │   ├── rooms.py            # 房間 CRUD
│   │   ├── players.py          # 玩家管理
│   │   ├── nfc.py              # NFC 驗證
│   │   ├── votes.py            # 投票系統
│   │   ├── events.py           # 事件卡
│   │   ├── messages.py         # 訊息
│   │   ├── admin.py            # 管理員 API
│   │   └── websocket.py        # WebSocket 路由
│   ├── services/               # 業務邏輯
│   │   ├── room_service.py
│   │   ├── nfc_service.py
│   │   ├── game_service.py
│   │   └── vote_service.py
│   ├── websocket/              # WebSocket 處理
│   │   ├── manager.py          # 連線管理
│   │   └── events.py           # 事件處理
│   └── data/                   # 靜態資料
│       └── roles.json          # 角色定義
├── alembic/                    # 資料庫遷移
│   ├── versions/
│   ├── env.py
│   └── script.py.mako
├── alembic.ini
├── requirements.txt
├── Dockerfile
├── railway.toml
└── .env.example
```

---

## 技術棧

| 項目 | 技術 | 版本 |
|------|------|------|
| 框架 | FastAPI | 0.109.0 |
| ASGI | Uvicorn | 0.27.0 |
| ORM | SQLAlchemy | 2.0.25 |
| 資料庫 | PostgreSQL | 15+ |
| 快取 | Redis | 7+ |
| 驗證 | Pydantic | 2.5.3 |
| WebSocket | websockets | 12.0 |
| 遷移 | Alembic | 1.13.1 |

---

## 環境變數

```env
# 資料庫
DATABASE_URL=postgresql+asyncpg://user:password@host:5432/parliament1812

# Redis
REDIS_URL=redis://default:password@host:6379

# 安全性
SECRET_KEY=your-secret-key-here
ADMIN_KEY=your-admin-key-here

# 環境
ENVIRONMENT=development  # development | production
DEBUG=true
```


---

## API 端點

### 房間 (Rooms)

| 方法 | 端點 | 說明 |
|------|------|------|
| POST | `/api/rooms` | 建立房間 |
| GET | `/api/rooms/{code}` | 取得房間資訊 |
| POST | `/api/rooms/{code}/join` | 加入房間 |
| DELETE | `/api/rooms/{code}` | 刪除房間 |
| GET | `/api/rooms/{code}/players` | 取得房間玩家 |
| POST | `/api/rooms/{code}/start` | 開始遊戲 |

### 玩家 (Players)

| 方法 | 端點 | 說明 |
|------|------|------|
| GET | `/api/players/{player_id}` | 取得玩家資訊 |
| PATCH | `/api/players/{player_id}` | 更新玩家資訊 |
| DELETE | `/api/players/{player_id}` | 玩家離開 |

### NFC 驗證

| 方法 | 端點 | 說明 |
|------|------|------|
| POST | `/api/nfc/scan` | NFC 掃卡驗證並分配角色 |
| GET | `/api/nfc/validate/{card_id}` | 驗證卡片有效性 |

### 角色 (Roles)

| 方法 | 端點 | 說明 |
|------|------|------|
| GET | `/api/roles` | 取得所有角色 |
| GET | `/api/roles/{role_type}` | 取得特定角色 |

### 投票 (Votes)

| 方法 | 端點 | 說明 |
|------|------|------|
| POST | `/api/rooms/{code}/votes` | 發起投票 |
| POST | `/api/rooms/{code}/votes/{vote_id}/cast` | 投票 |
| GET | `/api/rooms/{code}/votes/{vote_id}/results` | 投票結果 |

### 管理員 (Admin)

| 方法 | 端點 | 說明 |
|------|------|------|
| GET | `/api/admin/nfc-cards` | 取得所有 NFC 卡片資料 (含 hash) |
| POST | `/api/admin/rooms/{code}/assign-role` | 手動分配角色 |
| DELETE | `/api/admin/rooms` | 清除所有房間 |

### WebSocket

```
GET /ws/{room_code}/{player_id}
```

---

## NFC 防作弊系統

### 卡片 ID 規範

| 角色 | 卡片 ID | role_type |
|------|---------|-----------|
| 工人 | WORKER01 ~ WORKER04 | `worker` |
| 工廠主 | FACTORY01 ~ FACTORY04 | `factory_owner` |
| 盧德派 | LUDDITE01 ~ LUDDITE04 | `luddite` |
| 改革者 | REFORMER01 ~ REFORMER04 | `reformer` |
| 議員 | MP01 ~ MP04 | `mp` |
| 👑 喬治三世 | GEORGEIII01 ~ GEORGEIII04 | `george_iii` |

### NFC 驗證流程

```
1. 前端掃描 NFC 卡片
2. 解析 URI: parliament1812://role?id=WORKER01&secret=a1b2c3d4e5f67890
3. 呼叫 POST /api/nfc/scan
4. 後端驗證:
   - 檢查 card_id 格式
   - 驗證 signature (HMAC-SHA256)
   - 確認卡片未被使用
   - 分配角色給玩家
5. 回傳角色資訊
```

### NFC Service 實作

```python
# app/services/nfc_service.py

import hmac
import hashlib
from typing import Optional

class NFCService:
    def __init__(self, secret_key: str):
        self.secret_key = secret_key
    
    def generate_signature(self, card_id: str) -> str:
        """產生 16 字元的 HMAC-SHA256 簽名"""
        message = card_id.encode('utf-8')
        key = self.secret_key.encode('utf-8')
        signature = hmac.new(key, message, hashlib.sha256).hexdigest()
        return signature[:16]  # 取前 16 字元
    
    def verify_signature(self, card_id: str, signature: str) -> bool:
        """驗證簽名"""
        expected = self.generate_signature(card_id)
        return hmac.compare_digest(expected, signature)
    
    def parse_card_id(self, card_id: str) -> Optional[dict]:
        """解析卡片 ID，回傳 role_type 和 index"""
        import re
        
        patterns = {
            r'^WORKER(\d{2})$': 'worker',
            r'^FACTORY(\d{2})$': 'factory_owner',
            r'^LUDDITE(\d{2})$': 'luddite',
            r'^REFORMER(\d{2})$': 'reformer',
            r'^MP(\d{2})$': 'mp',
            r'^GEORGEIII(\d{2})$': 'george_iii',
        }
        
        for pattern, role_type in patterns.items():
            match = re.match(pattern, card_id)
            if match:
                index = int(match.group(1))
                return {'role_type': role_type, 'role_index': index}
        
        return None
```


---

## 資料模型 (SQLAlchemy)

### Room Model

```python
# app/models/room.py

from sqlalchemy import Column, String, DateTime, Enum, ForeignKey
from sqlalchemy.orm import relationship
from datetime import datetime
import enum
import secrets

from app.database import Base

class RoomStatus(str, enum.Enum):
    WAITING = "waiting"
    PLAYING = "playing"
    FINISHED = "finished"

class Room(Base):
    __tablename__ = "rooms"
    
    id = Column(String, primary_key=True)
    code = Column(String(6), unique=True, index=True, nullable=False)
    host_id = Column(String, ForeignKey("players.id"), nullable=False)
    status = Column(Enum(RoomStatus), default=RoomStatus.WAITING)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    players = relationship("Player", back_populates="room", foreign_keys="Player.room_id")
    host = relationship("Player", foreign_keys=[host_id])
    
    @staticmethod
    def generate_code() -> str:
        """產生 6 位數房間代碼"""
        return ''.join(secrets.choice('ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789') for _ in range(6))
```

### Player Model

```python
# app/models/player.py

from sqlalchemy import Column, String, Boolean, Integer, ForeignKey, DateTime
from sqlalchemy.orm import relationship
from datetime import datetime
import uuid

from app.database import Base

class Player(Base):
    __tablename__ = "players"
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    nickname = Column(String(50), nullable=False)
    room_id = Column(String, ForeignKey("rooms.id"), nullable=True)
    is_host = Column(Boolean, default=False)
    role_type = Column(String, nullable=True)
    role_index = Column(Integer, nullable=True)
    card_id = Column(String, nullable=True, unique=True)  # 防止重複使用
    connected = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    room = relationship("Room", back_populates="players", foreign_keys=[room_id])
    
    @property
    def has_role(self) -> bool:
        return self.role_type is not None and self.role_index is not None
```

---

## Pydantic Schemas

### Room Schemas

```python
# app/schemas/room.py

from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime
from enum import Enum

class RoomStatus(str, Enum):
    WAITING = "waiting"
    PLAYING = "playing"
    FINISHED = "finished"

class CreateRoomRequest(BaseModel):
    host_nickname: str = Field(..., min_length=1, max_length=50)

class JoinRoomRequest(BaseModel):
    nickname: str = Field(..., min_length=1, max_length=50)

class PlayerResponse(BaseModel):
    id: str
    nickname: str
    is_host: bool
    role_type: Optional[str] = None
    role_index: Optional[int] = None
    
    class Config:
        from_attributes = True

class RoomResponse(BaseModel):
    code: str
    host_id: str
    status: RoomStatus
    players: List[PlayerResponse]
    created_at: datetime
    
    class Config:
        from_attributes = True

class CreateRoomResponse(BaseModel):
    code: str
    player: PlayerResponse
```

### NFC Schemas

```python
# app/schemas/nfc.py

from pydantic import BaseModel, Field
from typing import Optional

class NFCScanRequest(BaseModel):
    room_code: str = Field(..., min_length=6, max_length=6)
    player_id: str
    card_id: str = Field(..., pattern=r'^[A-Z]+\d{2}$')
    signature: str = Field(..., min_length=16, max_length=16)

class RoleInfo(BaseModel):
    id: str
    name_zh: str
    name_en: str
    faction: str
    description: Optional[str] = None

class NFCScanResponse(BaseModel):
    success: bool
    role_type: Optional[str] = None
    role_index: Optional[int] = None
    role: Optional[RoleInfo] = None
    message: Optional[str] = None
```


---

## API 路由實作

### NFC Router

```python
# app/routers/nfc.py

from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.schemas.nfc import NFCScanRequest, NFCScanResponse
from app.services.nfc_service import NFCService
from app.models.player import Player
from app.models.room import Room
from app.config import settings

router = APIRouter(prefix="/api/nfc", tags=["NFC"])

nfc_service = NFCService(settings.SECRET_KEY)

@router.post("/scan", response_model=NFCScanResponse)
async def scan_nfc(
    request: NFCScanRequest,
    db: AsyncSession = Depends(get_db)
):
    # 1. 驗證簽名
    if not nfc_service.verify_signature(request.card_id, request.signature):
        raise HTTPException(status_code=400, detail="Invalid signature")
    
    # 2. 解析卡片 ID
    card_info = nfc_service.parse_card_id(request.card_id)
    if not card_info:
        raise HTTPException(status_code=400, detail="Invalid card ID format")
    
    # 3. 檢查房間
    room = await db.execute(
        select(Room).where(Room.code == request.room_code)
    )
    room = room.scalar_one_or_none()
    if not room:
        raise HTTPException(status_code=404, detail="Room not found")
    
    # 4. 檢查玩家
    player = await db.execute(
        select(Player).where(Player.id == request.player_id)
    )
    player = player.scalar_one_or_none()
    if not player:
        raise HTTPException(status_code=404, detail="Player not found")
    
    # 5. 檢查卡片是否已被使用
    existing = await db.execute(
        select(Player).where(Player.card_id == request.card_id)
    )
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="Card already used")
    
    # 6. 分配角色
    player.role_type = card_info['role_type']
    player.role_index = card_info['role_index']
    player.card_id = request.card_id
    
    await db.commit()
    await db.refresh(player)
    
    # 7. 取得角色資訊
    role = get_role_by_type(card_info['role_type'])
    
    return NFCScanResponse(
        success=True,
        role_type=card_info['role_type'],
        role_index=card_info['role_index'],
        role=role
    )
```

### Rooms Router

```python
# app/routers/rooms.py

from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.database import get_db
from app.schemas.room import (
    CreateRoomRequest, CreateRoomResponse,
    JoinRoomRequest, RoomResponse, PlayerResponse
)
from app.models.room import Room, RoomStatus
from app.models.player import Player

router = APIRouter(prefix="/api/rooms", tags=["Rooms"])

@router.post("", response_model=CreateRoomResponse)
async def create_room(
    request: CreateRoomRequest,
    db: AsyncSession = Depends(get_db)
):
    # 建立玩家
    player = Player(
        nickname=request.host_nickname,
        is_host=True
    )
    db.add(player)
    
    # 建立房間
    room = Room(
        code=Room.generate_code(),
        host_id=player.id
    )
    db.add(room)
    
    # 關聯玩家和房間
    player.room_id = room.id
    
    await db.commit()
    await db.refresh(room)
    await db.refresh(player)
    
    return CreateRoomResponse(
        code=room.code,
        player=PlayerResponse.model_validate(player)
    )

@router.get("/{code}", response_model=RoomResponse)
async def get_room(
    code: str,
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(
        select(Room).where(Room.code == code)
    )
    room = result.scalar_one_or_none()
    
    if not room:
        raise HTTPException(status_code=404, detail="Room not found")
    
    return RoomResponse.model_validate(room)

@router.post("/{code}/join", response_model=PlayerResponse)
async def join_room(
    code: str,
    request: JoinRoomRequest,
    db: AsyncSession = Depends(get_db)
):
    # 檢查房間
    result = await db.execute(
        select(Room).where(Room.code == code)
    )
    room = result.scalar_one_or_none()
    
    if not room:
        raise HTTPException(status_code=404, detail="Room not found")
    
    if room.status != RoomStatus.WAITING:
        raise HTTPException(status_code=400, detail="Game already started")
    
    # 檢查人數
    if len(room.players) >= 6:
        raise HTTPException(status_code=400, detail="Room is full")
    
    # 建立玩家
    player = Player(
        nickname=request.nickname,
        room_id=room.id,
        is_host=False
    )
    db.add(player)
    
    await db.commit()
    await db.refresh(player)
    
    return PlayerResponse.model_validate(player)
```


---

## WebSocket 實作

### Connection Manager

```python
# app/websocket/manager.py

from typing import Dict, Set
from fastapi import WebSocket
import json

class ConnectionManager:
    def __init__(self):
        # room_code -> {player_id -> WebSocket}
        self.rooms: Dict[str, Dict[str, WebSocket]] = {}
    
    async def connect(self, websocket: WebSocket, room_code: str, player_id: str):
        await websocket.accept()
        
        if room_code not in self.rooms:
            self.rooms[room_code] = {}
        
        self.rooms[room_code][player_id] = websocket
    
    def disconnect(self, room_code: str, player_id: str):
        if room_code in self.rooms:
            self.rooms[room_code].pop(player_id, None)
            if not self.rooms[room_code]:
                del self.rooms[room_code]
    
    async def broadcast_to_room(self, room_code: str, message: dict, exclude: str = None):
        """廣播訊息給房間內所有玩家"""
        if room_code not in self.rooms:
            return
        
        for player_id, websocket in self.rooms[room_code].items():
            if player_id != exclude:
                try:
                    await websocket.send_json(message)
                except:
                    pass
    
    async def send_to_player(self, room_code: str, player_id: str, message: dict):
        """發送訊息給特定玩家"""
        if room_code in self.rooms and player_id in self.rooms[room_code]:
            try:
                await self.rooms[room_code][player_id].send_json(message)
            except:
                pass

manager = ConnectionManager()
```

### WebSocket Router

```python
# app/routers/websocket.py

from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.websocket.manager import manager

router = APIRouter()

@router.websocket("/ws/{room_code}/{player_id}")
async def websocket_endpoint(
    websocket: WebSocket,
    room_code: str,
    player_id: str
):
    await manager.connect(websocket, room_code, player_id)
    
    # 通知其他玩家
    await manager.broadcast_to_room(
        room_code,
        {"type": "player_joined", "player_id": player_id},
        exclude=player_id
    )
    
    try:
        while True:
            data = await websocket.receive_json()
            # 處理接收到的訊息
            await handle_message(room_code, player_id, data)
    except WebSocketDisconnect:
        manager.disconnect(room_code, player_id)
        await manager.broadcast_to_room(
            room_code,
            {"type": "player_left", "player_id": player_id}
        )

async def handle_message(room_code: str, player_id: str, data: dict):
    message_type = data.get("type")
    
    if message_type == "chat":
        await manager.broadcast_to_room(room_code, {
            "type": "chat",
            "player_id": player_id,
            "message": data.get("message")
        })
    elif message_type == "ping":
        await manager.send_to_player(room_code, player_id, {"type": "pong"})
```

### WebSocket 事件類型

| 事件 | 方向 | 說明 |
|------|------|------|
| `player_joined` | Server → Client | 玩家加入房間 |
| `player_left` | Server → Client | 玩家離開房間 |
| `role_assigned` | Server → Client | 角色分配完成 |
| `game_started` | Server → Client | 遊戲開始 |
| `vote_started` | Server → Client | 投票開始 |
| `vote_cast` | Client → Server | 投票 |
| `vote_ended` | Server → Client | 投票結束 |
| `chat` | 雙向 | 聊天訊息 |
| `ping/pong` | 雙向 | 心跳檢測 |


---

## 角色系統

### roles.json

```json
{
  "roles": [
    {
      "id": "george_iii",
      "name_zh": "喬治三世",
      "name_en": "George III",
      "faction": "crown",
      "description": "精神狀態不穩定的國王，在工業革命的浪潮中努力維護王室權威"
    },
    {
      "id": "worker",
      "name_zh": "工人",
      "name_en": "Worker",
      "faction": "labor",
      "description": "紡織工人湯瑪斯，面對機器取代人力的威脅"
    },
    {
      "id": "factory_owner",
      "name_zh": "工廠主",
      "name_en": "Factory Owner",
      "faction": "capital",
      "description": "理查·威爾森，追求利潤最大化的資本家"
    },
    {
      "id": "luddite",
      "name_zh": "盧德派",
      "name_en": "Luddite",
      "faction": "radical",
      "description": "機器破壞者喬治，以暴力手段反抗工業化"
    },
    {
      "id": "reformer",
      "name_zh": "改革者",
      "name_en": "Reformer",
      "faction": "reform",
      "description": "羅伯特·歐文，主張和平改革與勞工權益"
    },
    {
      "id": "mp",
      "name_zh": "議員",
      "name_en": "Member of Parliament",
      "faction": "parliament",
      "description": "威廉·菲茨傑拉德，在各方勢力間周旋的國會議員"
    }
  ]
}
```

---

## 開發指南

### 本地開發

```bash
cd shared/backend

# 建立虛擬環境
python -m venv venv
source venv/bin/activate  # macOS/Linux
# venv\Scripts\activate   # Windows

# 安裝依賴
pip install -r requirements.txt

# 設定環境變數
cp .env.example .env
# 編輯 .env 填入資料庫連線等資訊

# 執行資料庫遷移
alembic upgrade head

# 啟動開發伺服器
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### 資料庫遷移

```bash
# 建立新的遷移
alembic revision --autogenerate -m "Add player role fields"

# 執行遷移
alembic upgrade head

# 回滾
alembic downgrade -1
```

### 測試

```bash
# 執行所有測試
pytest

# 執行特定測試
pytest tests/test_nfc.py -v

# 顯示覆蓋率
pytest --cov=app
```

---

## Railway 部署

### railway.toml

```toml
[build]
builder = "dockerfile"
dockerfilePath = "Dockerfile"

[deploy]
startCommand = "uvicorn app.main:app --host 0.0.0.0 --port $PORT"
healthcheckPath = "/health"
healthcheckTimeout = 100
restartPolicyType = "on_failure"
restartPolicyMaxRetries = 3
```

### Dockerfile

```dockerfile
FROM python:3.11-slim

WORKDIR /app

# 安裝依賴
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 複製程式碼
COPY . .

# 執行遷移並啟動
CMD alembic upgrade head && uvicorn app.main:app --host 0.0.0.0 --port $PORT
```

### Railway 環境變數

在 Railway Dashboard 設定:

| 變數 | 說明 |
|------|------|
| `DATABASE_URL` | Railway PostgreSQL 自動提供 |
| `REDIS_URL` | Railway Redis 自動提供 |
| `SECRET_KEY` | 隨機產生的密鑰 |
| `ADMIN_KEY` | 管理員 API 密鑰 |
| `ENVIRONMENT` | `production` |


---

## 測試 API

### 使用 curl 測試

```bash
# 建立房間
curl -X POST https://1812-production.up.railway.app/api/rooms \
  -H "Content-Type: application/json" \
  -d '{"host_nickname": "TestHost"}'

# 加入房間
curl -X POST https://1812-production.up.railway.app/api/rooms/ABC123/join \
  -H "Content-Type: application/json" \
  -d '{"nickname": "TestPlayer"}'

# 取得房間資訊
curl https://1812-production.up.railway.app/api/rooms/ABC123

# NFC 掃描 (需要正確的 signature)
curl -X POST https://1812-production.up.railway.app/api/nfc/scan \
  -H "Content-Type: application/json" \
  -d '{
    "room_code": "ABC123",
    "player_id": "uuid-here",
    "card_id": "GEORGEIII01",
    "signature": "7f3a9c2b1e5d8f04"
  }'

# 取得所有角色
curl https://1812-production.up.railway.app/api/roles

# 管理員: 取得 NFC 卡片資料 (需要 admin key)
curl https://1812-production.up.railway.app/api/admin/nfc-cards \
  -H "X-Admin-Key: your-admin-key"
```

### WebSocket 測試 (使用 websocat)

```bash
# 安裝 websocat
brew install websocat  # macOS

# 連接 WebSocket
websocat wss://1812-production.up.railway.app/ws/ABC123/player-uuid

# 發送訊息
{"type": "chat", "message": "Hello!"}
```

---

## 已知問題 (待修復)

### 問題 1: NFC 卡片 hash 未同步

**現象**: 實體 NFC 卡片的 signature 與後端產生的不一致

**原因**: 
1. 可能使用不同的 SECRET_KEY
2. 卡片 ID 格式不一致 (大小寫、底線)

**解決方案**:
1. 從後端 `/api/admin/nfc-cards` 取得正確的 hash
2. 重新寫入 NFC 卡片

### 問題 2: 加入房間後回應格式

**現象**: 前端加入房間後顯示錯誤訊息

**需檢查**: 
- API 回應是否符合 `PlayerResponse` schema
- 是否有額外的 wrapper

---

## 管理員 API

### 取得 NFC 卡片資料

```python
# app/routers/admin.py

from fastapi import APIRouter, Depends, HTTPException, Header
from app.config import settings
from app.services.nfc_service import NFCService

router = APIRouter(prefix="/api/admin", tags=["Admin"])

def verify_admin_key(x_admin_key: str = Header(...)):
    if x_admin_key != settings.ADMIN_KEY:
        raise HTTPException(status_code=403, detail="Invalid admin key")
    return True

@router.get("/nfc-cards")
async def get_nfc_cards(admin: bool = Depends(verify_admin_key)):
    """取得所有 NFC 卡片的 card_id 和 signature"""
    nfc_service = NFCService(settings.SECRET_KEY)
    
    card_ids = [
        "WORKER01", "WORKER02", "WORKER03", "WORKER04",
        "FACTORY01", "FACTORY02", "FACTORY03", "FACTORY04",
        "LUDDITE01", "LUDDITE02", "LUDDITE03", "LUDDITE04",
        "REFORMER01", "REFORMER02", "REFORMER03", "REFORMER04",
        "MP01", "MP02", "MP03", "MP04",
        "GEORGEIII01", "GEORGEIII02", "GEORGEIII03", "GEORGEIII04",
    ]
    
    cards = []
    for card_id in card_ids:
        signature = nfc_service.generate_signature(card_id)
        nfc_url = f"parliament1812://role?id={card_id}&secret={signature}"
        cards.append({
            "card_id": card_id,
            "signature": signature,
            "nfc_url": nfc_url
        })
    
    return {"cards": cards}

@router.post("/rooms/{code}/assign-role")
async def manual_assign_role(
    code: str,
    player_id: str,
    role_type: str,
    role_index: int,
    admin: bool = Depends(verify_admin_key),
    db: AsyncSession = Depends(get_db)
):
    """手動分配角色 (測試用)"""
    # 實作手動分配邏輯
    pass
```

---

## 效能優化

### Redis 快取

```python
# app/services/cache_service.py

import redis.asyncio as redis
from app.config import settings

class CacheService:
    def __init__(self):
        self.redis = redis.from_url(settings.REDIS_URL)
    
    async def get_room(self, code: str) -> dict | None:
        data = await self.redis.get(f"room:{code}")
        return json.loads(data) if data else None
    
    async def set_room(self, code: str, room: dict, ttl: int = 3600):
        await self.redis.setex(f"room:{code}", ttl, json.dumps(room))
    
    async def invalidate_room(self, code: str):
        await self.redis.delete(f"room:{code}")
```

### 連線池配置

```python
# app/database.py

from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker

engine = create_async_engine(
    settings.DATABASE_URL,
    pool_size=20,
    max_overflow=10,
    pool_pre_ping=True,
    pool_recycle=300
)

async_session = sessionmaker(
    engine, class_=AsyncSession, expire_on_commit=False
)
```

---

## 參考資源

- [FastAPI 官方文檔](https://fastapi.tiangolo.com/)
- [SQLAlchemy 2.0](https://docs.sqlalchemy.org/en/20/)
- [Alembic 遷移](https://alembic.sqlalchemy.org/)
- [Railway 部署指南](https://docs.railway.app/)

---

*最後更新: 2024-12-20*
*框架: FastAPI 0.109 + SQLAlchemy 2.0 + PostgreSQL + Redis*
