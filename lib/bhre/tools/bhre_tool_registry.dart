import 'bhre_tool.dart';

class BhreToolRegistry {
  final Map<String, BhreTool> _tools = {};

  Iterable<BhreTool> get all => _tools.values;

  void register(BhreTool tool) {
    _tools[tool.id] = tool;
  }

  BhreTool? findFor(String command) {
    for (final tool in _tools.values) {
      if (tool.canHandle(command)) {
        return tool;
      }
    }

    return null;
  }

  BhreTool? get(String id) {
    return _tools[id];
  }

  bool contains(String id) {
    return _tools.containsKey(id);
  }
}
