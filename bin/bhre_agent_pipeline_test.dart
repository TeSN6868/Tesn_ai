import '../lib/bhre/agent/bhre_agent.dart';
import '../lib/bhre/cognition/bhre_decision.dart';

Future<void> main() async {
  final agent = BhreAgent();

  final decision = agent.processWithPipeline(
    'Buka percakapan dengan Andi',
    sessionId: 'AGENT-SESSION-001',
    userId: 'USER-001',
  );

  if (agent.contextManager.current == null) {
    throw StateError('BHRE context tidak terbentuk');
  }

  if (agent.contextManager.current!.sessionId != 'AGENT-SESSION-001') {
    throw StateError('Session ID tidak sesuai');
  }

  if (agent.perception.latest == null) {
    throw StateError('BHRE perception tidak menerima observasi');
  }

  if (agent.perception.latest!.value != 'Buka percakapan dengan Andi') {
    throw StateError('Observasi tidak sesuai');
  }

  if (agent.memory.latest == null) {
    throw StateError('BHRE memory tidak menyimpan input');
  }

  if (agent.memory.latest!.content != 'Buka percakapan dengan Andi') {
    throw StateError('Memory content tidak sesuai');
  }

  if (decision.type != BhreDecisionType.executeTool) {
    throw StateError(
      'Decision tidak sesuai: ${decision.type}',
    );
  }

  print('BHRE AGENT PIPELINE TEST: PASS');
  print('Session: ${agent.contextManager.current!.sessionId}');
  print('Observation: ${agent.perception.latest!.value}');
  print('Memory: ${agent.memory.latest!.content}');
  print('Decision: ${decision.type}');
}
