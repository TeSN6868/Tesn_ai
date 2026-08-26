import 'bhre_reference_scorer.dart';

enum BhreReferenceDecisionType {
  resolved,
  resolvedWithLowConfidence,
  clarificationRequired,
  unresolved,
}

class BhreReferenceDecision {
  final BhreReferenceDecisionType type;
  final BhreReferenceCandidate? candidate;
  final double confidence;
  final String reason;

  const BhreReferenceDecision({
    required this.type,
    required this.candidate,
    required this.confidence,
    required this.reason,
  });

  bool get resolved =>
      type == BhreReferenceDecisionType.resolved ||
      type == BhreReferenceDecisionType.resolvedWithLowConfidence;
}

class BhreReferenceDecisionEngine {
  const BhreReferenceDecisionEngine();

  BhreReferenceDecision decide(
    List<BhreReferenceCandidate> candidates,
  ) {
    if (candidates.isEmpty) {
      return const BhreReferenceDecision(
        type: BhreReferenceDecisionType.unresolved,
        candidate: null,
        confidence: 0.0,
        reason: 'Tidak ada kandidat.',
      );
    }

    final best = candidates.first;

    // Kandidat cukup kuat dan unggul jauh dari kandidat kedua.
    if (best.score >= 0.80) {
      return BhreReferenceDecision(
        type: BhreReferenceDecisionType.resolved,
        candidate: best,
        confidence: best.score,
        reason: 'Confidence tinggi.',
      );
    }

    if (best.score >= 0.55) {
      if (candidates.length == 1) {
        return BhreReferenceDecision(
          type: BhreReferenceDecisionType.resolvedWithLowConfidence,
          candidate: best,
          confidence: best.score,
          reason: 'Satu kandidat dengan confidence sedang.',
        );
      }

      final second = candidates[1];

      if ((best.score - second.score) >= 0.20) {
        return BhreReferenceDecision(
          type: BhreReferenceDecisionType.resolvedWithLowConfidence,
          candidate: best,
          confidence: best.score,
          reason:
              'Kandidat unggul cukup jauh dari kandidat kedua.',
        );
      }

      return BhreReferenceDecision(
        type: BhreReferenceDecisionType.clarificationRequired,
        candidate: best,
        confidence: best.score,
        reason:
            'Kandidat teratas belum cukup unggul.',
      );
    }

    return BhreReferenceDecision(
      type: BhreReferenceDecisionType.clarificationRequired,
      candidate: best,
      confidence: best.score,
      reason: 'Confidence terlalu rendah.',
    );
  }
}
