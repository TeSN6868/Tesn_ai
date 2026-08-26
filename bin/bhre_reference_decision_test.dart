import '../lib/bhre/detail/bhre_detail_extractor.dart';
import '../lib/bhre/knowledge/bhre_reference_decision.dart';
import '../lib/bhre/knowledge/bhre_reference_scorer.dart';
import '../lib/bhre/knowledge/bhre_relation.dart';
import '../lib/bhre/knowledge/bhre_relation_engine.dart';

void main() {
  const input =
      'Kemarin saya menaruh dokumen di meja untuk diberikan '
      'kepada Pak Arif di acara Sembukan.';

  const extractor = BhreDetailExtractor();
  const relationEngine = BhreRelationEngine();
  const scorer = BhreReferenceScorer();
  const decisionEngine = BhreReferenceDecisionEngine();

  final details = extractor.extract(input);

  final graph = relationEngine.build(
    input,
    details,
  );

  final candidates = scorer.score(
    reference: 'yang itu',
    graph: graph,
    expectedType: BhreEntityType.object,
    relatedEntity: 'Pak Arif',
  );

  final decision = decisionEngine.decide(candidates);

  if (decision.type !=
      BhreReferenceDecisionType.resolvedWithLowConfidence) {
    throw StateError(
      'Decision tidak sesuai: ${decision.type}',
    );
  }

  if (decision.candidate?.entity.value != 'dokumen') {
    throw StateError(
      'Kandidat keputusan bukan dokumen.',
    );
  }

  print('BHRE REFERENCE DECISION TEST: PASS');
  print('Decision: ${decision.type}');
  print('Candidate: ${decision.candidate?.entity.value}');
  print(
    'Confidence: '
    '${decision.confidence.toStringAsFixed(3)}',
  );
  print('Reason: ${decision.reason}');
}
