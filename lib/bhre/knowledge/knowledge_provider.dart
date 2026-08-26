import 'knowledge_result.dart';

abstract class BhreKnowledgeProvider {
  String get id;

  Future<List<BhreKnowledgeResult>> search(String query);
}
