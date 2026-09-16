JARVIS / LiveKit Voice Agent - Build Package
=============================================
Built for Galandous Brooker (KJ4QPR). LiveKit + Gemini voice agent with
camera vision, search/weather/browser tools, web frontend, and Flutter Android app.

CONTENTS
- agent/      Python LiveKit voice agent (agent.py, tools.py, token_server.py, prompts.py)
- frontend/   Web frontend (index.html, app.js, styles.css)
- mobile/     Flutter Android app (portrait-first phone UI)

WHAT YOU NEED ON YOUR MACHINE
- Python 3.10+ and: pip install -r agent/requirements.txt
- Flutter SDK (stable) + Android Studio with Android SDK
- Your own LiveKit Cloud project credentials and Google Gemini API key
  (set as environment variables - see agent/README.md; never commit real keys)

BUILD THE APK
  cd mobile
  flutter pub get
  flutter build apk --release
  (APK lands in mobile/build/app/outputs/flutter-apk/)

RUN THE VOICE AGENT
  cd agent
  python token_server.py   # in one terminal
  python agent.py          # in another terminal

NOTE: android/local.properties and gradle.properties may contain machine-specific
paths - update ANDROID_HOME / sdk.dir for your machine if needed.
