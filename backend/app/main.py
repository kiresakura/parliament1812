"""
Parliament 1812 - 主程式入口

1812 國會風雲 - 角色扮演遊戲 API 伺服器
"""
from contextlib import asynccontextmanager
from typing import AsyncGenerator

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.database import init_db, close_db, redis_manager
from app.routers import rooms_router, players_router, admin_router, websocket_router, messages_router, votes_router, events_router
from app.websocket import manager as ws_manager


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator[None, None]:
    """
    應用程式生命週期管理
    
    啟動時：
    - 初始化資料庫
    - 連接 Redis
    - 啟動 WebSocket 管理器
    
    關閉時：
    - 關閉 WebSocket 管理器
    - 斷開 Redis 連線
    - 關閉資料庫連線
    """
    # 啟動
    print("🚀 啟動 Parliament 1812 伺服器...")
    
    # 初始化資料庫
    await init_db()
    print("✅ 資料庫連線成功")
    
    # 連接 Redis
    await redis_manager.connect()
    print("✅ Redis 連線成功")
    
    # 啟動 WebSocket 管理器
    await ws_manager.start()
    print("✅ WebSocket 管理器啟動")
    
    print(f"🎭 Parliament 1812 伺服器已就緒！")
    print(f"📍 API 文件：http://localhost:8000/docs")
    
    yield
    
    # 關閉
    print("\n🛑 正在關閉伺服器...")
    
    # 停止 WebSocket 管理器
    await ws_manager.stop()
    print("✅ WebSocket 管理器已停止")
    
    # 斷開 Redis
    await redis_manager.disconnect()
    print("✅ Redis 已斷開")
    
    # 關閉資料庫
    await close_db()
    print("✅ 資料庫已關閉")
    
    print("👋 伺服器已安全關閉")


# 建立 FastAPI 應用程式
app = FastAPI(
    title=settings.app_name,
    version=settings.app_version,
    description="""
## 1812 國會風雲 - 角色扮演遊戲 API

這是模擬 1812 年英國國會針對「機器問題」辯論的多人即時連線遊戲。

### 主要功能
- 🎴 NFC 卡片掃描選角色
- 🤫 每個玩家有秘密任務（只有自己看得到）
- 💬 玩家間可以私訊密謀
- ⚡ 主持人可以觸發突發事件
- 🗳️ 兩輪投票（第一輪匿名、第二輪記名）

### API 分類
- **Rooms**: 房間管理（建立、加入、設定）
- **Players**: 玩家管理（NFC 掃卡、角色分配）
- **Messages**: 私訊系統
- **Votes**: 投票系統
- **WebSocket**: 即時同步
    """,
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan,
)

# 設定 CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 註冊路由
app.include_router(rooms_router)
app.include_router(players_router)
app.include_router(admin_router)
app.include_router(websocket_router)
app.include_router(messages_router)
app.include_router(votes_router)
app.include_router(events_router)


@app.get("/", tags=["root"])
async def root() -> dict:
    """
    根路徑 - 健康檢查
    
    Returns:
        應用程式資訊
    """
    return {
        "name": settings.app_name,
        "version": settings.app_version,
        "status": "running",
        "message": "歡迎來到 1812 國會風雲！",
    }


@app.get("/health", tags=["root"])
async def health_check() -> dict:
    """
    健康檢查端點
    
    Returns:
        健康狀態資訊
    """
    return {
        "status": "healthy",
        "database": "connected",
        "redis": "connected",
    }
