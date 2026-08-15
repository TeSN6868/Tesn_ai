import 'dart:async';
import 'dart:convert';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:http/http.dart' as http;

class M8CallService {
  static const apiBase = 'https://m8-messenger-api.coolalaga686.workers.dev';

  RTCPeerConnection? peer;
  MediaStream? localStream;

  String? callId;
  String? myPin;

  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  Timer? _signalTimer;
  int _lastSignalId = 0;

  // ICE candidate yang datang sebelum remote description siap
  final List<RTCIceCandidate> _pendingIceCandidates = [];
  bool _remoteDescriptionSet = false;

  bool audioEnabled = true;
  bool videoEnabled = true;

  // Mencegah polling/signaling tetap berjalan saat panggilan sedang diakhiri.
  bool _isEnding = false;

  // Status panggilan untuk UI M8.
  // connecting -> ringing -> connected -> ended/failed/rejected
  String callStatus = 'connecting';
  void Function(String status)? onCallStatusChanged;

  void _setCallStatus(String status) {
    callStatus = status;
    onCallStatusChanged?.call(status);
    print('[M8 CALL STATUS] $status');
  }

  Future<void> initializeRenderers() async {
    await localRenderer.initialize();
    await remoteRenderer.initialize();
  }

  Future<List<Map<String, dynamic>>> getIncomingCalls(String pin) async {
    if (pin.trim().isEmpty) return <Map<String, dynamic>>[];

    try {
      final response = await http.get(
        Uri.parse(
          '$apiBase/api/calls/incoming'
          '?m8_pin=${Uri.encodeComponent(pin.trim())}',
        ),
      );

      if (response.statusCode != 200) return <Map<String, dynamic>>[];

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (data['success'] != true) return <Map<String, dynamic>>[];

      final calls = data['calls'];

      if (calls is! List) return <Map<String, dynamic>>[];

      return calls
          .whereType<Map>()
          .map<Map<String, dynamic>>((item) => Map<String, dynamic>.from(item))
          .toList();
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  Future<void> startCall({
    required String callerPin,
    required String calleePin,
    bool videoCall = false,
  }) async {
    myPin = callerPin;
    _isEnding = false;

    try {
      final response = await http.post(
        Uri.parse('$apiBase/api/calls'),
        headers: <String, String>{'Content-Type': 'application/json'},
        body: jsonEncode({
            'caller_pin': callerPin,
            'callee_pin': calleePin,
            'call_type': videoCall ? 'video' : 'voice',
          }),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (data['success'] != true) {
        throw Exception(data['error'] ?? 'Gagal memulai panggilan');
      }

      callId = data['call_id'].toString();

      // Sesi panggilan sudah dibuat di server.
      _setCallStatus('ringing');

      await _createPeer(videoCall: videoCall);

      final offer = await peer!.createOffer(<String, dynamic>{
        'offerToReceiveAudio': 1,
        'offerToReceiveVideo': 1,
      });

      await peer!.setLocalDescription(offer);

      await _sendSignal('offer', <String, dynamic>{
        'type': offer.type,
        'sdp': offer.sdp,
      });
      _startSignalPolling();
    } catch (e) {
      try {
        if (callId != null && myPin != null) {
          await http.post(
            Uri.parse('$apiBase/api/calls/end'),
            headers: <String, String>{'Content-Type': 'application/json'},
            body: jsonEncode({'call_id': callId, 'm8_pin': myPin}),
          );
        }
      } catch (_) {}

      _signalTimer?.cancel();

      for (final track in localStream?.getTracks() ?? []) {
        track.stop();
      }

      await localStream?.dispose();
      await peer?.close();

      localRenderer.srcObject = null;
      remoteRenderer.srcObject = null;

      localStream = null;
      peer = null;
      callId = null;
      myPin = null;
      _signalTimer = null;
      _lastSignalId = 0;

      throw Exception('Panggilan gagal: $e');
    }
  }

  Future<void> acceptCall({
    required String incomingCallId,
    required String calleePin,
    bool videoCall = false,
  }) async {
    callId = incomingCallId;
    myPin = calleePin;
    _isEnding = false;

    final response = await http.post(
      Uri.parse('$apiBase/api/calls/accept'),
      headers: <String, String>{'Content-Type': 'application/json'},
      body: jsonEncode({'call_id': callId, 'm8_pin': calleePin}),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (data['success'] != true) {
      throw Exception(data['error'] ?? 'Gagal menerima panggilan');
    }

    await _createPeer(videoCall: videoCall);
    _setCallStatus('connecting');
    _startSignalPolling();
  }

  Future<void> rejectCall({
    required String incomingCallId,
    required String calleePin,
  }) async {
    _setCallStatus('rejected');

    await http.post(
      Uri.parse('$apiBase/api/calls/reject'),
      headers: <String, String>{'Content-Type': 'application/json'},
      body: jsonEncode({'call_id': incomingCallId, 'm8_pin': calleePin}),
    );
  }

  Future<void> _createPeer({bool videoCall = false}) async {
    _pendingIceCandidates.clear();
    _remoteDescriptionSet = false;

    peer = await createPeerConnection(<String, dynamic>{
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        {'urls': 'stun:stun1.l.google.com:19302'},
      ],
    });

    peer!.onIceCandidate = (candidate) async {
      if (candidate.candidate == null) return;

      await _sendSignal('ice', <String, dynamic>{
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
      });
    };

    peer!.onIceConnectionState = (state) {
      print("[M8 WEBRTC] ICE CONNECTION STATE: $state");

      final value = state.toString().toLowerCase();

      if (value.contains('connected') || value.contains('completed')) {
        _setCallStatus('connected');
      } else if (value.contains('failed')) {
        print("[M8 WEBRTC] ICE FAILED");
        _setCallStatus('failed');
      } else if (value.contains('checking')) {
        print("[M8 WEBRTC] ICE CHECKING");
      } else if (value.contains('disconnected')) {
        // WebRTC mobile bisa sementara disconnected.
        // Jangan langsung mengakhiri panggilan.
        print("[M8 WEBRTC] ICE TEMPORARILY DISCONNECTED");
      }
    };

    peer!.onConnectionState = (state) {
      print("[M8 WEBRTC] PEER CONNECTION STATE: $state");

      final value = state.toString().toLowerCase();

      if (value.contains('connected')) {
        _setCallStatus('connected');
      } else if (value.contains('failed')) {
        print("[M8 WEBRTC] PEER CONNECTION FAILED");
        _setCallStatus('failed');
      } else if (value.contains('closed')) {
        _setCallStatus('ended');
      } else if (value.contains('disconnected')) {
        // Jangan mengakhiri panggilan hanya karena transient disconnect.
        print("[M8 WEBRTC] PEER TEMPORARILY DISCONNECTED");
      }
    };

    peer!.onIceGatheringState = (state) {
      print("[M8 WEBRTC] ICE GATHERING STATE: $state");
    };

    peer!.onSignalingState = (state) {
      print("[M8 WEBRTC] SIGNALING STATE: $state");
    };

    peer!.onTrack = (event) {
      print(
        '[M8 WEBRTC] REMOTE TRACK: '
        'kind=${event.track.kind}, '
        'streams=${event.streams.length}',
      );

      if (event.streams.isNotEmpty) {
        remoteRenderer.srcObject = event.streams.first;
        print('[M8 WEBRTC] REMOTE STREAM DITERIMA');
      }
    };

    try {
      localStream = await navigator.mediaDevices.getUserMedia(<String, dynamic>{
        'audio': <String, dynamic>{
  'echoCancellation': true,
  'noiseSuppression': true,
  'autoGainControl': true,
  'googEchoCancellation': true,
  'googNoiseSuppression': true,
  'googAutoGainControl': true,
  'googHighpassFilter': true,
  'channelCount': 1,
},
        'video': videoCall
            ? {
                'facingMode': 'user',
                'width': {'ideal': 1280},
                'height': {'ideal': 720},
              }
            : false,
      });
    } catch (e) {
      print('[M8 VCALL] CAMERA/MIC ERROR: $e');
      throw Exception('Kamera atau mikrofon gagal dibuka: $e');
    }

    localRenderer.srcObject = localStream;

    // Kamera depan langsung aktif saat panggilan dimulai.
    for (final track in localStream!.getVideoTracks()) {
      track.enabled = true;
    }

    for (final track in localStream!.getAudioTracks()) {
      track.enabled = true;
    }

    for (final track in localStream!.getTracks()) {
      await peer!.addTrack(track, localStream!);
    }
  }

  Future<void> _sendSignal(String type, Map<String, dynamic> payload) async {
    final currentCallId = callId;
    final currentPin = myPin;

    if (currentCallId == null || currentPin == null) return;

    try {
      final response = await http.post(
        Uri.parse('$apiBase/api/calls/signal'),
        headers: <String, String>{'Content-Type': 'application/json'},
        body: jsonEncode({
          'call_id': currentCallId,
          'sender_pin': currentPin,
          'type': type,
          'payload': payload,
        }),
      );

      print(
        '[M8 WEBRTC] SEND SIGNAL '
        'type=$type status=${response.statusCode}',
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        print(
          '[M8 WEBRTC] SIGNAL ERROR '
          'type=$type status=${response.statusCode} '
          'body=${response.body}',
        );
        throw Exception(
          'Signaling $type gagal: HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      print('[M8 WEBRTC] SIGNAL POST ERROR: $e');
    }
  }

  Future<void> _handleSignal(Map<String, dynamic> signal) async {
    final type = signal['type'];
    final payload = Map<String, dynamic>.from(signal['payload'] ?? {});

    print(
      '[M8 WEBRTC] HANDLE SIGNAL '
      'type=$type id=${signal['id']} sender=${signal['sender_pin']}',
    );

    if (type == 'offer') {
      final sdp = payload['sdp'];
      final offerType = payload['type'];

      print(
        '[M8 WEBRTC] OFFER RECEIVED '
        'type=$offerType sdp=${sdp != null ? 'OK' : 'NULL'}',
      );

      if (sdp == null) return;

      await peer!.setRemoteDescription(RTCSessionDescription(sdp, offerType));

      _remoteDescriptionSet = true;

      // Masukkan candidate yang sudah datang lebih dulu.
      for (final candidate in List<RTCIceCandidate>.from(
        _pendingIceCandidates,
      )) {
        try {
          await peer!.addCandidate(candidate);
        } catch (e) {
          print('[M8 WEBRTC] queued ICE error: $e');
        }
      }
      _pendingIceCandidates.clear();

      final answer = await peer!.createAnswer(<String, dynamic>{
        'offerToReceiveAudio': 1,
        'offerToReceiveVideo': 1,
      });

      await peer!.setLocalDescription(answer);

      print(
        '[M8 WEBRTC] ANSWER CREATED '
        'type=${answer.type} sdp=${answer.sdp != null ? 'OK' : 'NULL'}',
      );

      await _sendSignal('answer', <String, dynamic>{
        'type': answer.type,
        'sdp': answer.sdp,
      });

      print('[M8 WEBRTC] ANSWER SENT');
    } else if (type == 'answer') {
      final sdp = payload['sdp'];
      final answerType = payload['type'];

      print(
        '[M8 WEBRTC] ANSWER RECEIVED '
        'type=$answerType sdp=${sdp != null ? 'OK' : 'NULL'}',
      );

      if (sdp == null) return;

      await peer!.setRemoteDescription(RTCSessionDescription(sdp, answerType));

      _remoteDescriptionSet = true;

      // Masukkan candidate yang tertahan selama answer belum siap.
      for (final candidate in List<RTCIceCandidate>.from(
        _pendingIceCandidates,
      )) {
        try {
          await peer!.addCandidate(candidate);
        } catch (e) {
          print('[M8 WEBRTC] queued ICE error: $e');
        }
      }
      _pendingIceCandidates.clear();
    } else if (type == 'ice') {
      final candidate = payload['candidate'];

      print(
        '[M8 WEBRTC] ICE RECEIVED '
        'candidate=${candidate != null ? 'OK' : 'NULL'}',
      );

      if (candidate == null) return;

      final iceCandidate = RTCIceCandidate(
        candidate,
        payload['sdpMid'],
        payload['sdpMLineIndex'],
      );

      if (!_remoteDescriptionSet) {
        _pendingIceCandidates.add(iceCandidate);
        print('[M8 WEBRTC] ICE queued');
        return;
      }

      try {
        await peer!.addCandidate(iceCandidate);
      } catch (e) {
        print('[M8 WEBRTC] ICE add error: $e');
      }
    }
  }

  void _startSignalPolling() {
    _signalTimer?.cancel();

    _signalTimer = Timer.periodic(
      const Duration(milliseconds: 800),
      (_) => _pollSignals(),
    );

    _pollSignals();
  }

  Future<void> _pollSignals() async {
    if (_isEnding) return;
    if (callId == null || myPin == null) return;

    try {
      final response = await http.get(
        Uri.parse(
          '$apiBase/api/calls/signals'
          '?call_id=${Uri.encodeComponent(callId!)}'
          '&m8_pin=${Uri.encodeComponent(myPin!)}',
        ),
      );

      if (response.statusCode != 200) return;

      final data = jsonDecode(response.body);

      if (data['success'] != true) return;

      final status = data['status']?.toString();

      if (status == 'ended' || status == 'rejected') {
        _signalTimer?.cancel();

        if (status == 'rejected') {
          _setCallStatus('rejected');
        } else {
          _setCallStatus('ended');
        }

        return;
      }

      final signals = data['signals'];

      if (signals is! List) return;

      if (_isEnding) return;

    for (final item in signals) {
      if (_isEnding) return;
        final signal = Map<String, dynamic>.from(item);

        final id = int.tryParse(signal['id']?.toString() ?? '') ?? 0;

        if (id <= _lastSignalId) continue;

        _lastSignalId = id;

        try {
          print(
            '[M8 WEBRTC] RECEIVE SIGNAL '
            'id=$id type=${signal['type']}',
          );

          await _handleSignal(signal);
        } catch (e) {
          print('[M8 WEBRTC] HANDLE SIGNAL ERROR: $e');
        }
      }
    } catch (_) {
      // Polling tetap berjalan selama panggilan aktif.
    }
  }

  Future<void> hangUp() async {
    // Jangan jalankan cleanup dua kali.
    if (_isEnding) return;

    _isEnding = true;
    _setCallStatus('ended');

    // Hentikan timer polling terlebih dahulu.
    _signalTimer?.cancel();
    _signalTimer = null;

    final currentCallId = callId;
    final currentPin = myPin;

    // Putuskan audio/video lokal secepat mungkin.
    try {
      for (final track in localStream?.getTracks() ?? <MediaStreamTrack>[]) {
        track.enabled = false;
        track.stop();
      }
    } catch (e) {
      print('[M8 CALL] STOP TRACK ERROR: $e');
    }

    // Lepaskan peer connection.
    try {
      final currentPeer = peer;
      peer = null;

      if (currentPeer != null) {
        await currentPeer.close();
      }
    } catch (e) {
      print('[M8 CALL] PEER CLOSE ERROR: $e');
    }

    // Dispose local stream setelah peer ditutup.
    try {
      final currentStream = localStream;
      localStream = null;

      if (currentStream != null) {
        await currentStream.dispose();
      }
    } catch (e) {
      print('[M8 CALL] STREAM DISPOSE ERROR: $e');
    }

    // HANYA lepaskan source renderer.
    // Jangan dispose renderer di sini karena VoiceCallPage masih hidup.
    try {
      localRenderer.srcObject = null;
      remoteRenderer.srcObject = null;
    } catch (e) {
      print('[M8 CALL] RENDERER CLEAR ERROR: $e');
    }

    // Beri tahu server bahwa sesi sudah berakhir.
    if (currentCallId != null && currentPin != null) {
      try {
        final response = await http.post(
          Uri.parse('$apiBase/api/calls/end'),
          headers: <String, String>{
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'call_id': currentCallId,
            'm8_pin': currentPin,
          }),
        );

        print(
          '[M8 CALL] END CALL HTTP ${response.statusCode}: '
          '${response.body}',
        );
      } catch (e) {
        print('[M8 CALL] END CALL ERROR: $e');
      }
    }

    // Bersihkan state setelah semua resource dilepas.
    callId = null;
    myPin = null;
    _lastSignalId = 0;
    _pendingIceCandidates.clear();
    _remoteDescriptionSet = false;

    // Reset audio routing Android setelah sesi selesai.
    try {
      await Helper.clearAndroidCommunicationDevice();
    } catch (e) {
      print('[M8 CALL] AUDIO ROUTE CLEAR ERROR: $e');
    }
  }
}
