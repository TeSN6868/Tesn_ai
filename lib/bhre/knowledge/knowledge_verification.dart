import 'knowledge_result.dart';

class BhreKnowledgeVerification {
  final String query;
  final List<BhreKnowledgeResult> sources;
  final double confidence;
  final bool hasConflictingInformation;

  const BhreKnowledgeVerification({
    required this.query,
    required this.sources,
    required this.confidence,
    required this.hasConflictingInformation,
  });
}
