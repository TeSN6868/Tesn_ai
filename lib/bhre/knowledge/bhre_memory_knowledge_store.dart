import 'bhre_knowledge_domain.dart';
import 'bhre_knowledge_record.dart';
import 'bhre_knowledge_store.dart';

class BhreMemoryKnowledgeStore implements BhreKnowledgeStore {
  final Map<String, BhreKnowledgeRecord> _records = {};

  @override
  Future<void> save(BhreKnowledgeRecord record) async {
    _records[record.id] = record;
  }

  @override
  Future<BhreKnowledgeRecord?> getById(String id) async {
    return _records[id];
  }

  @override
  Future<List<BhreKnowledgeRecord>> findByDomain(
    BhreKnowledgeDomain domain,
  ) async {
    final results = _records.values
        .where((record) => record.domain == domain)
        .toList();

    return List.unmodifiable(results);
  }

  @override
  Future<List<BhreKnowledgeRecord>> search(String query) async {
    final normalized = query.trim().toLowerCase();

    if (normalized.isEmpty) {
      return const [];
    }

    final results = _records.values.where((record) {
      return record.topic.toLowerCase().contains(normalized) ||
          record.content.toLowerCase().contains(normalized);
    }).toList();

    return List.unmodifiable(results);
  }

  @override
  Future<void> clear() async {
    _records.clear();
  }
}
