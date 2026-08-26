import 'bhre_lifecycle.dart';

/// Jembatan resmi B'Jo ↔ Bree.
///
/// UI B'Jo tidak perlu mengetahui implementasi internal BHRE.
class BhreAppBridge {
  final BhreLifecycle _lifecycle;

  BhreAppBridge({BhreLifecycle? lifecycle})
    : _lifecycle = lifecycle ?? BhreLifecycle();

  bool get isInitialized => _lifecycle.isInitialized;

  Future<void> initialize() async {
    if (!_lifecycle.isInitialized) {
      await _lifecycle.initialize();
    }
  }

  Future<String> sendMessage(String message) async {
    await initialize();
    return _lifecycle.handleMessage(message);
  }

  Future<String> sendVoiceInput(String input) async {
    await initialize();
    return _lifecycle.handleVoiceInput(input);
  }

  Future<void> dispose() async {
    await _lifecycle.dispose();
  }
}
