import '../detail/bhre_detail.dart';
import 'bhre_reference_decision.dart';
import 'bhre_relation_engine.dart';

class BhreUnderstanding {
  final String input;
  final List<BhreDetail> details;
  final BhreKnowledgeGraph graph;
  final List<BhreReferenceDecision> referenceDecisions;

  const BhreUnderstanding({
    required this.input,
    required this.details,
    required this.graph,
    this.referenceDecisions = const [],
  });

  bool get hasAmbiguity {
    return referenceDecisions.any(
      (decision) =>
          decision.type == BhreReferenceDecisionType.clarificationRequired,
    );
  }

  bool get hasResolvedReference {
    return referenceDecisions.any((decision) => decision.resolved);
  }
}
