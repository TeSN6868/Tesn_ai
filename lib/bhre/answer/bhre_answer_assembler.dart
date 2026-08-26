import '../knowledge/bhre_knowledge_candidate.dart';
import 'bhre_answer.dart';

class BhreAnswerAssembler {
  const BhreAnswerAssembler();

  BhreAnswer assemble({
    required String query,
    required List<BhreKnowledgeCandidate> candidates,
    required String answer,
    DateTime? now,
  }) {
    if (query.trim().isEmpty) {
      throw ArgumentError.value(
        query,
        'query',
        'Query tidak boleh kosong.',
      );
    }

    if (answer.trim().isEmpty) {
      throw ArgumentError.value(
        answer,
        'answer',
        'Answer tidak boleh kosong.',
      );
    }

    if (candidates.isEmpty) {
      throw StateError(
        'Tidak ada knowledge candidate untuk membentuk jawaban.',
      );
    }

    final knowledge = candidates
        .map((candidate) => candidate.record)
        .toList(growable: false);

    final confidence = candidates
        .map((candidate) => candidate.score)
        .reduce((a, b) => a > b ? a : b)
        .clamp(0.0, 1.0);

    final verified = knowledge.every(
      (record) => record.verified,
    );

    return BhreAnswer(
      query: query,
      answer: answer,
      domain: knowledge.first.domain,
      confidence: confidence,
      verified: verified,
      knowledge: knowledge,
      generatedAt: now ?? DateTime.now(),
    );
  }
}
