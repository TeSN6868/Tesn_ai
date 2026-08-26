import 'bhre_event.dart';
import 'bhre_response.dart';
import 'bhre_state.dart';

class BhreEngine {
  BhreState _state = const BhreState();

  BhreState get state => _state;

  Future<BhreResponse> handle(BhreEvent event) async {
    _state = _state.copyWith(
      runtime: BhreRuntimeState.thinking,
      currentTask: event.payload,
    );

    try {
      final response = await _process(event);

      _state = _state.copyWith(
        runtime: BhreRuntimeState.idle,
        currentTask: null,
      );

      return response;
    } catch (_) {
      _state = _state.copyWith(
        runtime: BhreRuntimeState.error,
        currentTask: null,
      );

      return const BhreResponse(
        text: 'Maaf, aku mengalami kendala saat memprosesnya.',
        shouldSpeak: true,
      );
    }
  }

  Future<BhreResponse> _process(BhreEvent event) async {
    switch (event.type) {
      case BhreEventType.userMessage:
        return BhreResponse(
          text: 'Aku mendengarkan: ${event.payload}',
        );

      case BhreEventType.voiceInput:
        return BhreResponse(
          text: 'Aku menerima perintah suara: ${event.payload}',
        );

      case BhreEventType.systemEvent:
      case BhreEventType.scheduledEvent:
      case BhreEventType.locationChanged:
      case BhreEventType.notificationReceived:
      case BhreEventType.toolResult:
        return BhreResponse(
          text: 'Event diterima dan siap diproses: ${event.payload}',
          shouldSpeak: false,
        );
    }
  }
}
