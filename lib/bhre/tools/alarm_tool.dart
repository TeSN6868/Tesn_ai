import '../services/alarm_service.dart';
import 'bhre_tool.dart';

class BhreAlarmTool implements BhreTool {
  final BhreAlarmService service;

  BhreAlarmTool({
    BhreAlarmService? service,
  }) : service = service ?? BhreAlarmService();

  @override
  String get id => 'alarm';

  @override
  String get name => 'Alarm';

  @override
  String get description =>
      'Mengatur dan membatalkan alarm berdasarkan perintah pengguna.';

  @override
  bool canHandle(String command) {
    final text = command.toLowerCase();

    return text.contains('alarm') ||
        text.contains('bangunkan') ||
        text.contains('bangun');
  }

  @override
  Future<String> execute(String command) async {
    return 'Perintah alarm diterima: $command';
  }
}
