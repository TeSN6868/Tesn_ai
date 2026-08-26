import 'bhre_intent.dart';

enum BhreDecisionType {
  respond,
  searchKnowledge,
  recallMemory,
  createPlan,
  executeTool,
  requestClarification,
}

class BhreDecision {
  final BhreDecisionType type;
  final BhreIntent intent;
  final String reason;
  final Map<String, dynamic> parameters;

  const BhreDecision({
    required this.type,
    required this.intent,
    required this.reason,
    this.parameters = const {},
  });
}
