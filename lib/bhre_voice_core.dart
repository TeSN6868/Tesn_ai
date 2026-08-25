import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class BhreVoiceCore {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _initialized = false;
  bool _speaking = false;

  bool get isListening => _speech.isListening;
  bool get isSpeaking => _speaking;

  Future<bool> initialize() async {
    if (_initialized) return true;

    final available = await _speech.initialize(
      onError: (error) {
        // Error ditangani oleh caller.
      },
      onStatus: (status) {
        // Status tersedia untuk dikembangkan menjadi event engine.
      },
    );

    if (!available) return false;

    await _tts.setLanguage('id-ID');
    await _tts.setSpeechRate(0.48);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);

    _tts.setStartHandler(() {
      _speaking = true;
    });

    _tts.setCompletionHandler(() {
      _speaking = false;
    });

    _tts.setCancelHandler(() {
      _speaking = false;
    });

    _tts.setErrorHandler((_) {
      _speaking = false;
    });

    _initialized = true;
    return true;
  }

  Future<String?> listen({
    Duration listenFor = const Duration(seconds: 10),
    Duration pauseFor = const Duration(seconds: 3),
    String localeId = 'id_ID',
  }) async {
    final ready = await initialize();

    if (!ready) {
      throw Exception('Speech recognition tidak tersedia.');
    }

    if (_speech.isListening) {
      await _speech.stop();
    }

    String? result;

    await _speech.listen(
      onResult: (value) {
        if (value.finalResult && value.recognizedWords.trim().isNotEmpty) {
          result = value.recognizedWords.trim();
        }
      },
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
        listenMode: stt.ListenMode.confirmation,
        listenFor: listenFor,
        pauseFor: pauseFor,
        localeId: localeId,
      ),
    );

    while (_speech.isListening) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }

    return result;
  }

  Future<void> stopListening() async {
    if (_speech.isListening) {
      await _speech.stop();
    }
  }

  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;

    final ready = await initialize();

    if (!ready) {
      throw Exception('Text-to-speech tidak tersedia.');
    }

    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> stopSpeaking() async {
    await _tts.stop();
    _speaking = false;
  }

  Future<void> dispose() async {
    await _speech.stop();
    await _tts.stop();
    _speaking = false;
  }
}
