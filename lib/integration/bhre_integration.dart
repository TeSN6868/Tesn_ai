import '../bhre/core/bhre_app.dart';

class BhreIntegration {
  final BhreApp app;

  BhreIntegration({
    BhreApp? app,
  }) : app = app ?? BhreApp();

  Future<void> start() {
    return app.start();
  }

  Future<void> stop() {
    return app.stop();
  }

  Future<String> sendMessage(String message) async {
    final response = await app.sendMessage(message);
    return response.text;
  }

  Future<String> sendVoiceInput(String input) async {
    final response = await app.sendVoiceInput(input);
    return response.text;
  }
}
