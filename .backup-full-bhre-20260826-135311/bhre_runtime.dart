import '../agent/bhre_agent.dart';
import '../answer/bhre_answer_assembler.dart';
import '../cognition/bhre_decision.dart';
import '../knowledge/bhre_knowledge_candidate.dart';
import '../knowledge/bhre_knowledge_retriever.dart';
import '../knowledge/bhre_knowledge_router.dart';
import '../knowledge/bhre_memory_knowledge_store.dart';
import '../knowledge/bhre_understanding_engine.dart';
import '../tools/bhre_tool_executor.dart';
import '../tools/bhre_tool_registry.dart';
import 'bhre_engine.dart';
import 'bhre_event.dart';
import 'bhre_response.dart';
import 'bhre_state.dart';

class BhreRuntime {
  final BhreEngine engine;

  late final BhreAgent agent;
  late final BhreMemoryKnowledgeStore knowledgeStore;
  late final BhreKnowledgeRetriever knowledgeRetriever;
  late final BhreKnowledgeRouter knowledgeRouter;
  late final BhreUnderstandingEngine understanding;
  late final BhreAnswerAssembler answerAssembler;
  late final BhreToolExecutor toolExecutor;

  bool _started = false;

  BhreRuntime({
    BhreEngine? engine,
    BhreAgent? agent,
    BhreToolRegistry? toolRegistry,
  }) : engine = engine ?? BhreEngine() {
    knowledgeStore = BhreMemoryKnowledgeStore();
    knowledgeRetriever = BhreKnowledgeRetriever(store: knowledgeStore);
    knowledgeRouter = const BhreKnowledgeRouter();
    understanding = const BhreUnderstandingEngine();
    answerAssembler = const BhreAnswerAssembler();

    final registry = toolRegistry ?? BhreToolRegistry();
    toolExecutor = BhreToolExecutor(registry: registry);

    this.agent = agent ?? BhreAgent();
  }

  bool get isStarted => _started;

  BhreState get state => engine.state;

  Future<void> start() async {
    if (_started) return;
    _started = true;
  }

  Future<void> stop() async {
    if (!_started) return;
    _started = false;
  }

  Future<BhreResponse> dispatch(BhreEvent event) async {
    if (!_started) {
      await start();
    }

    if (event.type == BhreEventType.userMessage) {
      return _handleUserMessage(event.payload);
    }

    if (event.type == BhreEventType.voiceInput) {
      return _handleVoiceInput(event.payload);
    }

    return engine.handle(event);
  }

  Future<BhreResponse> _handleVoiceInput(String input) async {
    return _handleUserMessage(input);
  }

  Future<BhreResponse> _handleUserMessage(String input) async {
    final message = input.trim();

    if (message.isEmpty) {
      return const BhreResponse(
        text: 'Silakan sampaikan pesan terlebih dahulu.',
        shouldSpeak: true,
      );
    }

    final decision = agent.processWithPipeline(
      message,
      sessionId: 'default',
      userId: 'local-user',
    );

    // Understanding layer ikut membaca hubungan,
    // referensi, dan detail dari pesan.
    understanding.understand(message);

    switch (decision.type) {
      case BhreDecisionType.respond:
        return BhreResponse(
          text: _conversationResponse(message),
          shouldSpeak: true,
        );

      case BhreDecisionType.recallMemory:
        return _recallMemory(message);

      case BhreDecisionType.searchKnowledge:
        return _searchKnowledge(message);

      case BhreDecisionType.executeTool:
        return _executeTool(message);

      case BhreDecisionType.createPlan:
        return BhreResponse(
          text: 'Baik. Aku akan membantu menyusun rencana untuk: $message',
          shouldSpeak: true,
        );

      case BhreDecisionType.requestClarification:
        return BhreResponse(
          text:
              'Aku memahami sebagian pesanmu. Bisa jelaskan sedikit lebih spesifik?',
          shouldSpeak: true,
        );
    }
  }

  String _conversationResponse(String message) {
    final normalized = message.toLowerCase();

    if (normalized.contains('halo') ||
        normalized.contains('hai') ||
        normalized.contains('hei')) {
      return 'Halo. Aku Bree. Aku siap mendengarkan dan membantu.';
    }

    if (normalized.contains('siapa kamu') ||
        normalized.contains('kamu siapa')) {
      return 'Aku Bree, mesin kecerdasan yang sedang kamu bangun.';
    }

    if (normalized.contains('apa kabar')) {
      return 'Aku siap dan sedang menunggu perintahmu.';
    }

    return 'Aku memahami pesanmu: $message';
  }

  Future<BhreResponse> _searchKnowledge(String query) async {
    final request = knowledgeRouter.route(query);

    final candidates = await knowledgeRetriever.retrieve(
      query: request.query,
      domain: request.domain,
      limit: request.maxSources,
    );

    if (candidates.isEmpty) {
      return BhreResponse(
        text:
            'Aku belum menemukan pengetahuan yang cukup di dalam basis pengetahuanku untuk menjawab: $query',
        shouldSpeak: true,
      );
    }

    return _answerFromCandidates(query, candidates);
  }

  BhreResponse _answerFromCandidates(
    String query,
    List<BhreKnowledgeCandidate> candidates,
  ) {
    final contents = candidates
        .map((candidate) => candidate.record.content.trim())
        .where((content) => content.isNotEmpty)
        .toList();

    if (contents.isEmpty) {
      return BhreResponse(
        text:
            'Aku menemukan data, tetapi belum ada isi yang bisa digunakan untuk menjawab.',
        shouldSpeak: true,
      );
    }

    final answerText = contents.join('\n\n');

    final answer = answerAssembler.assemble(
      query: query,
      candidates: candidates,
      answer: answerText,
    );

    return BhreResponse(text: answer.answer, shouldSpeak: true);
  }

  Future<BhreResponse> _recallMemory(String query) async {
    final matches = agent.memory.search(query);

    if (matches.isEmpty) {
      return BhreResponse(
        text: 'Aku belum menemukan ingatan yang cocok dengan "$query".',
        shouldSpeak: true,
      );
    }

    final text = matches.map((entry) => entry.content).join('\n');

    return BhreResponse(text: 'Yang aku ingat:\n$text', shouldSpeak: true);
  }

  Future<BhreResponse> _executeTool(String command) async {
    final result = await toolExecutor.execute(command);

    return BhreResponse(text: result, shouldSpeak: true);
  }
}
