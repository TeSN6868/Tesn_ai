import '../knowledge/bhre_knowledge_domain.dart';
import '../knowledge/bhre_knowledge_record.dart';

class BhreAnswer {
  final String query;
  final String answer;
  final BhreKnowledgeDomain domain;
  final double confidence;
  final bool verified;
  final List<BhreKnowledgeRecord> knowledge;
  final DateTime generatedAt;
  final String generatedBy;

  const BhreAnswer({
    required this.query,
    required this.answer,
    required this.domain,
    required this.confidence,
    required this.verified,
    required this.knowledge,
    required this.generatedAt,
    this.generatedBy = 'Bree_ANSWER_ASSEMBLER',
  });

  @override
  String toString() {
    return 'BhreAnswer('
        'query: "$query", '
        'domain: $domain, '
        'confidence: $confidence, '
        'verified: $verified, '
        'knowledge: ${knowledge.length}, '
        'generatedBy: $generatedBy'
        ')';
  }
}
