import '../lib/integration/bhre_integration.dart';

Future<void> main() async {
  final bhre = BhreIntegration();

  await bhre.start();

  if (!bhre.app.isStarted) {
    throw StateError('BHRE gagal start');
  }

  final response = await bhre.sendMessage('Halo BHRE');

  if (response != 'Aku mendengarkan: Halo BHRE') {
    throw StateError('Response BHRE tidak sesuai: $response');
  }

  await bhre.stop();

  if (bhre.app.isStarted) {
    throw StateError('BHRE gagal stop');
  }

  print('BHRE SMOKE TEST: PASS');
  print('Response: $response');
}
