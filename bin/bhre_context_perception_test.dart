import '../lib/bhre/core/bhre_context_manager.dart';
import '../lib/bhre/models/bhre_context.dart';
import '../lib/bhre/perception/bhre_observation.dart';
import '../lib/bhre/perception/bhre_perception.dart';

Future<void> main() async {
  final contextManager = BhreContextManager();

  if (contextManager.hasContext) {
    throw StateError('Context seharusnya belum tersedia');
  }

  final context = contextManager.ensureContext(
    sessionId: 'TEST-SESSION-001',
    userId: 'TEST-USER-001',
    source: BhreSource.bjo,
  );

  if (!contextManager.hasContext) {
    throw StateError('Context gagal dibuat');
  }

  if (context.sessionId != 'TEST-SESSION-001') {
    throw StateError('Session ID tidak sesuai');
  }

  if (context.source != BhreSource.bjo) {
    throw StateError('Source tidak sesuai');
  }

  final perception = BhrePerception(maxObservations: 3);

  perception.observe(
    BhreObservation(
      type: BhreObservationType.userMessage,
      value: 'Halo BHRE',
      timestamp: DateTime.now(),
    ),
  );

  perception.observe(
    BhreObservation(
      type: BhreObservationType.voiceInput,
      value: 'Buka percakapan',
      timestamp: DateTime.now(),
    ),
  );

  if (perception.observations.length != 2) {
    throw StateError('Jumlah observation tidak sesuai');
  }

  if (perception.latest?.value != 'Buka percakapan') {
    throw StateError('Latest observation tidak sesuai');
  }

  perception.observe(
    BhreObservation(
      type: BhreObservationType.systemEvent,
      value: 'System ready',
      timestamp: DateTime.now(),
    ),
  );

  perception.observe(
    BhreObservation(
      type: BhreObservationType.toolResult,
      value: 'Tool selesai',
      timestamp: DateTime.now(),
    ),
  );

  if (perception.observations.length != 3) {
    throw StateError('Buffer observation gagal membatasi ukuran');
  }

  if (perception.observations.first.value != 'Buka percakapan') {
    throw StateError('Observation lama tidak dibuang dengan benar');
  }

  contextManager.clear();

  if (contextManager.hasContext) {
    throw StateError('Context gagal clear');
  }

  print('BHRE CONTEXT + PERCEPTION TEST: PASS');
  print('Session: ${context.sessionId}');
  print('Observations: ${perception.observations.length}');
}
