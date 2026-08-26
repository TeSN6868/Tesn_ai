import 'bhre_source_evidence.dart';
import 'bhre_source_fetch_result.dart';

class BhreSourceEvidenceCollector {
  const BhreSourceEvidenceCollector();

  List<BhreSourceEvidence> collect(
    List<BhreSourceFetchResult> results,
  ) {
    final evidence = results
        .map(BhreSourceEvidence.fromFetch)
        .where((item) => item.usable)
        .toList();

    return List.unmodifiable(evidence);
  }
}
