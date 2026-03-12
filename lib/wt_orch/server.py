"""FastAPI application factory for the wt-web dashboard.

Creates the app with CORS, lifespan management (watcher start/stop),
API routes, WebSocket endpoints, and static SPA file serving.
"""

from __future__ import annotations

import os
from contextlib import asynccontextmanager
from pathlib import Path

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from .api import router as api_router
from .watcher import WatcherManager
from .websocket import router as ws_router, connection_manager


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Start file watchers on startup, stop on shutdown."""
    watcher = app.state.watcher_manager
    await watcher.start(connection_manager)
    yield
    await watcher.stop()


def create_app(web_dist_dir: str | None = None) -> FastAPI:
    """Create and configure the FastAPI application.

    Args:
        web_dist_dir: Path to the built SPA directory (web/dist/).
                      If None, tries to find it relative to the package.
    """
    app = FastAPI(
        title="wt-tools Web Dashboard",
        version="0.1.0",
        lifespan=lifespan,
    )

    # CORS for dev (Vite dev server on different port)
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_methods=["*"],
        allow_headers=["*"],
    )

    # State
    app.state.watcher_manager = WatcherManager()

    # API and WebSocket routes
    app.include_router(api_router)
    app.include_router(ws_router)

    # Static SPA serving — must be last (catch-all)
    if web_dist_dir is None:
        # Try relative to this file: lib/wt_orch/../../web/dist
        candidate = Path(__file__).resolve().parent.parent.parent / "web" / "dist"
        if candidate.is_dir():
            web_dist_dir = str(candidate)

    if web_dist_dir and Path(web_dist_dir).is_dir():
        app.mount("/", StaticFiles(directory=web_dist_dir, html=True), name="spa")

    return app
