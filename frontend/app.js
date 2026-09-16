import { Room, RoomEvent, Track } from "https://esm.sh/livekit-client@2";

const $ = (id) => document.getElementById(id);
const statusEl = $("status"), transcriptEl = $("transcript");
const micBtn = $("mic-btn"), camBtn = $("camera-btn"), connBtn = $("connect-btn");
const wave = $("waveform"), wctx = wave.getContext("2d");

let room = null, micOn = false, camOn = false, analyser = null, audioCtx = null;
let tokenServer = localStorage.getItem("jarvis_token_server") || "";
$("token-url").value = tokenServer;

$("save-settings").onclick = () => {
  tokenServer = $("token-url").value.trim();
  localStorage.setItem("jarvis_token_server", tokenServer);
  addMsg("jarvis", "Settings saved.");
};

function setStatus(s) { statusEl.textContent = s; }

function addMsg(who, text) {
  const div = document.createElement("div");
  div.className = "msg " + who;
  const label = document.createElement("span");
  label.className = "who";
  label.textContent = who === "user" ? "You" : "JARVIS";
  div.appendChild(label);
  div.appendChild(document.createTextNode(text));
  transcriptEl.appendChild(div);
  transcriptEl.scrollTop = transcriptEl.scrollHeight;
}

function drawWave() {
  requestAnimationFrame(drawWave);
  wctx.clearRect(0, 0, wave.width, wave.height);
  wctx.strokeStyle = "#29b6f6";
  wctx.lineWidth = 3;
  wctx.beginPath();
  const mid = wave.height / 2;
  if (analyser) {
    const data = new Uint8Array(analyser.fftSize);
    analyser.getByteTimeDomainData(data);
    const step = wave.width / data.length;
    for (let i = 0; i < data.length; i++) {
      const y = mid + ((data[i] - 128) / 128) * mid * 0.9;
      i === 0 ? wctx.moveTo(0, y) : wctx.lineTo(i * step, y);
    }
  } else {
    wctx.moveTo(0, mid);
    wctx.lineTo(wave.width, mid);
  }
  wctx.stroke();
}
drawWave();

async function connect() {
  if (room) { await disconnect(); return; }
  if (!tokenServer) { addMsg("jarvis", "Set the token server URL first."); return; }
  const roomName = $("room-name").value.trim() || "jarvis-room";
  setStatus("connecting...");
  try {
    const res = await fetch(`${tokenServer.replace(/\/$/, "")}/token?room=${encodeURIComponent(roomName)}`);
    const { token, url } = await res.json();
    room = new Room({ adaptiveStream: true, dynacast: true });

    room.on(RoomEvent.TrackSubscribed, (track) => {
      if (track.kind === Track.Kind.Audio) {
        const el = track.attach();
        document.body.appendChild(el);
        hookVisualizer(el);
      } else if (track.kind === Track.Kind.Video) {
        track.attach($("remote-video"));
      }
    });
    room.on(RoomEvent.TrackUnsubscribed, (track) => track.detach().forEach((el) => el.remove()));
    room.on(RoomEvent.Disconnected, () => { room = null; setStatus("offline"); connBtn.textContent = "🔌"; });

    // Live captions of the agent's speech come through as transcription segments
    room.on(RoomEvent.TranscriptionReceived, (segments) => {
      for (const seg of segments) {
        if (seg.final) addMsg(seg.participantIdentity === room.localParticipant.identity ? "user" : "jarvis", seg.text);
      }
    });

    await room.connect(url, token);
    setStatus("connected — tap the mic");
    connBtn.textContent = "⏻";
    addMsg("jarvis", "Connected. Tap the mic to talk.");
  } catch (e) {
    console.error(e);
    setStatus("connection failed");
    addMsg("jarvis", "Could not connect: " + e.message);
    room = null;
  }
}

async function disconnect() {
  if (room) { await room.disconnect(); room = null; }
  micOn = false; camOn = false;
  micBtn.classList.remove("live");
  setStatus("offline");
  connBtn.textContent = "🔌";
}

function hookVisualizer(mediaEl) {
  try {
    audioCtx = audioCtx || new (window.AudioContext || window.webkitAudioContext)();
    const src = audioCtx.createMediaElementSource(mediaEl);
    analyser = audioCtx.createAnalyser();
    analyser.fftSize = 512;
    src.connect(analyser);
    analyser.connect(audioCtx.destination);
  } catch (e) { console.warn("visualizer unavailable", e); }
}

micBtn.onclick = async () => {
  if (!room) { await connect(); }
  if (!room) return;
  micOn = !micOn;
  await room.localParticipant.setMicrophoneEnabled(micOn);
  micBtn.classList.toggle("live", micOn);
  setStatus(micOn ? "listening..." : "connected — tap the mic");
};

camBtn.onclick = async () => {
  if (!room) { await connect(); }
  if (!room) return;
  camOn = !camOn;
  await room.localParticipant.setCameraEnabled(camOn);
  if (camOn) {
    const pub = [...room.localParticipant.videoTrackPublications.values()][0];
    if (pub?.videoTrack) pub.videoTrack.attach($("local-video"));
  } else {
    $("local-video").srcObject = null;
  }
  addMsg("jarvis", camOn ? "Camera on — I can see you now." : "Camera off.");
};

connBtn.onclick = connect;
