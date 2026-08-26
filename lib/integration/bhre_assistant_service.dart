import '../bhre/core/bhre_runtime.dart';
import '../bhre/core/bhre_event.dart';
import 'bhre_assistant_state.dart';

class BhreAssistantService {
  final BhreRuntime _runtime;

  BhreAssistantState _state = const BhreAssistantState();

  BhreAssistantService({BhreRuntime? runtime})
      : _runtime = runtime ?? BhreRuntime();

  BhreAssistantState get state => _state;

  bool get isStarted => _runtime.isStarted;

  Future<void> start() async {
    if (_runtime.isStarted) return;

    _state = _state.copyWith(
      status: BhreAssistantStatus.starting,
      clearError: true,
    );

    try {
      await _runtime.start();

      _state = _state.copyWith(
        status: BhreAssistantStatus.idle,
      );
    } catch (e) {
      _state = _state.copyWith(
        status: BhreAssistantStatus.error,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<String> ask(String message) async {
    final normalized = message.trim();

    if (normalized.isEmpty) {
      return 'Silakan sampaikan pesan terlebih dahulu.';
    }

    if (!_runtime.isStarted) {
      await start();
    }

    _state = _state.copyWith(
      status: BhreAssistantStatus.thinking,
      lastMessage: normalized,
      clearError: true,
    );

    try {
      final response = await _runtime.dispatch(
        BhreEvent(
          type: BhreEventType.userMessage,
          payload: normalized,
        ),
      );

      _state = _state.copyWith(
        status: BhreAssistantStatus.idle,
        lastResponse: response.text,
      );

      return response.text;
    } catch (e) {
      _state = _state.copyWith(
        status: BhreAssistantStatus.error,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> stop() async {
    await _runtime.stop();

    _state = _state.copyWith(
      status: BhreAssistantStatus.idle,
    );
  }
}
