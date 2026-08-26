import 'bhre_integration.dart';

class BhreLifecycle {
  final BhreIntegration integration;

  bool _initialized = false;

  BhreLifecycle({BhreIntegration? integration})
    : integration = integration ?? BhreIntegration();

  bool get isInitialized => _initialized;

  Future<void> initialize() async {
    if (_initialized) return;

    await integration.start();
    _initialized = true;
  }

  Future<void> dispose() async {
    if (!_initialized) return;

    await integration.stop();
    _initialized = false;
  }

  Future<String> handleMessage(String message) async {
    if (!_initialized) {
      await initialize();
    }

    return integration.sendMessage(message);
  }

  Future<String> handleVoiceInput(String input) async {
    if (!_initialized) {
      await initialize();
    }

    return integration.sendVoiceInput(input);
  }
}
