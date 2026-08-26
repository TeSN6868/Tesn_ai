import 'bhre_decision.dart';
import 'bhre_intent.dart';

class BhreCognitionEngine {
  const BhreCognitionEngine();

  BhreDecision decide(BhreIntent intent) {
    switch (intent.type) {
      case BhreIntentType.question:
      case BhreIntentType.informationRequest:
      case BhreIntentType.search:
        return BhreDecision(
          type: BhreDecisionType.searchKnowledge,
          intent: intent,
          reason: 'Input membutuhkan informasi dari knowledge layer.',
        );

      case BhreIntentType.reminder:
      case BhreIntentType.alarm:
      case BhreIntentType.navigation:
      case BhreIntentType.automation:
        return BhreDecision(
          type: BhreDecisionType.executeTool,
          intent: intent,
          reason: 'Input membutuhkan tindakan melalui tool layer.',
        );

      case BhreIntentType.planning:
        return BhreDecision(
          type: BhreDecisionType.createPlan,
          intent: intent,
          reason: 'Input memiliki tujuan yang perlu dipecah menjadi rencana.',
        );

      case BhreIntentType.command:
        return BhreDecision(
          type: BhreDecisionType.executeTool,
          intent: intent,
          reason: 'Input merupakan perintah yang berpotensi membutuhkan tindakan.',
        );

      case BhreIntentType.conversation:
        return BhreDecision(
          type: BhreDecisionType.respond,
          intent: intent,
          reason: 'Input merupakan percakapan langsung.',
        );

      case BhreIntentType.unknown:
        return BhreDecision(
          type: BhreDecisionType.requestClarification,
          intent: intent,
          reason: 'Maksud pengguna belum cukup jelas.',
        );
    }
  }
}
