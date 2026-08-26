import '../lib/bhre/detail/bhre_detail_extractor.dart';
import '../lib/bhre/knowledge/bhre_relation_engine.dart';

void main() {
  const input =
      'Besok sore tolong ingatkan saya membawa dokumen yang kemarin '
      'saya taruh di meja, karena akan saya berikan ke Pak Arif '
      'di acara Sembukan.';

  const extractor = BhreDetailExtractor();
  const engine = BhreRelationEngine();

  final details = extractor.extract(input);
  final graph = engine.build(input, details);

  if (graph.entities.isEmpty) {
    throw StateError('Knowledge graph tidak memiliki entity.');
  }

  final document = graph.findEntity('dokumen');

  if (document == null) {
    throw StateError('Entity dokumen tidak ditemukan.');
  }

  final relations = graph.relationsFor(document.id);

  bool hasRelation(String relation, String targetValue) {
    for (final item in relations) {
      final targetId = item.subjectId == document.id
          ? item.objectId
          : item.subjectId;

      final target = graph.entities.where(
        (entity) => entity.id == targetId,
      );

      if (target.isEmpty) continue;

      if (item.relation == relation &&
          target.first.value.toLowerCase() ==
              targetValue.toLowerCase()) {
        return true;
      }
    }

    return false;
  }

  if (!hasRelation('berada_di', 'meja')) {
    throw StateError('Relasi dokumen -> meja tidak ditemukan.');
  }

  if (!hasRelation('diberikan_kepada', 'Pak Arif')) {
    throw StateError('Relasi dokumen -> Pak Arif tidak ditemukan.');
  }

  if (!hasRelation('terkait_dengan', 'acara Sembukan')) {
    throw StateError(
      'Relasi dokumen -> acara Sembukan tidak ditemukan.',
    );
  }

  print('BHRE RELATION ENGINE TEST: PASS');
  print('Entities: ${graph.entities.length}');
  print('Relations: ${graph.relations.length}');

  for (final entity in graph.entities) {
    print(
      'ENTITY: ${entity.type.name} -> ${entity.value}',
    );
  }

  for (final relation in graph.relations) {
    final subject = graph.entities.firstWhere(
      (entity) => entity.id == relation.subjectId,
    );

    final object = graph.entities.firstWhere(
      (entity) => entity.id == relation.objectId,
    );

    print(
      'RELATION: ${subject.value} '
      '--${relation.relation}--> '
      '${object.value}',
    );
  }
}
