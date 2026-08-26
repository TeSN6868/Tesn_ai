import 'bhre_event.dart';
import 'bhre_response.dart';
import 'bhre_runtime.dart';

class BhreApp {
  final BhreRuntime runtime;

  BhreApp({
    BhreRuntime? runtime,
  }) : runtime = runtime ?? BhreRuntime();

  bool get isStarted => runtime.isStarted;

  Future<void> start() {
    return runtime.start();
  }

  Future<void> stop() {
    return runtime.stop();
  }

  Future<BhreResponse> sendMessage(String message) {
    return runtime.dispatch(
      BhreEvent(
        type: BhreEventType.userMessage,
        payload: message,
      ),
    );
  }

  Future<BhreResponse> sendVoiceInput(String input) {
    return runtime.dispatch(
      BhreEvent(
        type: BhreEventType.voiceInput,
        payload: input,
      ),
    );
  }
}
