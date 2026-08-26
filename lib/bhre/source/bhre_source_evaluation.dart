import 'bhre_source_evidence.dart';

class BhreSourceEvaluation {
  final BhreSourceEvidence evidence;
  final double confidence;
  final bool verified;
  final bool fresh;
  final String reason;

  const BhreSourceEvaluation({
    required this.evidence,
    required this.confidence,
    required this.verified,
    required this.fresh,
    required this.reason,
  });

  @override
  String toString() {
    return 'BhreSourceEvaluation('
        'sourceId: ${evidence.sourceId}, '
        'confidence: $confidence, '
        'verified: $verified, '
        'fresh: $fresh, '
        'reason: "$reason"'
        ')';
  }
}
