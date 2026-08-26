import 'bhre_relation.dart';
import 'bhre_relation_engine.dart';

class BhreReferenceCandidate {
  final BhreEntity entity;
  final double score;
  final List<String> reasons;

  const BhreReferenceCandidate({
    required this.entity,
    required this.score,
    this.reasons = const [],
  });

  @override
  String toString() {
    return '${entity.value} '
        '(score=${score.toStringAsFixed(3)} '
        '${reasons.join(", ")})';
  }
}

class BhreReferenceScorer {
  const BhreReferenceScorer();

  List<BhreReferenceCandidate> score({
    required String reference,
    required BhreKnowledgeGraph graph,
    BhreEntityType? expectedType,
    String? relatedEntity,
  }) {
    final candidates = <BhreReferenceCandidate>[];

    for (final entity in graph.entities) {
      if (expectedType != null && entity.type != expectedType) {
        continue;
      }

      var score = entity.confidence * 0.35;
      final reasons = <String>['base-confidence'];

      final normalizedReference = reference.toLowerCase().trim();

      final normalizedValue = entity.value.toLowerCase().trim();

      // Referensi langsung.
      if (normalizedReference == normalizedValue) {
        score += 0.45;
        reasons.add('exact-match');
      }

      // Referensi temporal.
      if (normalizedReference.contains('kemarin') &&
          entity.type == BhreEntityType.date &&
          normalizedValue == 'kemarin') {
        score += 0.25;
        reasons.add('temporal-match');
      }

      if (normalizedReference.contains('besok') &&
          entity.type == BhreEntityType.date &&
          normalizedValue == 'besok') {
        score += 0.25;
        reasons.add('temporal-match');
      }

      // Hubungan dengan entity yang sedang dibicarakan.
      if (relatedEntity != null) {
        final related = graph.findEntity(relatedEntity);

        if (related != null) {
          final connected = graph.relations.any((relation) {
            final connectsSubject =
                relation.subjectId == entity.id &&
                relation.objectId == related.id;

            final connectsObject =
                relation.objectId == entity.id &&
                relation.subjectId == related.id;

            return connectsSubject || connectsObject;
          });

          if (connected) {
            score += 0.30;
            reasons.add('relationship-match');
          }
        }
      }

      candidates.add(
        BhreReferenceCandidate(
          entity: entity,
          score: score.clamp(0.0, 1.0),
          reasons: List.unmodifiable(reasons),
        ),
      );
    }

    candidates.sort((a, b) => b.score.compareTo(a.score));

    return List.unmodifiable(candidates);
  }
}
