import 'knowledge_source.dart';

class BhreKnowledgeResult {
  final String query;
  final String content;
  final BhreKnowledgeSource source;
  final DateTime retrievedAt;
  final double confidence;

  const BhreKnowledgeResult({
    required this.query,
    required this.content,
    required this.source,
    required this.retrievedAt,
    required this.confidence,
  });
}
