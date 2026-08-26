import '../lib/integration/bhre_lifecycle.dart';

Future<void> main() async {
  final lifecycle = BhreLifecycle();

  if (lifecycle.isInitialized) {
    throw StateError('BHRE seharusnya belum initialized');
  }

  final response = await lifecycle.handleMessage('Tes lifecycle BHRE');

  if (!lifecycle.isInitialized) {
    throw StateError('BHRE gagal initialize otomatis');
  }

  if (response != 'Aku mendengarkan: Tes lifecycle BHRE') {
    throw StateError('Response tidak sesuai: $response');
  }

  await lifecycle.dispose();

  if (lifecycle.isInitialized) {
    throw StateError('BHRE gagal dispose');
  }

  print('BHRE LIFECYCLE TEST: PASS');
  print('Response: $response');
}
