import '../lib/bhre/detail/bhre_detail_extractor.dart';
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

  final details = extractor.extract(input);
  final graph = relationEngine.build(input, details);

  final candidates = scorer.score(
    reference: 'yang itu',
    graph: graph,
    expectedType: BhreEntityType.object,
    relatedEntity: 'Pak Arif',
  );

  if (candidates.isEmpty) {
    throw StateError(
      'Reference scorer tidak menghasilkan kandidat.',
    );
  }

  final first = candidates.first;

  if (first.entity.value.toLowerCase() != 'dokumen') {
    throw StateError(
      'Kandidat teratas bukan dokumen: '
      '${first.entity.value}',
    );
  }

  if (first.score <= 0.5) {
    throw StateError(
      'Score kandidat terlalu rendah: ${first.score}',
    );
  }

  print('BHRE REFERENCE SCORING TEST: PASS');
  print('Reference: yang itu');
  print('Related entity: Pak Arif');

  for (final candidate in candidates) {
    print('CANDIDATE: $candidate');
  }
}
