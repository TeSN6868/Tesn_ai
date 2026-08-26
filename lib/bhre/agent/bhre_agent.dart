import '../cognition/bhre_cognition_engine.dart';
import '../cognition/bhre_decision.dart';
import 'bhre_intent_router.dart';

class BhreAgent {
  final BhreIntentRouter intentRouter;
  final BhreCognitionEngine cognition;

  BhreAgent({
    BhreIntentRouter? intentRouter,
    BhreCognitionEngine? cognition,
  })  : intentRouter = intentRouter ?? BhreIntentRouter(),
        cognition = cognition ?? BhreCognitionEngine();

  BhreDecision process(String input) {
    final intent = intentRouter.route(input);
    return cognition.decide(intent);
  }
}
