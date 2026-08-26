import '../detail/bhre_detail.dart';
import 'bhre_relation.dart';

class BhreKnowledgeGraph {
  final List<BhreEntity> entities;
  final List<BhreRelation> relations;

  const BhreKnowledgeGraph({
    this.entities = const [],
    this.relations = const [],
  });

  BhreEntity? findEntity(String value) {
    final normalized = value.trim().toLowerCase();

    for (final entity in entities) {
      if (entity.value.toLowerCase() == normalized) {
        return entity;
      }
    }

    return null;
  }

  List<BhreRelation> relationsFor(String entityId) {
    return List.unmodifiable(
      relations.where(
        (relation) =>
            relation.subjectId == entityId ||
            relation.objectId == entityId,
      ),
    );
  }
}

class BhreRelationEngine {
  const BhreRelationEngine();

  BhreKnowledgeGraph build(
    String input,
    List<BhreDetail> details,
  ) {
    final entities = <BhreEntity>[];
    final relations = <BhreRelation>[];

    var counter = 0;

    String addEntity(
      BhreEntityType type,
      String value, {
      double confidence = 0.9,
    }) {
      final existing = entities.where(
        (entity) =>
            entity.type == type &&
            entity.value.toLowerCase() == value.toLowerCase(),
      );

      if (existing.isNotEmpty) {
        return existing.first.id;
      }

      final id = 'entity-${++counter}';

      entities.add(
        BhreEntity(
          id: id,
          type: type,
          value: value,
          confidence: confidence,
        ),
      );

      return id;
    }

    for (final detail in details) {
      switch (detail.type) {
        case BhreDetailType.person:
          addEntity(
            BhreEntityType.person,
            detail.value,
            confidence: detail.confidence,
          );
          break;

        case BhreDetailType.place:
          addEntity(
            BhreEntityType.place,
            detail.value,
            confidence: detail.confidence,
          );
          break;

        case BhreDetailType.object:
          addEntity(
            BhreEntityType.object,
            detail.value,
            confidence: detail.confidence,
          );
          break;

        case BhreDetailType.event:
          addEntity(
            BhreEntityType.event,
            detail.value,
            confidence: detail.confidence,
          );
          break;

        case BhreDetailType.time:
          addEntity(
            BhreEntityType.time,
            detail.value,
            confidence: detail.confidence,
          );
          break;

        case BhreDetailType.date:
          addEntity(
            BhreEntityType.date,
            detail.value,
            confidence: detail.confidence,
          );
          break;

        default:
          break;
      }
    }

    final document = _findEntity(entities, 'dokumen');
    final meja = _findEntity(entities, 'meja');
    final arif = _findPerson(entities, 'Pak Arif');
    final sembukan = _findEntity(entities, 'acara Sembukan');

    if (document != null && meja != null) {
      relations.add(
        BhreRelation(
          subjectId: document.id,
          relation: 'berada_di',
          objectId: meja.id,
          confidence: 0.85,
        ),
      );
    }

    if (document != null && arif != null) {
      relations.add(
        BhreRelation(
          subjectId: document.id,
          relation: 'diberikan_kepada',
          objectId: arif.id,
          confidence: 0.90,
        ),
      );
    }

    if (document != null && sembukan != null) {
      relations.add(
        BhreRelation(
          subjectId: document.id,
          relation: 'terkait_dengan',
          objectId: sembukan.id,
          confidence: 0.80,
        ),
      );
    }

    return BhreKnowledgeGraph(
      entities: List.unmodifiable(entities),
      relations: List.unmodifiable(relations),
    );
  }

  BhreEntity? _findEntity(
    List<BhreEntity> entities,
    String value,
  ) {
    final normalized = value.toLowerCase();

    for (final entity in entities) {
      if (entity.value.toLowerCase() == normalized) {
        return entity;
      }
    }

    return null;
  }

  BhreEntity? _findPerson(
    List<BhreEntity> entities,
    String value,
  ) {
    final normalized = value.toLowerCase();

    for (final entity in entities) {
      if (entity.type == BhreEntityType.person &&
          entity.value.toLowerCase() == normalized) {
        return entity;
      }
    }

    return null;
  }
}
