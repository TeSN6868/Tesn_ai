import 'bhre_knowledge_record.dart';
import 'bhre_knowledge_request.dart';
import '../source/bhre_source_evaluation.dart';

class BhreKnowledgeAggregator {
  const BhreKnowledgeAggregator();

  BhreKnowledgeRecord aggregate({
    required BhreKnowledgeRequest request,
    required List<BhreSourceEvaluation> evaluations,
    DateTime? now,
  }) {
    final observed = evaluations
        .where((evaluation) => evaluation.verified)
        .toList();

    if (observed.isEmpty) {
      return BhreKnowledgeRecord(
        id: 'bhre-${request.query.hashCode}',
        topic: request.query,
        content: '',
        domain: request.domain,
        createdAt: now ?? DateTime.now(),
        observedAt: null,
        confidence: 0.0,
        verified: false,
        generatedBy: 'Bree',
      );
    }

    final contents = observed
        .map((evaluation) => evaluation.evidence.content.trim())
        .where((content) => content.isNotEmpty)
        .toList();

    final averageConfidence =
        observed
            .map((evaluation) => evaluation.confidence)
            .reduce((a, b) => a + b) /
        observed.length;

    final latestObservedAt = observed
        .map((evaluation) => evaluation.evidence.observedAt)
        .reduce((a, b) => a.isAfter(b) ? a : b);

    return BhreKnowledgeRecord(
      id: 'bhre-${request.query.hashCode}',
      topic: request.query,
      content: contents.join('\n\n'),
      domain: request.domain,
      sources:
          observed
              .map((evaluation) => evaluation.evidence.sourceId)
              .map(
                (id) => observed
                    .firstWhere(
                      (evaluation) => evaluation.evidence.sourceId == id,
                    )
                    .evidence,
              )
              .map((evidence) => evidence.sourceId)
              .isEmpty
          ? const []
          : const [],
      createdAt: now ?? DateTime.now(),
      observedAt: latestObservedAt,
      confidence: averageConfidence,
      verified: true,
      generatedBy: 'Bree',
    );
  }
}
