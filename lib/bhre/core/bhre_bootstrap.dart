import '../tools/alarm_tool.dart';
import '../tools/bhre_tool_registry.dart';

class BhreBootstrap {
  static BhreToolRegistry createToolRegistry() {
    final registry = BhreToolRegistry();

    registry.register(
      BhreAlarmTool(),
    );

    return registry;
  }
}
