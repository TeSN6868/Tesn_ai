import 'dart:convert';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:http/http.dart' as http;

class M8CallService {
  static const apiBase = 'https://m8-messenger-api.coolalaga686.workers.dev';

  RTCPeerConnection? peer;
  MediaStream? localStream;

  String? callId;
  String? myPin;

  Future<void> startCall({
    required String callerPin,
    required String calleePin,
  }) async {
    myPin = callerPin;

    final response = await http.post(
      Uri.parse('$apiBase/api/calls'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'caller_pin': callerPin, 'callee_pin': calleePin}),
    );

    final data = jsonDecode(response.body);

    if (data['success'] != true) {
      throw Exception(data['error'] ?? 'Gagal memulai panggilan');
    }

    callId = data['call_id'].toString();

    await _createPeer();

    final offer = await peer!.createOffer({'offerToReceiveAudio': 1});

    await peer!.setLocalDescription(offer);

    await _sendSignal('offer', {'type': offer.type, 'sdp': offer.sdp});
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

      await _sendSignal('ice', {
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
      });
    };

    localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': false,
    });

    for (final track in localStream!.getAudioTracks()) {
      await peer!.addTrack(track, localStream!);
    }
  }

  Future<void> _sendSignal(String type, Map<String, dynamic> payload) async {
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

  Future<void> hangUp() async {
    if (callId != null && myPin != null) {
      await http.post(
        Uri.parse('$apiBase/api/calls/end'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'call_id': callId, 'm8_pin': myPin}),
      );
    }

    for (final track in localStream?.getTracks() ?? []) {
      track.stop();
    }

    await localStream?.dispose();
    await peer?.close();

    localStream = null;
    peer = null;
    callId = null;
    myPin = null;
  }
}
