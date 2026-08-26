import 'bhre_knowledge_domain.dart';
import 'bhre_knowledge_record.dart';

abstract interface class BhreKnowledgeStore {
  Future<void> save(BhreKnowledgeRecord record);

  Future<BhreKnowledgeRecord?> getById(String id);

  Future<List<BhreKnowledgeRecord>> findByDomain(BhreKnowledgeDomain domain);

  Future<List<BhreKnowledgeRecord>> search(String query);

  Future<void> clear();
}
