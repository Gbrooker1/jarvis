"""Tiny token server for the web frontend and the mobile app.

GET /token?room=<name>&identity=<name>  ->  {"token": "<livekit jwt>"}

Run:  uvicorn token_server:app --host 0.0.0.0 --port 8001

Needs LIVEKIT_URL, LIVEKIT_API_KEY, LIVEKIT_API_SECRET in the environment.
"""
import os

from dotenv import load_dotenv
from fastapi import FastAPI, Query
from livekit import api

load_dotenv()

app = FastAPI(title="JARVIS token server")


@app.get("/token")
async def mint_token(
    room: str = Query(default="jarvis-room"),
    identity: str = Query(default="g-phone"),
):
    token = (
        api.AccessToken(os.environ["LIVEKIT_API_KEY"], os.environ["LIVEKIT_API_SECRET"])
        .with_identity(identity)
        .with_name(identity)
        .with_grants(
            api.VideoGrants(
                room_join=True,
                room=room,
                can_publish=True,
                can_subscribe=True,
                can_publish_data=True,
            )
        )
    )
    return {"token": token.to_jwt(), "url": os.environ["LIVEKIT_URL"], "room": room}


@app.get("/health")
async def health():
    return {"ok": True}
