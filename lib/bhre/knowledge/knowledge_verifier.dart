import 'knowledge_result.dart';
import 'knowledge_verification.dart';

class BhreKnowledgeVerifier {
  BhreKnowledgeVerification verify(
    String query,
    List<BhreKnowledgeResult> results,
  ) {
    if (results.isEmpty) {
      return BhreKnowledgeVerification(
        query: query,
        sources: const [],
        confidence: 0,
        hasConflictingInformation: false,
      );
    }

    final averageConfidence =
        results.map((e) => e.confidence).reduce((a, b) => a + b) /
        results.length;

    return BhreKnowledgeVerification(
      query: query,
      sources: results,
      confidence: averageConfidence.clamp(0.0, 1.0),
      hasConflictingInformation: false,
    );
  }
}
