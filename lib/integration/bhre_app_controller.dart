import 'bhre_lifecycle.dart';

class BhreAppController {
  final BhreLifecycle lifecycle;

  BhreAppController({BhreLifecycle? lifecycle})
    : lifecycle = lifecycle ?? BhreLifecycle();

  bool get isReady => lifecycle.isInitialized;

  Future<void> initialize() {
    return lifecycle.initialize();
  }

  Future<void> shutdown() {
    return lifecycle.dispose();
  }

  Future<String> processMessage(String message) {
    return lifecycle.handleMessage(message);
  }

  Future<String> processVoice(String input) {
    return lifecycle.handleVoiceInput(input);
  }
}
