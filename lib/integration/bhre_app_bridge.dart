import 'bhre_lifecycle.dart';

/// Application-level bridge antara B'Jo dan Bree.
///
/// Layer ini sengaja tipis agar UI B'Jo tidak bergantung langsung
/// pada implementasi internal Bree.
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

  Future<void> dispose() async {
    await _lifecycle.dispose();
  }
}
