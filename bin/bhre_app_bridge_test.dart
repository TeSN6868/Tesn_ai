import '../lib/integration/bhre_app_bridge.dart';

Future<void> main() async {
  final bridge = BhreAppBridge();

  if (bridge.isInitialized) {
    throw StateError('Bridge seharusnya belum initialized');
  }

  final response = await bridge.sendMessage('Tes BJo ke BHRE');

  if (!bridge.isInitialized) {
    throw StateError('Bridge gagal initialize');
  }

  if (response != 'Aku mendengarkan: Tes BJo ke BHRE') {
    throw StateError('Response tidak sesuai: $response');
  }

  await bridge.dispose();

  if (bridge.isInitialized) {
    throw StateError('Bridge gagal dispose');
  }

  print('BHRE APP BRIDGE TEST: PASS');
  print('Response: $response');
}
