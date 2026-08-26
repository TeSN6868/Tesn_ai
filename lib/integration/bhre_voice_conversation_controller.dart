import 'package:flutter/foundation.dart';

import '../bhre/core/bhre_runtime.dart';
import '../bhre/core/bhre_event.dart';
import '../bhre_voice_core.dart';

enum BhreVoiceMode { off, listening, thinking, speaking, error }

class BhreVoiceConversationController extends ChangeNotifier {
  final BhreRuntime runtime;
  final BhreVoiceCore voice;

  BhreVoiceMode _mode = BhreVoiceMode.off;
  bool _enabled = false;
  bool _busy = false;
  String _lastTranscript = '';
  String _lastResponse = '';
  String? _error;

  BhreVoiceConversationController({BhreRuntime? runtime, BhreVoiceCore? voice})
    : runtime = runtime ?? BhreRuntime(),
      voice = voice ?? BhreVoiceCore();

  BhreVoiceMode get mode => _mode;
  bool get isEnabled => _enabled;
  bool get isListening => _mode == BhreVoiceMode.listening;
  bool get isThinking => _mode == BhreVoiceMode.thinking;
  bool get isSpeaking => _mode == BhreVoiceMode.speaking;
  String get lastTranscript => _lastTranscript;
  String get lastResponse => _lastResponse;
  String? get error => _error;

  Future<void> start() async {
    if (_enabled) return;

    _enabled = true;
    _error = null;
    _mode = BhreVoiceMode.listening;
    notifyListeners();

    try {
      await runtime.start();
      await voice.initialize();

      await _conversationLoop();
    } catch (e) {
      if (!_enabled) return;

      _error = e.toString();
      _mode = BhreVoiceMode.error;
      notifyListeners();
    }
  }

  Future<void> stop() async {
    _enabled = false;

    await voice.stopListening();
    await voice.stopSpeaking();

    _mode = BhreVoiceMode.off;
    _busy = false;
    notifyListeners();
  }

  Future<void> _conversationLoop() async {
    while (_enabled) {
      if (_busy) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        continue;
      }

      _busy = true;

      try {
        _mode = BhreVoiceMode.listening;
        _error = null;
        notifyListeners();

        final transcript = await voice.listen(
          listenFor: const Duration(seconds: 15),
          pauseFor: const Duration(seconds: 2),
          localeId: 'id_ID',
        );

        if (!_enabled) break;

        if (transcript == null || transcript.trim().isEmpty) {
          _busy = false;
          continue;
        }

        _lastTranscript = transcript.trim();
        _mode = BhreVoiceMode.thinking;
        notifyListeners();

        final response = await runtime.dispatch(
          BhreEvent(type: BhreEventType.userMessage, payload: _lastTranscript),
        );

        if (!_enabled) break;

        _lastResponse = response.text.trim();

        if (_lastResponse.isNotEmpty) {
          _mode = BhreVoiceMode.speaking;
          notifyListeners();

          await voice.speak(_lastResponse);
        }

        if (!_enabled) break;

        _mode = BhreVoiceMode.listening;
        notifyListeners();
      } catch (e) {
        if (!_enabled) break;

        _error = e.toString();
        _mode = BhreVoiceMode.error;
        notifyListeners();

        await Future<void>.delayed(const Duration(seconds: 1));

        if (_enabled) {
          _mode = BhreVoiceMode.listening;
          notifyListeners();
        }
      } finally {
        _busy = false;
      }
    }

    if (!_enabled) {
      _mode = BhreVoiceMode.off;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _enabled = false;
    voice.dispose();
    runtime.stop();
    super.dispose();
  }
}
