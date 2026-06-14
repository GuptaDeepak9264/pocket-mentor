from fastapi import APIRouter
from app.api.v1 import auth, topics, cards, feeds, uploads, progress, sync

api_router = APIRouter(prefix="/api/v1")

api_router.include_router(auth.router)
api_router.include_router(topics.router)
api_router.include_router(cards.router)
api_router.include_router(feeds.router)
api_router.include_router(uploads.router)
api_router.include_router(progress.router)
api_router.include_router(sync.router)
