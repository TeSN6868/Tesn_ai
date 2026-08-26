import 'bhre_command_router.dart';
import 'bhre_knowledge_core.dart';
import 'bhre_voice_core.dart';

class BhreConversationTurn {
  final String userText;
  final BhreCommand command;
  final String response;
  final List<BhreKnowledgeItem> knowledge;
  final DateTime timestamp;

  const BhreConversationTurn({
    required this.userText,
    required this.command,
    required this.response,
    required this.knowledge,
    required this.timestamp,
  });
}

class BhreConversationEngine {
  final BhreVoiceCore voice;
  final BhreKnowledgeCore knowledge;

  final List<BhreConversationTurn> _history = [];

  BhreConversationEngine({BhreVoiceCore? voice, BhreKnowledgeCore? knowledge})
    : voice = voice ?? BhreVoiceCore(),
      knowledge = knowledge ?? BhreKnowledgeCore();

  List<BhreConversationTurn> get history => List.unmodifiable(_history);

  Future<bool> initialize() async {
    return voice.initialize();
  }

  Future<BhreConversationTurn?> processText(String text) async {
    final clean = text.trim();

    if (clean.isEmpty) return null;

    final command = BhreCommandRouter.parse(clean);
    final matches = _findKnowledge(clean);

    final response = _buildResponse(command, matches);

    final turn = BhreConversationTurn(
      userText: clean,
      command: command,
      response: response,
      knowledge: matches,
      timestamp: DateTime.now(),
    );

    _history.add(turn);

    return turn;
  }

  Future<BhreConversationTurn?> listenAndProcess() async {
    final text = await voice.listen();

    if (text == null || text.trim().isEmpty) {
      return null;
    }

    final turn = await processText(text);

    if (turn != null) {
      await voice.speak(turn.response);
    }

    return turn;
  }

  Future<void> say(String text) async {
    await voice.speak(text);
  }

  List<BhreKnowledgeItem> _findKnowledge(String text) {
    return knowledge.search(text).take(5).toList(growable: false);
  }

  String _buildResponse(BhreCommand command, List<BhreKnowledgeItem> matches) {
    switch (command.type) {
      case BhreCommandType.security:
        return 'Baik. Saya siap memeriksa keamanan perangkat.';

      case BhreCommandType.deviceStatus:
        return 'Baik. Saya siap memeriksa kondisi perangkat.';

      case BhreCommandType.navigation:
        return 'Baik. Saya siap membuka sistem navigasi.';

      case BhreCommandType.call:
        final name = command.argument;

        if (name == null || name.isEmpty) {
          return 'Siapa yang ingin kamu panggil?';
        }

        return 'Baik. Saya siapkan panggilan untuk $name.';

      case BhreCommandType.chat:
        if (matches.isNotEmpty) {
          final best = matches.first;
          return '${best.title}. ${best.content}';
        }

        return 'Saya mendengarkan. Silakan lanjutkan.';

      case BhreCommandType.unknown:
        return 'Saya belum memahami perintah itu.';
    }
  }

  void clearHistory() {
    _history.clear();
  }

  Future<void> dispose() async {
    await voice.dispose();
  }
}
