import '../lib/integration/bhre_assistant_service.dart';
import '../lib/integration/bhre_assistant_state.dart';

Future<void> main() async {
  final assistant = BhreAssistantService();

  if (assistant.state.status != BhreAssistantStatus.idle) {
    throw StateError('Initial state tidak idle');
  }

  if (assistant.isStarted) {
    throw StateError('BHRE seharusnya belum started');
  }

  await assistant.start();

  if (!assistant.isStarted) {
    throw StateError('BHRE Assistant gagal start');
  }

  if (assistant.state.status != BhreAssistantStatus.idle) {
    throw StateError('Status setelah start bukan idle');
  }

  final response = await assistant.ask('Halo dari BHRE Assistant');

  if (response != 'Aku mendengarkan: Halo dari BHRE Assistant') {
    throw StateError('Response tidak sesuai: $response');
  }

  if (assistant.state.lastMessage != 'Halo dari BHRE Assistant') {
    throw StateError('lastMessage tidak tersimpan');
  }

  if (assistant.state.lastResponse != response) {
    throw StateError('lastResponse tidak tersimpan');
  }

  if (assistant.state.status != BhreAssistantStatus.idle) {
    throw StateError('Assistant tidak kembali ke idle');
  }

  final emptyResponse = await assistant.ask('   ');

  if (emptyResponse != 'Silakan sampaikan pesan terlebih dahulu.') {
    throw StateError('Validasi pesan kosong gagal');
  }

  await assistant.stop();

  if (assistant.isStarted) {
    throw StateError('BHRE Assistant gagal stop');
  }

  print('BHRE ASSISTANT SERVICE TEST: PASS');
  print('Status: ${assistant.state.status}');
  print('Response: $response');
  print('Empty input: $emptyResponse');
}
