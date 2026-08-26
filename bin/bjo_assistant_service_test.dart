import '../lib/integration/bjo_assistant_service.dart';
import '../lib/integration/bjo_assistant_state.dart';

Future<void> main() async {
  final assistant = BJoAssistantService();

  if (assistant.state.status != BJoAssistantStatus.idle) {
    throw StateError('Initial state tidak idle');
  }

  await assistant.start();

  final response = await assistant.ask('Halo dari BJo Assistant');

  if (response != 'Aku mendengarkan: Halo dari BJo Assistant') {
    throw StateError('Response tidak sesuai: $response');
  }

  if (assistant.state.lastMessage != 'Halo dari BJo Assistant') {
    throw StateError('lastMessage tidak tersimpan');
  }

  if (assistant.state.lastResponse != response) {
    throw StateError('lastResponse tidak tersimpan');
  }

  if (assistant.state.status != BJoAssistantStatus.idle) {
    throw StateError('Assistant tidak kembali ke idle');
  }

  await assistant.stop();

  print('BJO ASSISTANT SERVICE TEST: PASS');
  print('Status: ${assistant.state.status}');
  print('Response: $response');
}
