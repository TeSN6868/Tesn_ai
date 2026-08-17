import 'dart:io';

import 'package:record/record.dart';

class M8VoiceService {
  final AudioRecorder _recorder = AudioRecorder();

  Future<bool> get isRecording => _recorder.isRecording();

  Future<bool> hasPermission() async {
    return await _recorder.hasPermission();
  }

  Future<void> start(String path) async {
    final allowed = await _recorder.hasPermission();

    if (!allowed) {
      throw Exception('Izin mikrofon belum diberikan.');
    }

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: path,
    );
  }

  Future<String?> stop() async {
    return await _recorder.stop();
  }

  Future<void> cancel() async {
    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }
  }

  Future<void> dispose() async {
    await _recorder.dispose();
  }

  bool fileExists(String? path) {
    if (path == null || path.isEmpty) return false;
    return File(path).existsSync();
  }
}
