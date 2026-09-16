import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:livekit_client/livekit_client.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const JarvisApp());
}

class JarvisApp extends StatelessWidget {
  const JarvisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JARVIS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: const Color(0xFF05070D),
        colorScheme: const ColorScheme.dark(primary: Color(0xFF29B6F6)),
      ),
      home: const JarvisHome(),
    );
  }
}

class ChatMsg {
  final String who; // 'you' or 'jarvis'
  final String text;
  ChatMsg(this.who, this.text);
}

class JarvisHome extends StatefulWidget {
  const JarvisHome({super.key});
  @override
  State<JarvisHome> createState() => _JarvisHomeState();
}

class _JarvisHomeState extends State<JarvisHome> {
  Room? _room;
  bool _connected = false;
  bool _micOn = false;
  bool _camOn = false;
  String _status = 'offline';
  final List<ChatMsg> _msgs = [];
  final _scroll = ScrollController();
  String _tokenServer = '';
  String _roomName = 'jarvis-room';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _tokenServer = prefs.getString('token_server') ?? '';
      _roomName = prefs.getString('room_name') ?? 'jarvis-room';
    });
  }

  void _addMsg(String who, String text) {
    setState(() => _msgs.add(ChatMsg(who, text)));
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => _scroll.jumpTo(_scroll.position.maxScrollExtent));
  }

  Future<void> _connect() async {
    if (_tokenServer.isEmpty) {
      _openSettings();
      return;
    }
    setState(() => _status = 'connecting...');
    try {
      final res = await http.get(Uri.parse(
          '${_tokenServer.replaceAll(RegExp(r"/$"), "")}/token?room=$_roomName&identity=g-phone'));
      final data = jsonDecode(res.body);
      final token = data['token'] as String;
      final url = data['url'] as String;

      await [Permission.microphone, Permission.camera].request();

      final room = Room();
      final listener = room.createListener();

      listener.on<RoomDisconnectedEvent>((_) {
        setState(() {
          _connected = false;
          _micOn = false;
          _camOn = false;
          _status = 'offline';
          _room = null;
        });
      });

      listener.on<TrackSubscribedEvent>((e) {
        if (e.track is AudioTrack) {
          // audio plays automatically on device speaker
        }
      });

      listener.on<TranscriptionEvent>((e) {
        final isLocal = e.participant.identity == room.localParticipant?.identity;
        for (final seg in e.segments) {
          if (seg.isFinal) {
            _addMsg(isLocal ? 'you' : 'jarvis', seg.text);
          }
        }
      });

      await room.connect(url, token);
      setState(() {
        _room = room;
        _connected = true;
        _status = 'connected — tap the mic';
      });
      _addMsg('jarvis', 'Connected. Tap the mic to talk.');
    } catch (e) {
      setState(() => _status = 'connection failed');
      _addMsg('jarvis', 'Could not connect: $e');
    }
  }

  Future<void> _disconnect() async {
    await _room?.disconnect();
    setState(() {
      _room = null;
      _connected = false;
      _micOn = false;
      _camOn = false;
      _status = 'offline';
    });
  }

  Future<void> _toggleMic() async {
    if (!_connected) {
      await _connect();
      if (!_connected) return;
    }
    final on = !_micOn;
    await _room!.localParticipant?.setMicrophoneEnabled(on);
    setState(() {
      _micOn = on;
      _status = on ? 'listening...' : 'connected — tap the mic';
    });
  }

  Future<void> _toggleCam() async {
    if (!_connected) {
      await _connect();
      if (!_connected) return;
    }
    final on = !_camOn;
    await _room!.localParticipant?.setCameraEnabled(on);
    setState(() {
      _camOn = on;
    });
    _addMsg('jarvis', on ? 'Camera on — I can see you now.' : 'Camera off.');
  }

  void _openSettings() {
    final serverCtrl = TextEditingController(text: _tokenServer);
    final roomCtrl = TextEditingController(text: _roomName);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Connection', style: TextStyle(fontSize: 20)),
            const SizedBox(height: 12),
            TextField(
              controller: serverCtrl,
              decoration: const InputDecoration(
                  labelText: 'Token server URL (http://host:8001)',
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: roomCtrl,
              decoration: const InputDecoration(
                  labelText: 'Room name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('token_server', serverCtrl.text.trim());
                  await prefs.setString('room_name', roomCtrl.text.trim());
                  setState(() {
                    _tokenServer = serverCtrl.text.trim();
                    _roomName = roomCtrl.text.trim();
                  });
                  if (mounted) Navigator.pop(ctx);
                },
                child: const Text('Save', style: TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('J A R V I S'),
        centerTitle: true,
        actions: [
          IconButton(
              icon: const Icon(Icons.settings, size: 30),
              onPressed: _openSettings),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(_status,
                  style: const TextStyle(color: Colors.grey, fontSize: 14)),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _msgs.length,
                itemBuilder: (ctx, i) {
                  final m = _msgs[i];
                  final isYou = m.who == 'you';
                  return Align(
                    alignment:
                        isYou ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(14),
                      constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(ctx).size.width * 0.85),
                      decoration: BoxDecoration(
                        color: isYou
                            ? const Color(0xFF12325A)
                            : const Color(0xFF0E2237),
                        borderRadius: BorderRadius.circular(16),
                        border: isYou
                            ? null
                            : Border.all(
                                color: const Color(0xFF29B6F6).withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(isYou ? 'You' : 'JARVIS',
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey)),
                          const SizedBox(height: 2),
                          Text(m.text, style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _bigButton(Icons.videocam, _camOn, _toggleCam),
                  const SizedBox(width: 32),
                  _bigButton(
                      _micOn ? Icons.mic : Icons.mic_none, _micOn, _toggleMic,
                      big: true),
                  const SizedBox(width: 32),
                  _bigButton(
                      _connected ? Icons.power_settings_new : Icons.link,
                      _connected,
                      _connected ? _disconnect : _connect),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bigButton(IconData icon, bool active, VoidCallback onTap,
      {bool big = false}) {
    final size = big ? 110.0 : 72.0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? const Color(0xFF1B5E8A) : const Color(0xFF0B1220),
          border: Border.all(
              color: const Color(0xFF29B6F6).withValues(alpha: 0.4), width: 2),
          boxShadow: active
              ? [
                  BoxShadow(
                      color: const Color(0xFF29B6F6).withValues(alpha: 0.4),
                      blurRadius: 24)
                ]
              : null,
        ),
        child: Icon(icon, size: big ? 48 : 30, color: Colors.white),
      ),
    );
  }
}
