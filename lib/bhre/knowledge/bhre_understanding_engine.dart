import '../detail/bhre_detail.dart';
import '../detail/bhre_detail_extractor.dart';
import 'bhre_reference_decision.dart';
import 'bhre_reference_scorer.dart';
import 'bhre_relation_engine.dart';
import 'bhre_understanding.dart';

class BhreUnderstandingEngine {
  final BhreDetailExtractor detailExtractor;
  final BhreRelationEngine relationEngine;
  final BhreReferenceScorer referenceScorer;
  final BhreReferenceDecisionEngine decisionEngine;

  const BhreUnderstandingEngine({
    this.detailExtractor = const BhreDetailExtractor(),
    this.relationEngine = const BhreRelationEngine(),
    this.referenceScorer = const BhreReferenceScorer(),
    this.decisionEngine = const BhreReferenceDecisionEngine(),
  });

  BhreUnderstanding understand(String input) {
    final details = detailExtractor.extract(input);

    final graph = relationEngine.build(input, details);

    final decisions = <BhreReferenceDecision>[];

    for (final detail in details) {
      if (detail.type != BhreDetailType.reference) {
        continue;
      }

      final candidates = referenceScorer.score(
        reference: detail.value,
        graph: graph,
      );

      final decision = decisionEngine.decide(candidates);

      decisions.add(decision);
    }

    return BhreUnderstanding(
      input: input,
      details: details,
      graph: graph,
      referenceDecisions: List.unmodifiable(decisions),
    );
  }
}
