import '../cognition/bhre_cognition_engine.dart';
import '../cognition/bhre_decision.dart';
import '../core/bhre_response.dart';
import '../models/bhre_context.dart';
import '../perception/bhre_observation.dart';
import 'bhre_intent_router.dart';

class BhreAgent {
  final BhreIntentRouter intentRouter;
  final BhreCognitionEngine cognition;

  BhreContext _context = BhreContext(
    timestamp: DateTime.now(),
  );

  BhreAgent({
    BhreIntentRouter? intentRouter,
    BhreCognitionEngine? cognition,
  })  : intentRouter = intentRouter ?? BhreIntentRouter(),
        cognition = cognition ?? const BhreCognitionEngine();

  BhreContext get context => _context;

  void observe(BhreObservation observation) {
    final data = Map<String, dynamic>.from(_context.data);

    data[observation.type.name] = {
      'value': observation.value,
      'timestamp': observation.timestamp.toIso8601String(),
      ...observation.metadata,
    };

    _context = _context.copyWith(
      timestamp: DateTime.now(),
      data: data,
    );
  }

  Future<BhreResponse> receive(String input) async {
    final intent = intentRouter.route(input);
    final decision = cognition.decide(intent);

    return _respond(decision);
  }

  BhreResponse _respond(BhreDecision decision) {
    switch (decision.type) {
      case BhreDecisionType.searchKnowledge:
        return const BhreResponse(
          text: 'Saya perlu mencari informasi untuk menjawabnya.',
          shouldSpeak: true,
        );

      case BhreDecisionType.recallMemory:
        return const BhreResponse(
          text: 'Saya akan memeriksa ingatan saya.',
          shouldSpeak: true,
        );

      case BhreDecisionType.createPlan:
        return const BhreResponse(
          text: 'Saya akan menyusun rencana untuk itu.',
          shouldSpeak: true,
        );

      case BhreDecisionType.executeTool:
        return const BhreResponse(
          text: 'Saya memahami perintahnya dan menyiapkan tindakan.',
          shouldSpeak: true,
          shouldExecuteAction: true,
        );

      case BhreDecisionType.requestClarification:
        return const BhreResponse(
          text: 'Saya belum cukup memahami maksudmu. Bisa jelaskan sedikit lagi?',
          shouldSpeak: true,
        );

      case BhreDecisionType.respond:
        return const BhreResponse(
          text: 'Saya mendengarkan.',
          shouldSpeak: true,
        );
    }
  }
}
