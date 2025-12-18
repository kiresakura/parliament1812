"""
應用程式配置設定
使用 pydantic-settings 從環境變數載入配置
"""
from functools import lru_cache
from typing import Optional

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """應用程式設定"""
    
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
    )
    
    # 應用程式設定
    app_name: str = "Parliament 1812"
    app_version: str = "1.0.0"
    debug: bool = False
    
    # 資料庫設定
    database_url: str = "postgresql+asyncpg://postgres:password@localhost:5432/parliament1812"
    
    # Redis 設定
    redis_url: str = "redis://localhost:6379/0"
    
    # 安全性設定
    secret_key: str = "your-super-secret-key-change-in-production"
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 30
    
    # CORS 設定
    cors_origins: str = "*"
    
    # WebSocket 設定
    ws_heartbeat_interval: int = 30  # 心跳間隔（秒）
    
    # 遊戲設定
    max_players_per_room: int = 20
    room_code_length: int = 6
    
    @property
    def cors_origins_list(self) -> list[str]:
        """取得 CORS 允許的來源列表"""
        if self.cors_origins == "*":
            return ["*"]
        return [origin.strip() for origin in self.cors_origins.split(",")]


@lru_cache()
def get_settings() -> Settings:
    """取得設定實例（使用快取）"""
    return Settings()


settings = get_settings()
