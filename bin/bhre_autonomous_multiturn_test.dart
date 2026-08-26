import '../lib/bhre/autonomy/bhre_autonomous_engine.dart';
import '../lib/bhre/knowledge/bhre_understanding_engine.dart';

void main() {
  const understandingEngine =
      BhreUnderstandingEngine();

  final autonomous =
      BhreAutonomousEngine();

  const firstInput =
      'Kemarin saya taruh dokumen di meja.';

  final first =
      understandingEngine.understand(firstInput);

  final firstState =
      autonomous.process(first);

  print('TURN 1');
  print('Input: $firstInput');
  print('Next action: ${firstState.nextAction}');
  print('');

  const secondInput =
      'Besok ingatkan saya mengambilnya.';

  final second =
      understandingEngine.understand(secondInput);

  final secondState =
      autonomous.process(second);

  print('TURN 2');
  print('Input: $secondInput');
  print('Next action: ${secondState.nextAction}');
  print('');

  print('GOALS:');

  for (final goal in autonomous.goalManager.goals) {
    print(
      '- action=${goal.action}, '
      'target=${goal.target}, '
      'time=${goal.scheduledTime}, '
      'confidence=${goal.confidence}',
    );
  }

  print('');
  print('CONTEXT MEMORY:');

  for (final fact
      in autonomous.contextStore.facts) {
    print(
      '- ${fact.type.name}: ${fact.value}',
    );
  }

  if (autonomous.goalManager.goals.isEmpty) {
    throw StateError(
      'BHRE tidak membuat goal.',
    );
  }

  final goal =
      autonomous.goalManager.latest!;

  if (goal.action != 'ingatkan') {
    throw StateError(
      'Action goal salah: ${goal.action}',
    );
  }

  if (goal.target != 'dokumen') {
    throw StateError(
      'Target multi-turn belum terselesaikan: '
      '${goal.target}',
    );
  }

  if (goal.scheduledTime != 'besok') {
    throw StateError(
      'Waktu goal salah: '
      '${goal.scheduledTime}',
    );
  }

  print('');
  print(
    'BHRE AUTONOMOUS MULTI-TURN TEST: PASS',
  );
}
