import '../lib/integration/bhre_app_controller.dart';

Future<void> main() async {
  final controller = BhreAppController();

  if (controller.isReady) {
    throw StateError('Controller seharusnya belum ready');
  }

  await controller.initialize();

  if (!controller.isReady) {
    throw StateError('Controller gagal initialize');
  }

  final response = await controller.processMessage('Tes controller BHRE');

  if (response != 'Aku mendengarkan: Tes controller BHRE') {
    throw StateError('Response tidak sesuai: $response');
  }

  await controller.shutdown();

  if (controller.isReady) {
    throw StateError('Controller gagal shutdown');
  }

  print('BHRE CONTROLLER TEST: PASS');
  print('Response: $response');
}
