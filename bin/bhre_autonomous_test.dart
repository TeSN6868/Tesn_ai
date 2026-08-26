import '../lib/bhre/knowledge/bhre_understanding_engine.dart';
import '../lib/bhre/autonomy/bhre_autonomous_engine.dart';

void main() {
  const input =
      'Besok sore tolong ingatkan saya membawa dokumen '
      'yang kemarin saya taruh di meja, karena akan saya '
      'berikan ke Pak Arif di acara Sembukan.';

  const understandingEngine =
      BhreUnderstandingEngine();

  final understanding =
      understandingEngine.understand(input);

  final autonomous =
      BhreAutonomousEngine();

  final state =
      autonomous.process(understanding);

  if (!state.hasContext) {
    throw StateError(
      'Autonomous engine tidak memiliki context.',
    );
  }

  if (!state.hasMemory) {
    throw StateError(
      'Autonomous engine tidak menyimpan memory.',
    );
  }

  if (!state.hasGoal) {
    throw StateError(
      'Autonomous engine tidak menemukan goal/action.',
    );
  }

  print('BHRE AUTONOMOUS ENGINE TEST: PASS');
  print('');
  print('Context: ${state.hasContext}');
  print('Memory: ${state.hasMemory}');
  print('Goal: ${state.hasGoal}');
  print(
    'Clarification: ${state.requiresClarification}',
  );
  print('Next action: ${state.nextAction}');
  print('Confidence: ${state.confidence}');
  print('');
  print('STORED FACTS:');

  for (final fact in autonomous.contextStore.facts) {
    print(
      '- ${fact.type.name}: ${fact.value} '
      '(confidence=${fact.confidence})',
    );
  }
}
