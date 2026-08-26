import 'bhre_source_fetch_result.dart';
import 'bhre_source_kind.dart';

class BhreSourceEvidence {
  final String sourceId;
  final String sourceName;
  final BhreSourceKind sourceKind;
  final String query;
  final String content;
  final String? uri;
  final DateTime observedAt;
  final bool usable;

  const BhreSourceEvidence({
    required this.sourceId,
    required this.sourceName,
    required this.sourceKind,
    required this.query,
    required this.content,
    required this.observedAt,
    this.uri,
    this.usable = true,
  });

  factory BhreSourceEvidence.fromFetch(
    BhreSourceFetchResult result,
  ) {
    return BhreSourceEvidence(
      sourceId: result.sourceId,
      sourceName: result.sourceName,
      sourceKind: result.sourceKind,
      query: result.query,
      content: result.content ?? '',
      uri: result.uri,
      observedAt: result.fetchedAt,
      usable: result.success &&
          result.content != null &&
          result.content!.trim().isNotEmpty,
    );
  }

  @override
  String toString() {
    return 'BhreSourceEvidence('
        'sourceId: $sourceId, '
        'sourceName: $sourceName, '
        'usable: $usable, '
        'observedAt: $observedAt'
        ')';
  }
}
