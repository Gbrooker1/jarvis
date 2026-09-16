"""JARVIS voice agent — LiveKit worker using Gemini's realtime speech model.

One API key runs the whole voice pipeline (speech-to-speech, native audio,
vision, and function calling): GEMINI_API_KEY.

LiveKit Cloud free tier provides the room the agent joins:
LIVEKIT_URL, LIVEKIT_API_KEY, LIVEKIT_API_SECRET.

Run:  python agent.py dev     (dev mode, joins a room on demand)
      python agent.py start   (production worker)
"""
import logging
import os
from datetime import datetime

from dotenv import load_dotenv

from livekit import agents
from livekit.agents import Agent, AgentSession, RoomInputOptions
from livekit.plugins import google, noise_cancellation

from prompts import AGENT_INSTRUCTION, SESSION_INSTRUCTION
from tools import browser_action, get_weather, search_web

load_dotenv()
logging.basicConfig(level=logging.INFO)


class Jarvis(Agent):
    def __init__(self) -> None:
        super().__init__(
            instructions=AGENT_INSTRUCTION,
            llm=google.realtime.RealtimeModel(
                # Gemini native-audio voice. Other options:
                # "Puck", "Charon", "Kore", "Fenrir", "Aoede", "Leda", "Orus", "Zephyr"
                voice="Charon",
            ),
            tools=[get_weather, search_web, browser_action],
        )


async def entrypoint(ctx: agents.JobContext):
    session = AgentSession()

    await session.start(
        room=ctx.room,
        agent=Jarvis(),
        room_input_options=RoomInputOptions(
            video_enabled=True,  # camera vision through Gemini multimodal input
            noise_cancellation=noise_cancellation.BVC(),
        ),
    )

    await ctx.connect()

    today = datetime.now().strftime("%A, %B %d, %Y")
    await session.generate_reply(
        instructions=f"{SESSION_INSTRUCTION}\nToday is {today}.",
    )


if __name__ == "__main__":
    agents.cli.run_app(agents.WorkerOptions(entrypoint_fnc=entrypoint))
