import 'bhre_knowledge_candidate.dart';
import 'bhre_knowledge_domain.dart';
import 'bhre_knowledge_record.dart';
import 'bhre_knowledge_store.dart';

class BhreKnowledgeRetriever {
  final BhreKnowledgeStore store;

  const BhreKnowledgeRetriever({
    required this.store,
  });

  Future<List<BhreKnowledgeCandidate>> retrieve({
    required String query,
    BhreKnowledgeDomain? domain,
    int limit = 5,
  }) async {
    final normalizedQuery = query.trim().toLowerCase();

    if (normalizedQuery.isEmpty || limit <= 0) {
      return const [];
    }

    final records = domain != null
        ? await store.findByDomain(domain)
        : await store.search(normalizedQuery);

    final candidates = <BhreKnowledgeCandidate>[];

    for (final record in records) {
      final candidate = _rank(
        record,
        normalizedQuery,
        domain,
      );

      if (candidate != null) {
        candidates.add(candidate);
      }
    }

    candidates.sort(
      (a, b) => b.score.compareTo(a.score),
    );

    if (candidates.length <= limit) {
      return List.unmodifiable(candidates);
    }

    return List.unmodifiable(
      candidates.take(limit),
    );
  }

  BhreKnowledgeCandidate? _rank(
    BhreKnowledgeRecord record,
    String query,
    BhreKnowledgeDomain? domain,
  ) {
    final topic = record.topic.toLowerCase();
    final content = record.content.toLowerCase();

    var score = 0.0;
    final reasons = <String>[];

    if (topic == query) {
      score += 0.50;
      reasons.add('exact_topic');
    } else if (topic.contains(query)) {
      score += 0.35;
      reasons.add('topic_match');
    }

    if (content.contains(query)) {
      score += 0.20;
      reasons.add('content_match');
    }

    if (domain != null && record.domain == domain) {
      score += 0.15;
      reasons.add('domain_match');
    }

    if (record.verified) {
      score += 0.10;
      reasons.add('verified');
    }

    score += record.confidence.clamp(0.0, 1.0) * 0.05;

    if (record.confidence > 0) {
      reasons.add('confidence');
    }

    if (score <= 0) {
      return null;
    }

    return BhreKnowledgeCandidate(
      record: record,
      score: score,
      reasons: List.unmodifiable(reasons),
    );
  }
}
