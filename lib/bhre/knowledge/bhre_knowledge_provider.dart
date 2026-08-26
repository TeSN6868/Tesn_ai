import '../source/bhre_source_kind.dart';
import 'bhre_knowledge_record.dart';
import 'bhre_knowledge_request.dart';

abstract interface class BhreKnowledgeProvider {
  String get id;

  String get name;

  BhreSourceKind get sourceKind;

  Future<List<BhreKnowledgeRecord>> search(
    BhreKnowledgeRequest request,
  );

  bool supports(BhreKnowledgeRequest request);
}
