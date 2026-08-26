import 'bhre_knowledge_record.dart';

class BhreKnowledgeCandidate {
  final BhreKnowledgeRecord record;
  final double score;
  final List<String> reasons;

  const BhreKnowledgeCandidate({
    required this.record,
    required this.score,
    this.reasons = const [],
  });

  @override
  String toString() {
    return 'BhreKnowledgeCandidate('
        'id: ${record.id}, '
        'score: $score, '
        'reasons: $reasons'
        ')';
  }
}
