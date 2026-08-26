import '../lib/bhre/memory/bhre_memory.dart';
import '../lib/bhre/models/bhre_context.dart';
import '../lib/bhre/perception/bhre_observation.dart';

Future<void> main() async {
  final context = BhreContext(
    sessionId: 'MEMORY-SESSION-001',
    userId: 'USER-001',
    source: BhreSource.bjo,
    locale: 'id-ID',
    createdAt: DateTime.now(),
  );

  final memory = BhreMemory(maxEntries: 3);

  memory.remember(
    content: 'Halo BHRE',
    type: BhreObservationType.userMessage,
    context: context,
  );

  memory.remember(
    content: 'Buka percakapan dengan Andi',
    type: BhreObservationType.userMessage,
    context: context,
  );

  if (memory.entries.length != 2) {
    throw StateError('Memory entry tidak tersimpan dengan benar');
  }

  if (memory.latest?.content != 'Buka percakapan dengan Andi') {
    throw StateError('Latest memory tidak sesuai');
  }

  final results = memory.search('Andi');

  if (results.length != 1) {
    throw StateError('Memory search gagal');
  }

  memory.remember(
    content: 'Periksa pesan terbaru',
    type: BhreObservationType.userMessage,
    context: context,
  );

  memory.remember(
    content: 'Tampilkan notifikasi',
    type: BhreObservationType.notificationReceived,
    context: context,
  );

  if (memory.entries.length != 3) {
    throw StateError('Memory buffer gagal membatasi ukuran');
  }

  if (memory.entries.first.content != 'Buka percakapan dengan Andi') {
    throw StateError('Memory lama tidak dibuang dengan benar');
  }

  final recent = memory.recent(2);

  if (recent.length != 2) {
    throw StateError('Recent memory gagal');
  }

  memory.clear();

  if (memory.entries.isNotEmpty) {
    throw StateError('Memory gagal clear');
  }

  print('BHRE MEMORY TEST: PASS');
  print('Session: ${context.sessionId}');
  print('Search: ${results.first.content}');
}
