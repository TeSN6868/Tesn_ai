import '../agent/bhre_agent.dart';
import '../answer/bhre_answer_assembler.dart';
import '../cognition/bhre_decision.dart';
import '../knowledge/bhre_knowledge_retriever.dart';
import '../knowledge/bhre_knowledge_request.dart';
import '../knowledge/bhre_knowledge_domain.dart';
import '../knowledge/bhre_memory_knowledge_store.dart';
import '../knowledge/bhre_knowledge_record.dart';
import '../tools/bhre_tool_executor.dart';
import '../tools/bhre_tool_registry.dart';
import '../knowledge/bhre_understanding_engine.dart';
import 'bhre_event.dart';
import 'bhre_response.dart';
import 'bhre_state.dart';

class BhreEngine {
  BhreState _state = const BhreState();

  final BhreAgent agent;
  final BhreUnderstandingEngine understanding;
  final BhreMemoryKnowledgeStore knowledgeStore;
  final BhreKnowledgeRetriever knowledgeRetriever;
  final BhreAnswerAssembler answerAssembler;
  final BhreToolExecutor toolExecutor;

  BhreEngine({
    BhreAgent? agent,
    BhreUnderstandingEngine? understanding,
    BhreMemoryKnowledgeStore? knowledgeStore,
    BhreKnowledgeRetriever? knowledgeRetriever,
    BhreAnswerAssembler? answerAssembler,
    BhreToolExecutor? toolExecutor,
  }) : agent = agent ?? BhreAgent(),
       understanding = understanding ?? const BhreUnderstandingEngine(),
       knowledgeStore = knowledgeStore ?? BhreMemoryKnowledgeStore(),
       knowledgeRetriever =
           knowledgeRetriever ??
           BhreKnowledgeRetriever(
             store: knowledgeStore ?? BhreMemoryKnowledgeStore(),
           ),
       answerAssembler = answerAssembler ?? const BhreAnswerAssembler(),
       toolExecutor =
           toolExecutor ?? BhreToolExecutor(registry: BhreToolRegistry()) {
    _seedCoreKnowledge();
  }

  BhreState get state => _state;

  Future<BhreResponse> handle(BhreEvent event) async {
    _state = _state.copyWith(
      runtime: BhreRuntimeState.thinking,
      currentTask: event.payload,
    );

    try {
      final response = await _process(event);

      _state = _state.copyWith(
        runtime: BhreRuntimeState.idle,
        currentTask: null,
      );

      return response;
    } catch (error) {
      _state = _state.copyWith(
        runtime: BhreRuntimeState.error,
        currentTask: null,
      );

      return const BhreResponse(
        text: 'Maaf, Bree mengalami kendala saat memprosesnya.',
        shouldSpeak: true,
      );
    }
  }

  Future<BhreResponse> _process(BhreEvent event) async {
    final input = event.payload.trim();

    if (input.isEmpty) {
      return const BhreResponse(
        text: 'Silakan sampaikan sesuatu kepada Bree.',
        shouldSpeak: true,
      );
    }

    switch (event.type) {
      case BhreEventType.userMessage:
      case BhreEventType.voiceInput:
        return _processUserInput(input);

      case BhreEventType.toolResult:
        return BhreResponse(
          text: 'Bree menerima hasil tindakan: $input',
          shouldSpeak: true,
        );

      default:
        return BhreResponse(
          text: 'Bree menerima event: $input',
          shouldSpeak: false,
        );
    }
  }

  Future<BhreResponse> _processUserInput(String input) async {
    // 1. Agent menerima dan mengingat input.
    final decision = agent.processWithPipeline(input);

    // 2. Understanding engine membangun pemahaman dan relasi.
    understanding.understand(input);

    // 3. Percakapan biasa ditangani langsung.
    if (decision.type == BhreDecisionType.respond) {
      return BhreResponse(
        text: _conversationResponse(input),
        shouldSpeak: true,
      );
    }

    // 4. Perintah diarahkan ke tool layer.
    if (decision.type == BhreDecisionType.executeTool) {
      final result = await toolExecutor.execute(input);

      return BhreResponse(
        text: result,
        shouldSpeak: true,
        shouldExecuteAction: true,
      );
    }

    // 5. Pertanyaan/informasi masuk ke knowledge layer.
    if (decision.type == BhreDecisionType.searchKnowledge) {
      final request = _requestFromDecision(input, decision);

      final candidates = await knowledgeRetriever.retrieve(
        query: input,
        domain: request.domain,
        limit: request.maxSources,
      );

      if (candidates.isNotEmpty) {
        final best = candidates.first;

        final answer = answerAssembler.assemble(
          query: input,
          candidates: candidates,
          answer: best.record.content,
        );

        return BhreResponse(text: answer.answer, shouldSpeak: true);
      }

      return BhreResponse(
        text: _knowledgeUnavailableResponse(input),
        shouldSpeak: true,
      );
    }

    // 6. Bree belum cukup memahami maksudnya.
    if (decision.type == BhreDecisionType.requestClarification) {
      return const BhreResponse(
        text:
            'Aku belum sepenuhnya memahami maksudmu. Coba jelaskan sedikit lagi.',
        shouldSpeak: true,
      );
    }

    // 7. Rencana.
    if (decision.type == BhreDecisionType.createPlan) {
      return BhreResponse(
        text:
            'Aku memahami bahwa kamu ingin membuat rencana. Jelaskan tujuan atau hasil akhirnya, lalu aku akan membantu memecahnya menjadi langkah-langkah.',
        shouldSpeak: true,
      );
    }

    return const BhreResponse(text: 'Aku mendengarkan.', shouldSpeak: true);
  }

  BhreKnowledgeRequest _requestFromDecision(
    String input,
    BhreDecision decision,
  ) {
    final normalized = input.toLowerCase();

    BhreKnowledgeDomain domain = BhreKnowledgeDomain.general;

    if (normalized.contains('ai') ||
        normalized.contains('teknologi') ||
        normalized.contains('flutter') ||
        normalized.contains('dart')) {
      domain = BhreKnowledgeDomain.technology;
    }

    return BhreKnowledgeRequest(query: input, domain: domain, maxSources: 5);
  }

  String _conversationResponse(String input) {
    final text = input.toLowerCase();

    if (text.contains('halo') ||
        text.contains('hai') ||
        text.contains('hello')) {
      return 'Halo! 👋 Aku Bree. Aku mendengarkan. Ada yang ingin kamu tanyakan?';
    }

    if (text.contains('siapa kamu') || text.contains('kamu siapa')) {
      return 'Aku Bree, mesin kecerdasan yang sedang kamu bangun. Aku siap mendengarkan, memahami, mengingat, mencari pengetahuan, dan menjalankan kemampuan yang tersedia.';
    }

    if (text.contains('terima kasih') || text.contains('makasih')) {
      return 'Sama-sama. Aku siap membantu.';
    }

    return 'Aku mendengarkan. Silakan lanjutkan.';
  }

  String _knowledgeUnavailableResponse(String input) {
    return 'Aku memahami pertanyaanmu, tetapi pengetahuan untuk menjawab "$input" belum tersedia di knowledge layer Bree.';
  }

  void _seedCoreKnowledge() {
    knowledgeStore.save(
      BhreKnowledgeRecord(
        id: 'bhre-core-identity',
        topic: 'Bree',
        content:
            'Bree adalah mesin kecerdasan yang dirancang untuk memahami input pengguna, mengelola konteks dan memory, mengambil knowledge, menggunakan tools, serta menyusun jawaban.',
        domain: BhreKnowledgeDomain.general,
        createdAt: DateTime.now(),
        confidence: 1.0,
        verified: true,
        generatedBy: 'Bree_CORE',
      ),
    );
  }
}
