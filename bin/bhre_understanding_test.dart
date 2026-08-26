import '../lib/bhre/knowledge/bhre_reference_decision.dart';
import '../lib/bhre/knowledge/bhre_understanding_engine.dart';

void main() {
  const input =
      'Besok sore tolong ingatkan saya membawa dokumen '
      'yang kemarin saya taruh di meja, karena akan saya '
      'berikan ke Pak Arif di acara Sembukan.';

  const engine = BhreUnderstandingEngine();

  final result = engine.understand(input);

  if (result.details.isEmpty) {
    throw StateError(
      'Understanding tidak menghasilkan detail.',
    );
  }

  if (result.graph.entities.isEmpty) {
    throw StateError(
      'Understanding tidak menghasilkan entity.',
    );
  }

  if (result.graph.relations.isEmpty) {
    throw StateError(
      'Understanding tidak menghasilkan relation.',
    );
  }

  print('BHRE UNDERSTANDING ENGINE TEST: PASS');

  print('');
  print('INPUT: $input');

  print('');
  print('DETAILS:');
  for (final detail in result.details) {
    print(
      '- ${detail.type.name}: '
      '${detail.value} '
      '(confidence=${detail.confidence})',
    );
  }

  print('');
  print('ENTITIES:');
  for (final entity in result.graph.entities) {
    print(
      '- ${entity.type.name}: ${entity.value}',
    );
  }

  print('');
  print('RELATIONS:');
  for (final relation in result.graph.relations) {
    final subject = result.graph.entities.firstWhere(
      (entity) => entity.id == relation.subjectId,
    );

    final object = result.graph.entities.firstWhere(
      (entity) => entity.id == relation.objectId,
    );

    print(
      '- ${subject.value} '
      '--${relation.relation}--> '
      '${object.value}',
    );
  }

  print('');
  print('REFERENCE DECISIONS:');

  for (final decision in result.referenceDecisions) {
    print(
      '- ${decision.type.name}: '
      '${decision.candidate?.entity.value ?? "UNRESOLVED"} '
      '(confidence=${decision.confidence})',
    );
  }

  if (result.referenceDecisions.isEmpty) {
    print('- Tidak ada reference yang perlu diselesaikan.');
  }

  final hasDecision = result.referenceDecisions.any(
    (decision) =>
        decision.type ==
        BhreReferenceDecisionType.resolvedWithLowConfidence,
  );

  if (!hasDecision) {
    throw StateError(
      'Reference decision belum terbentuk sesuai harapan.',
    );
  }
}
