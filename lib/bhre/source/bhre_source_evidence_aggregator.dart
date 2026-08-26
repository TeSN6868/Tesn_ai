import '../knowledge/bhre_knowledge_record.dart';
import '../knowledge/bhre_knowledge_source.dart';
import '../knowledge/bhre_knowledge_request.dart';
import 'bhre_source_evaluation.dart';
import 'bhre_source_kind.dart';
import 'bhre_source_plan.dart';

class BhreSourceAggregationException implements Exception {
  final String message;

  const BhreSourceAggregationException(this.message);

  @override
  String toString() => 'BhreSourceAggregationException: $message';
}

class BhreSourceEvidenceAggregator {
  const BhreSourceEvidenceAggregator();

  BhreKnowledgeRecord aggregate({
    required BhreKnowledgeRequest request,
    required BhreSourcePlan plan,
    required List<BhreSourceEvaluation> evaluations,
    DateTime? now,
  }) {
    final usable = evaluations
        .where((evaluation) => evaluation.evidence.usable)
        .toList();

    if (usable.length < plan.minimumSources) {
      throw BhreSourceAggregationException(
        'Evidence tidak mencukupi: '
        '${usable.length}/${plan.minimumSources} source usable.',
      );
    }

    if (plan.requiresVerification &&
        usable.any((evaluation) => !evaluation.verified)) {
      throw const BhreSourceAggregationException(
        'Evidence belum memenuhi syarat verifikasi.',
      );
    }

    if (plan.requiresFreshData &&
        usable.any((evaluation) => !evaluation.fresh)) {
      throw const BhreSourceAggregationException(
        'Evidence belum memenuhi syarat freshness.',
      );
    }

    final sources = usable.map((evaluation) {
      final evidence = evaluation.evidence;

      return BhreKnowledgeSource(
        id: evidence.sourceId,
        name: evidence.sourceName,
        type: _sourceType(evidence.sourceKind),
        uri: evidence.uri,
        confidence: evaluation.confidence,
        verified: evaluation.verified,
      );
    }).toList(growable: false);

    final confidence = usable
        .map((evaluation) => evaluation.confidence)
        .reduce((a, b) => a < b ? a : b);

    final verified = usable.every(
      (evaluation) => evaluation.verified,
    );

    final observedAt = usable
        .map((evaluation) => evaluation.evidence.observedAt)
        .reduce((a, b) => a.isAfter(b) ? a : b);

    final content = usable
        .map((evaluation) => evaluation.evidence.content)
        .join('\n\n');

    return BhreKnowledgeRecord(
      id: _recordId(request.query, now ?? DateTime.now()),
      topic: request.query,
      content: content,
      domain: request.domain,
      sources: sources,
      createdAt: now ?? DateTime.now(),
      observedAt: observedAt,
      confidence: confidence,
      verified: verified,
      generatedBy: 'BHRE_SOURCE_AGGREGATOR',
    );
  }

  BhreKnowledgeSourceType _sourceType(
    BhreSourceKind kind,
  ) {
    switch (kind) {
      case BhreSourceKind.official:
        return BhreKnowledgeSourceType.web;

      case BhreSourceKind.government:
        return BhreKnowledgeSourceType.government;

      case BhreSourceKind.scientific:
        return BhreKnowledgeSourceType.scientific;

      case BhreSourceKind.documentation:
        return BhreKnowledgeSourceType.web;

      case BhreSourceKind.financial:
        return BhreKnowledgeSourceType.database;

      case BhreSourceKind.news:
        return BhreKnowledgeSourceType.news;

      case BhreSourceKind.reference:
        return BhreKnowledgeSourceType.knowledgeGraph;

      case BhreSourceKind.generalWeb:
        return BhreKnowledgeSourceType.web;
    }
  }

  String _recordId(String query, DateTime timestamp) {
    return 'bhre-${timestamp.microsecondsSinceEpoch}-'
        '${query.hashCode}';
  }
}
