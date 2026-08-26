import 'bhre_app_bridge.dart';

/// Pintu utama aplikasi B'Jo untuk berkomunikasi dengan Bree.
///
/// UI B'Jo hanya perlu mengenal gateway ini.
/// Detail implementasi Bree tetap tersembunyi di bawah layer integration.
class BJoIntelligenceGateway {
  final BhreAppBridge _bridge;

  BJoIntelligenceGateway({BhreAppBridge? bridge})
    : _bridge = bridge ?? BhreAppBridge();

  bool get isReady => _bridge.isInitialized;

  Future<void> start() async {
    await _bridge.initialize();
  }

  Future<String> ask(String message) async {
    if (message.trim().isEmpty) {
      return 'Silakan sampaikan pesan terlebih dahulu.';
    }

    return _bridge.sendMessage(message.trim());
  }

  Future<void> stop() async {
    await _bridge.dispose();
  }
}
