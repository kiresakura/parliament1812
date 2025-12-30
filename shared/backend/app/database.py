"""
資料庫連線配置
使用 SQLAlchemy 2.0 async 模式
"""
from typing import AsyncGenerator

import redis.asyncio as redis
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.orm import DeclarativeBase

from app.config import settings


# 建立非同步資料庫引擎
engine = create_async_engine(
    settings.async_database_url,  # 使用自動轉換的 asyncpg URL
    echo=settings.debug,
    pool_pre_ping=True,
    pool_size=10,
    max_overflow=20,
)

# 建立非同步 session 工廠
async_session_maker = async_sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autocommit=False,
    autoflush=False,
)


class Base(DeclarativeBase):
    """SQLAlchemy 基礎模型類別"""
    pass


async def get_db() -> AsyncGenerator[AsyncSession, None]:
    """
    取得資料庫 session 的依賴注入函式
    
    Yields:
        AsyncSession: 非同步資料庫 session
    """
    async with async_session_maker() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()


async def init_db() -> None:
    """初始化資料庫（建立所有表格）"""
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)


async def seed_missions() -> None:
    """
    種子資料：填充秘密任務表
    會檢查並補充所有缺少的秘密任務資料
    """
    from app.data.missions import SECRET_MISSIONS
    from app.models.secret_mission import SecretMission
    from sqlalchemy import select

    async with async_session_maker() as session:
        try:
            # 取得所有現有任務的 ID
            result = await session.execute(select(SecretMission.id))
            existing_ids = set(row[0] for row in result.fetchall())

            # 找出缺少的任務
            missing_missions = {
                mid: mdata for mid, mdata in SECRET_MISSIONS.items()
                if mdata["id"] not in existing_ids
            }

            if not missing_missions:
                print(f"✅ 所有 {len(SECRET_MISSIONS)} 個秘密任務已存在", flush=True)
                return

            # 插入缺少的秘密任務
            print(f"📝 正在補充 {len(missing_missions)} 個缺少的秘密任務...", flush=True)
            for mission_id, mission_data in missing_missions.items():
                mission = SecretMission(
                    id=mission_data["id"],
                    role_type=mission_data["role_type"],
                    title=mission_data["title"],
                    description=mission_data["description"],
                    success_condition=mission_data.get("success_condition"),
                    points=mission_data.get("points", 50),
                )
                session.add(mission)
                print(f"  + {mission_data['id']}: {mission_data['title']}", flush=True)

            await session.commit()
            print(f"✅ 已成功補充 {len(missing_missions)} 個秘密任務", flush=True)

        except Exception as e:
            await session.rollback()
            print(f"❌ 填充秘密任務失敗: {e}", flush=True)
            raise


async def close_db() -> None:
    """關閉資料庫連線"""
    await engine.dispose()


# Redis 連線
class RedisManager:
    """Redis 連線管理器"""
    
    def __init__(self):
        self._redis: redis.Redis | None = None
    
    async def connect(self) -> None:
        """建立 Redis 連線"""
        self._redis = redis.from_url(
            settings.redis_url,
            encoding="utf-8",
            decode_responses=True,
        )
    
    async def disconnect(self) -> None:
        """關閉 Redis 連線"""
        if self._redis:
            await self._redis.close()
    
    @property
    def client(self) -> redis.Redis:
        """取得 Redis 客戶端"""
        if not self._redis:
            raise RuntimeError("Redis 尚未連線，請先呼叫 connect()")
        return self._redis
    
    async def publish(self, channel: str, message: str) -> None:
        """發布訊息到頻道"""
        await self.client.publish(channel, message)
    
    async def subscribe(self, channel: str):
        """訂閱頻道"""
        pubsub = self.client.pubsub()
        await pubsub.subscribe(channel)
        return pubsub


redis_manager = RedisManager()


async def get_redis() -> redis.Redis:
    """取得 Redis 客戶端的依賴注入函式"""
    return redis_manager.client
