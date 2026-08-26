import 'bjo_assistant_state.dart';
import 'bjo_intelligence_gateway.dart';

class BJoAssistantService {
  final BJoIntelligenceGateway _gateway;

  BJoAssistantState _state = const BJoAssistantState();

  BJoAssistantService({BJoIntelligenceGateway? gateway})
    : _gateway = gateway ?? BJoIntelligenceGateway();

  BJoAssistantState get state => _state;

  Future<void> start() async {
    await _gateway.start();
    _state = _state.copyWith(status: BJoAssistantStatus.idle, clearError: true);
  }

  Future<String> ask(String message) async {
    _state = _state.copyWith(
      status: BJoAssistantStatus.thinking,
      lastMessage: message,
      clearError: true,
    );

    try {
      final response = await _gateway.ask(message);

      _state = _state.copyWith(
        status: BJoAssistantStatus.responding,
        lastResponse: response,
      );

      _state = _state.copyWith(status: BJoAssistantStatus.idle);

      return response;
    } catch (error) {
      _state = _state.copyWith(
        status: BJoAssistantStatus.error,
        error: error.toString(),
      );
      rethrow;
    }
  }

  Future<void> stop() async {
    await _gateway.stop();
    _state = _state.copyWith(status: BJoAssistantStatus.idle);
  }
}
