# JARVIS Android App

Portrait-first LiveKit client for the JARVIS voice agent.

## Screens
- **Home** — status line, chat transcript, three big round buttons:
  mic (talk), camera (vision), connect/disconnect.
- **Settings** (gear icon) — token server URL + room name, saved on device.

## How it connects
1. The app GETs `http://<your-host>:8001/token?room=jarvis-room` from the token
   server (see `../agent/token_server.py`) for a LiveKit access token.
2. It joins the LiveKit room; the Python agent joins automatically and starts talking.
3. Mic audio streams to the agent; the agent's audio plays on the phone speaker.
4. Camera toggle publishes phone video so JARVIS can see.

## Build (needs Flutter SDK + Android SDK)
```bash
cd mobile
flutter pub get
flutter build apk --debug   # -> build/app/outputs/flutter-apk/app-debug.apk
```
Install the APK on the phone (allow "install unknown apps" once), open it,
enter the token server URL in Settings, tap the mic.

## Notes
- The phone and the machine running the token server + agent must reach each
  other (same Wi-Fi, or a public URL for the token server and LiveKit Cloud).
- Uses a debug keystore — fine for sideloading, not for the Play Store.
