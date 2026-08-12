import 'dart:async';
import 'dart:convert';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:http/http.dart' as http;

class M8CallService {
  static const apiBase =
      'https://m8-messenger-api.coolalaga686.workers.dev';

  RTCPeerConnection? peer;
  MediaStream? localStream;

  String? callId;
  String? myPin;

  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  Timer? _signalTimer;
  int _lastSignalId = 0;

  bool audioEnabled = true;
  bool videoEnabled = true;

  Future<void> initializeRenderers() async {
    await localRenderer.initialize();
    await remoteRenderer.initialize();
  }

  Future<void> startCall({
    required String callerPin,
    required String calleePin,
  }) async {
    myPin = callerPin;

    final response = await http.post(
      Uri.parse('$apiBase/api/calls'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'caller_pin': callerPin,
        'callee_pin': calleePin,
      }),
    );

    final data = jsonDecode(response.body);

    if (data['success'] != true) {
      throw Exception(data['error'] ?? 'Gagal memulai panggilan');
    }

    callId = data['call_id'].toString();

    await _createPeer();

    final offer = await peer!.createOffer({
      'offerToReceiveAudio': 1,
      'offerToReceiveVideo': 1,
    });

    await peer!.setLocalDescription(offer);

    await _sendSignal(
      'offer',
      {
        'type': offer.type,
        'sdp': offer.sdp,
      },
    );

    _startSignalPolling();
  }

  Future<void> acceptCall({
    required String incomingCallId,
    required String calleePin,
  }) async {
    callId = incomingCallId;
    myPin = calleePin;

    final response = await http.post(
      Uri.parse('$apiBase/api/calls/accept'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'call_id': callId,
        'm8_pin': calleePin,
      }),
    );

    final data = jsonDecode(response.body);

    if (data['success'] != true) {
      throw Exception(data['error'] ?? 'Gagal menerima panggilan');
    }

    await _createPeer();
    _startSignalPolling();
  }

  Future<void> _createPeer() async {
    peer = await createPeerConnection({
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        {'urls': 'stun:stun1.l.google.com:19302'},
      ],
    });

    peer!.onIceCandidate = (candidate) async {
      if (candidate.candidate == null) return;

      await _sendSignal(
        'ice',
        {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        },
      );
    };

    peer!.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        remoteRenderer.srcObject = event.streams.first;
      }
    };

    localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': {
        'facingMode': 'user',
        'width': {'ideal': 1280},
        'height': {'ideal': 720},
      },
    });

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

  Future<void> _sendSignal(
    String type,
    Map<String, dynamic> payload,
  ) async {
    if (callId == null || myPin == null) return;

    await http.post(
      Uri.parse('$apiBase/api/calls/signal'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'call_id': callId,
        'sender_pin': myPin,
        'type': type,
        'payload': payload,
      }),
    );
  }

  Future<void> _handleSignal(Map<String, dynamic> signal) async {
    final type = signal['type'];
    final payload = Map<String, dynamic>.from(
      signal['payload'] ?? {},
    );

    if (type == 'offer') {
      final sdp = payload['sdp'];
      final offerType = payload['type'];

      if (sdp == null) return;

      await peer!.setRemoteDescription(
        RTCSessionDescription(
          sdp,
          offerType,
        ),
      );

      final answer = await peer!.createAnswer({
        'offerToReceiveAudio': 1,
        'offerToReceiveVideo': 1,
      });

      await peer!.setLocalDescription(answer);

      await _sendSignal(
        'answer',
        {
          'type': answer.type,
          'sdp': answer.sdp,
        },
      );
    } else if (type == 'answer') {
      final sdp = payload['sdp'];
      final answerType = payload['type'];

      if (sdp == null) return;

      await peer!.setRemoteDescription(
        RTCSessionDescription(
          sdp,
          answerType,
        ),
      );
    } else if (type == 'ice') {
      final candidate = payload['candidate'];

      if (candidate == null) return;

      await peer!.addCandidate(
        RTCIceCandidate(
          candidate,
          payload['sdpMid'],
          payload['sdpMLineIndex'],
        ),
      );
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
        return;
      }

      final signals = data['signals'];

      if (signals is! List) return;

      for (final item in signals) {
        final signal = Map<String, dynamic>.from(item);

        final id = int.tryParse(
              signal['id']?.toString() ?? '',
            ) ??
            0;

        if (id <= _lastSignalId) continue;

        _lastSignalId = id;

        await _handleSignal(signal);
      }
    } catch (_) {
      // Polling tetap berjalan selama panggilan aktif.
    }
  }

  Future<void> hangUp() async {
    _signalTimer?.cancel();

    if (callId != null && myPin != null) {
      await http.post(
        Uri.parse('$apiBase/api/calls/end'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'call_id': callId,
          'm8_pin': myPin,
        }),
      );
    }

    for (final track in localStream?.getTracks() ?? []) {
      track.stop();
    }

    await localStream?.dispose();
    await peer?.close();

    localRenderer.srcObject = null;
    remoteRenderer.srcObject = null;

    await localRenderer.dispose();
    await remoteRenderer.dispose();

    localStream = null;
    peer = null;
    callId = null;
    myPin = null;
    _signalTimer = null;
    _lastSignalId = 0;
  }
}
