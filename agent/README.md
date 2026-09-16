# JARVIS — Voice Agent (LiveKit + Gemini)

## What this is
The Python voice agent. One free Gemini API key runs the whole voice pipeline
(speech-to-speech, vision, and tool calling). LiveKit Cloud's free tier provides
the room the agent joins.

## Setup
```bash
cd agent
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
# edit .env with your keys:
#   GEMINI_API_KEY      -> free at https://aistudio.google.com/app/apikey
#   LIVEKIT_URL         -> wss://your-project.livekit.cloud
#   LIVEKIT_API_KEY     -> from https://cloud.livekit.io
#   LIVEKIT_API_SECRET  -> from https://cloud.livekit.io
```

## Run the token server (needed by the web + Android app)
```bash
uvicorn token_server:app --host 0.0.0.0 --port 8001
```

## Run the agent
```bash
python agent.py dev     # dev mode: joins a room when a participant arrives
python agent.py start   # production worker mode
```

Then open the frontend or the Android app, connect to the token server, and talk.

## Tools
- `get_weather(city)` — Open-Meteo, no key needed
- `search_web(query)` — DuckDuckGo, no key needed
- `browser_action(action, target)` — stub; hook to a local Playwright driver to go live
