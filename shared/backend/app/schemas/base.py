"""基礎 Schema 類別"""
from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict


class BaseSchema(BaseModel):
    """基礎 Schema，所有 Schema 繼承此類別"""
    
    model_config = ConfigDict(
        from_attributes=True,
        populate_by_name=True,
    )


class TimestampMixin(BaseModel):
    """時間戳記混入類別"""
    created_at: datetime | None = None
