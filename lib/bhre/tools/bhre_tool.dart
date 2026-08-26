abstract class BhreTool {
  String get id;
  String get name;
  String get description;

  bool canHandle(String command);

  Future<String> execute(String command);
}
