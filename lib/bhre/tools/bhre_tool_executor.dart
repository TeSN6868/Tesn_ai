import 'bhre_tool.dart';
import 'bhre_tool_registry.dart';

class BhreToolExecutor {
  final BhreToolRegistry registry;

  BhreToolExecutor({BhreToolRegistry? registry})
    : registry = registry ?? BhreToolRegistry();

  Future<String> execute(String command) async {
    final BhreTool? tool = registry.findFor(command);

    if (tool == null) {
      return 'Aku belum memiliki kemampuan untuk melakukan perintah itu.';
    }

    return tool.execute(command);
  }
}
