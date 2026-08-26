import '../cognition/bhre_cognition_engine.dart';
import '../cognition/bhre_decision.dart';
import '../core/bhre_context_manager.dart';
import '../memory/bhre_memory.dart';
import '../models/bhre_context.dart';
import '../perception/bhre_observation.dart';
import '../perception/bhre_perception.dart';
import 'bhre_intent_router.dart';

class BhreAgent {
  final BhreIntentRouter intentRouter;
  final BhreCognitionEngine cognition;
  final BhreContextManager contextManager;
  final BhrePerception perception;
  final BhreMemory memory;

  BhreAgent({
    BhreIntentRouter? intentRouter,
    BhreCognitionEngine? cognition,
    BhreContextManager? contextManager,
    BhrePerception? perception,
    BhreMemory? memory,
  }) : intentRouter = intentRouter ?? BhreIntentRouter(),
       cognition = cognition ?? BhreCognitionEngine(),
       contextManager = contextManager ?? BhreContextManager(),
       perception = perception ?? BhrePerception(),
       memory = memory ?? BhreMemory();

  BhreDecision process(String input) {
    final intent = intentRouter.route(input);
    return cognition.decide(intent);
  }

  BhreDecision processWithPipeline(
    String input, {
    String? sessionId,
    String? userId,
    BhreSource source = BhreSource.bjo,
  }) {
    final normalized = input.trim();

    final context = contextManager.ensureContext(
      sessionId: sessionId,
      userId: userId,
      source: source,
    );

    final observation = BhreObservation(
      type: BhreObservationType.userMessage,
      value: normalized,
      timestamp: DateTime.now(),
    );

    perception.observe(observation);

    memory.remember(
      content: normalized,
      type: observation.type,
      context: context,
      timestamp: observation.timestamp,
    );

    final intent = intentRouter.route(normalized);
    return cognition.decide(intent);
  }
}
