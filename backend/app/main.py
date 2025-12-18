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
    import traceback

    # 啟動
    print("🚀 啟動 Parliament 1812 伺服器...", flush=True)

    db_connected = False
    redis_connected = False
    ws_started = False

    # 初始化資料庫
    try:
        print(f"📊 正在連線資料庫...", flush=True)
        await init_db()
        db_connected = True
        print("✅ 資料庫連線成功", flush=True)
    except Exception as e:
        print(f"❌ 資料庫連線失敗: {e}", flush=True)
        print(traceback.format_exc(), flush=True)

    # 連接 Redis
    try:
        print(f"📮 正在連線 Redis...", flush=True)
        await redis_manager.connect()
        redis_connected = True
        print("✅ Redis 連線成功", flush=True)
    except Exception as e:
        print(f"❌ Redis 連線失敗: {e}", flush=True)
        print(traceback.format_exc(), flush=True)

    # 啟動 WebSocket 管理器 (需要 Redis 已連線)
    if redis_connected:
        try:
            print(f"🔌 正在啟動 WebSocket 管理器...", flush=True)
            await ws_manager.start()
            ws_started = True
            print("✅ WebSocket 管理器啟動", flush=True)
        except Exception as e:
            print(f"❌ WebSocket 管理器啟動失敗: {e}", flush=True)
            print(traceback.format_exc(), flush=True)
    else:
        print("⚠️ 跳過 WebSocket 管理器啟動 (Redis 未連線)", flush=True)

    print(f"🎭 Parliament 1812 伺服器已就緒！", flush=True)
    print(f"📍 狀態: DB={db_connected}, Redis={redis_connected}, WS={ws_started}", flush=True)

    yield

    # 關閉
    print("\n🛑 正在關閉伺服器...", flush=True)

    # 停止 WebSocket 管理器
    if ws_started:
        try:
            await ws_manager.stop()
            print("✅ WebSocket 管理器已停止", flush=True)
        except Exception as e:
            print(f"⚠️ WebSocket 管理器停止失敗: {e}", flush=True)

    # 斷開 Redis
    if redis_connected:
        try:
            await redis_manager.disconnect()
            print("✅ Redis 已斷開", flush=True)
        except Exception as e:
            print(f"⚠️ Redis 斷開失敗: {e}", flush=True)

    # 關閉資料庫
    if db_connected:
        try:
            await close_db()
            print("✅ 資料庫已關閉", flush=True)
        except Exception as e:
            print(f"⚠️ 資料庫關閉失敗: {e}", flush=True)

    print("👋 伺服器已安全關閉", flush=True)


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
    # 簡單檢查 - 只要伺服器能回應就是健康的
    # 詳細的連線狀態會在 /status 端點
    return {
        "status": "healthy",
        "version": settings.app_version,
    }


@app.get("/status", tags=["root"])
async def detailed_status() -> dict:
    """
    詳細狀態檢查端點

    Returns:
        詳細服務狀態
    """
    db_status = "unknown"
    redis_status = "unknown"

    # 檢查資料庫
    try:
        from sqlalchemy import text
        from app.database import async_session_maker
        async with async_session_maker() as session:
            await session.execute(text("SELECT 1"))
        db_status = "connected"
    except Exception as e:
        db_status = f"error: {str(e)}"

    # 檢查 Redis
    try:
        await redis_manager.client.ping()
        redis_status = "connected"
    except Exception as e:
        redis_status = f"error: {str(e)}"

    return {
        "status": "running",
        "version": settings.app_version,
        "database": db_status,
        "redis": redis_status,
    }
