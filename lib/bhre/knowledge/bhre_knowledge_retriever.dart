import 'bhre_knowledge_candidate.dart';
import 'bhre_knowledge_domain.dart';
import 'bhre_knowledge_record.dart';
import 'bhre_knowledge_store.dart';

class BhreKnowledgeRetriever {
  final BhreKnowledgeStore store;

  const BhreKnowledgeRetriever({required this.store});

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
      final candidate = _rank(record, normalizedQuery, domain);

      if (candidate != null) {
        candidates.add(candidate);
      }
    }

    candidates.sort((a, b) => b.score.compareTo(a.score));

    if (candidates.length <= limit) {
      return List.unmodifiable(candidates);
    }

    return List.unmodifiable(candidates.take(limit));
  }

  BhreKnowledgeCandidate? _rank(
    BhreKnowledgeRecord record,
    String query,
    BhreKnowledgeDomain? domain,
  ) {
    final topic = record.topic.toLowerCase();
    final content = record.content.toLowerCase();

    var score = 0.0;
    final reasons = <String>{};

    // Exact full-query match remains strongest.
    if (topic == query) {
      score += 0.60;
      reasons.add('exact_topic');
    } else if (topic.contains(query)) {
      score += 0.45;
      reasons.add('topic_match');
    }

    if (content.contains(query)) {
      score += 0.30;
      reasons.add('content_match');
    }

    // Domain relevance.
    if (domain != null && record.domain == domain) {
      score += 0.20;
      reasons.add('domain_match');
    }

    // Smart token matching.
    //
    // Example:
    // "bagaimana cara melakukan analisis forensik digital?"
    //
    // Tidak harus ada seluruh kalimat tersebut di knowledge.
    // Cukup kata-kata pentingnya ditemukan pada topic/content.
    final tokens = _keywords(query);

    var matchedTokens = 0;

    for (final token in tokens) {
      final inTopic = topic.contains(token);
      final inContent = content.contains(token);

      if (inTopic) {
        score += 0.12;
        matchedTokens++;
        reasons.add('keyword_topic');
      } else if (inContent) {
        score += 0.07;
        matchedTokens++;
        reasons.add('keyword_content');
      }
    }

    if (tokens.isNotEmpty && matchedTokens > 0) {
      final coverage = matchedTokens / tokens.length;
      score += coverage * 0.20;
      reasons.add('keyword_coverage');
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

  List<String> _keywords(String query) {
    const stopWords = {
      'apa',
      'itu',
      'yang',
      'dan',
      'atau',
      'di',
      'ke',
      'dari',
      'untuk',
      'dengan',
      'pada',
      'dalam',
      'ini',
      'itu',
      'saya',
      'aku',
      'bisa',
      'bagaimana',
      'mengapa',
      'kenapa',
      'jelaskan',
      'jelasin',
      'tolong',
      'mohon',
      'caranya',
      'cara',
      'kah',
      'ya',
      'dong',
    };

    final normalized = query.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9\s]'),
      ' ',
    );

    return normalized
        .split(RegExp(r'\s+'))
        .map((word) => word.trim())
        .where((word) => word.length >= 3 && !stopWords.contains(word))
        .toSet()
        .toList();
  }
}
