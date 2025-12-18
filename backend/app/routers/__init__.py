"""API 路由模組"""
from app.routers.rooms import router as rooms_router
from app.routers.players import router as players_router
from app.routers.admin import router as admin_router
from app.routers.websocket import router as websocket_router
from app.routers.messages import router as messages_router
from app.routers.votes import router as votes_router
from app.routers.events import router as events_router

__all__ = [
    "rooms_router",
    "players_router",
    "admin_router",
    "websocket_router",
    "messages_router",
    "votes_router",
    "events_router",
]
