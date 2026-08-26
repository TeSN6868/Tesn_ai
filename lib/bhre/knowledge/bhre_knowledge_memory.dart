import 'bhre_knowledge_record.dart';
import 'bhre_relation_engine.dart';
import 'bhre_relation.dart';

class BhreKnowledgeMemory {
  final int maxRecords;
  final List<BhreKnowledgeRecord> _records = [];
  final List<BhreKnowledgeGraph> _graphs = [];

  BhreKnowledgeMemory({this.maxRecords = 500}) : assert(maxRecords > 0);

  /// Knowledge records yang sudah disimpan.
  List<BhreKnowledgeRecord> get records => List.unmodifiable(_records);

  /// Knowledge graphs yang sudah diingat Bree.
  List<BhreKnowledgeGraph> get graphs => List.unmodifiable(_graphs);

  /// Menyimpan knowledge record lama.
  void store(BhreKnowledgeRecord record) {
    _records.add(record);

    if (_records.length > maxRecords) {
      _records.removeRange(0, _records.length - maxRecords);
    }
  }

  /// Menyimpan knowledge graph hasil BhreRelationEngine.
  void remember(BhreKnowledgeGraph graph) {
    _graphs.add(graph);

    if (_graphs.length > maxRecords) {
      _graphs.removeRange(0, _graphs.length - maxRecords);
    }
  }

  /// Mencari entity berdasarkan value di seluruh knowledge graph.
  ///
  /// Pencarian bersifat case-insensitive dan menggunakan exact match.
  /// Contoh:
  ///   findByValue('dokumen')
  ///   findByValue('Pak Arif')
  List<BhreEntity> findByValue(String value) {
    final normalized = value.trim().toLowerCase();

    if (normalized.isEmpty) {
      return const [];
    }

    final matches = <BhreEntity>[];

    for (final graph in _graphs) {
      for (final entity in graph.entities) {
        if (entity.value.trim().toLowerCase() == normalized) {
          matches.add(entity);
        }
      }
    }

    return List.unmodifiable(matches);
  }

  /// Mengambil seluruh entity dari seluruh knowledge graph.
  List<BhreEntity> allEntities() {
    final entities = <BhreEntity>[];

    for (final graph in _graphs) {
      entities.addAll(graph.entities);
    }

    return List.unmodifiable(entities);
  }

  /// Mencari knowledge record berdasarkan topic atau content.
  List<BhreKnowledgeRecord> search(String query) {
    final normalized = query.trim().toLowerCase();

    if (normalized.isEmpty) {
      return const [];
    }

    return List.unmodifiable(
      _records.where(
        (record) =>
            record.topic.toLowerCase().contains(normalized) ||
            record.content.toLowerCase().contains(normalized),
      ),
    );
  }

  /// Menghapus seluruh knowledge record dan knowledge graph.
  void clear() {
    _records.clear();
    _graphs.clear();
  }
}
