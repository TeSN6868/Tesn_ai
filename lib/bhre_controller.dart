import 'bhre_conversation_engine.dart';

class BhreController {
  final BhreConversationEngine engine;

  BhreController({
    BhreConversationEngine? engine,
  }) : engine = engine ?? BhreConversationEngine();

  bool get isListening => engine.voice.isListening;
  bool get isSpeaking => engine.voice.isSpeaking;

  Future<bool> initialize() {
    return engine.initialize();
  }

  Future<BhreConversationTurn?> talk() {
    return engine.listenAndProcess();
  }

  Future<BhreConversationTurn?> process(String text) {
    return engine.processText(text);
  }

  Future<void> speak(String text) {
    return engine.say(text);
  }

  Future<void> stop() async {
    await engine.voice.stopListening();
    await engine.voice.stopSpeaking();
  }

  Future<void> dispose() {
    return engine.dispose();
  }
}
