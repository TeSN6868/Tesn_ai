import 'bhre_source_kind.dart';

class BhreSourceFetchResult {
  final String sourceId;
  final String sourceName;
  final BhreSourceKind sourceKind;
  final String query;

  final bool success;

  final String? content;
  final String? uri;

  final DateTime fetchedAt;

  final String? error;

  const BhreSourceFetchResult({
    required this.sourceId,
    required this.sourceName,
    required this.sourceKind,
    required this.query,
    required this.success,
    required this.fetchedAt,
    this.content,
    this.uri,
    this.error,
  });

  factory BhreSourceFetchResult.success({
    required String sourceId,
    required String sourceName,
    required BhreSourceKind sourceKind,
    required String query,
    required String content,
    String? uri,
    required DateTime fetchedAt,
  }) {
    return BhreSourceFetchResult(
      sourceId: sourceId,
      sourceName: sourceName,
      sourceKind: sourceKind,
      query: query,
      success: true,
      content: content,
      uri: uri,
      fetchedAt: fetchedAt,
    );
  }

  factory BhreSourceFetchResult.failure({
    required String sourceId,
    required String sourceName,
    required BhreSourceKind sourceKind,
    required String query,
    required DateTime fetchedAt,
    required String error,
  }) {
    return BhreSourceFetchResult(
      sourceId: sourceId,
      sourceName: sourceName,
      sourceKind: sourceKind,
      query: query,
      success: false,
      fetchedAt: fetchedAt,
      error: error,
    );
  }

  @override
  String toString() {
    return 'BhreSourceFetchResult('
        'sourceId: $sourceId, '
        'sourceName: $sourceName, '
        'success: $success, '
        'uri: $uri, '
        'fetchedAt: $fetchedAt, '
        'error: $error'
        ')';
  }
}
