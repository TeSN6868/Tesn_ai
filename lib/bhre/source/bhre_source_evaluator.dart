import 'bhre_source_evidence.dart';
import 'bhre_source_evaluation.dart';

class BhreSourceEvaluator {
  const BhreSourceEvaluator();

  BhreSourceEvaluation evaluate(BhreSourceEvidence evidence, {DateTime? now}) {
    final currentTime = now ?? DateTime.now();

    final age = currentTime.difference(evidence.observedAt);
    final fresh = evidence.usable && age.inHours <= 24;

    final confidence = evidence.usable ? (fresh ? 1.0 : 0.75) : 0.0;

    final verified = evidence.usable && confidence >= 0.75;

    return BhreSourceEvaluation(
      evidence: evidence,
      confidence: confidence,
      verified: verified,
      fresh: fresh,
      reason: evidence.usable
          ? (fresh
                ? 'Evidence usable dan masih fresh.'
                : 'Evidence usable tetapi sudah tidak fresh.')
          : 'Evidence tidak usable.',
    );
  }
}
