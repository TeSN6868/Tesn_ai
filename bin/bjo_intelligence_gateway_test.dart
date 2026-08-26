import '../lib/integration/bjo_intelligence_gateway.dart';

Future<void> main() async {
  final gateway = BJoIntelligenceGateway();

  if (gateway.isReady) {
    throw StateError('Gateway tidak seharusnya ready sebelum start');
  }

  await gateway.start();

  if (!gateway.isReady) {
    throw StateError('Gateway gagal start');
  }

  final response = await gateway.ask('Halo BHRE dari BJo');

  if (response != 'Aku mendengarkan: Halo BHRE dari BJo') {
    throw StateError('Response tidak sesuai: $response');
  }

  final emptyResponse = await gateway.ask('   ');

  if (emptyResponse != 'Silakan sampaikan pesan terlebih dahulu.') {
    throw StateError('Validasi pesan kosong gagal');
  }

  await gateway.stop();

  if (gateway.isReady) {
    throw StateError('Gateway gagal stop');
  }

  print('BJO INTELLIGENCE GATEWAY TEST: PASS');
  print('Response: $response');
  print('Empty input: $emptyResponse');
}
