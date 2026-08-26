abstract class BhreCapability {
  String get id;
  String get name;

  Future<void> initialize();

  bool canHandle(String command);

  Future<String?> execute(String command);

  Future<void> dispose();
}
