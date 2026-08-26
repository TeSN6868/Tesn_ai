import '../knowledge/bhre_knowledge_request.dart';
import 'bhre_source_fetch_result.dart';
import 'bhre_source_fetcher.dart';
import 'bhre_source_resolver.dart';

class BhreProviderSourceFetcher implements BhreSourceFetcher {
  const BhreProviderSourceFetcher();

  @override
  Future<BhreSourceFetchResult> fetch({
    required BhreKnowledgeRequest request,
    required BhreResolvedSource source,
  }) async {
    try {
      final records = await source.provider.search(request);

      if (records.isEmpty) {
        return BhreSourceFetchResult.failure(
          sourceId: source.id,
          sourceName: source.name,
          sourceKind: source.kind,
          query: request.query,
          fetchedAt: DateTime.now(),
          error: 'Tidak ada hasil dari sumber.',
        );
      }

      final content = records
          .map((record) => record.content.trim())
          .where((value) => value.isNotEmpty)
          .join('\n\n');

      if (content.isEmpty) {
        return BhreSourceFetchResult.failure(
          sourceId: source.id,
          sourceName: source.name,
          sourceKind: source.kind,
          query: request.query,
          fetchedAt: DateTime.now(),
          error: 'Sumber mengembalikan data tanpa isi.',
        );
      }

      String? uri;

      for (final record in records) {
        if (record.sources.isNotEmpty) {
          final description = record.sources.first.uri?.trim() ?? '';

          if (description.startsWith('http://') ||
              description.startsWith('https://')) {
            uri = description;
            break;
          }
        }
      }

      return BhreSourceFetchResult.success(
        sourceId: source.id,
        sourceName: source.name,
        sourceKind: source.kind,
        query: request.query,
        content: content,
        uri: uri,
        fetchedAt: DateTime.now(),
      );
    } catch (e) {
      return BhreSourceFetchResult.failure(
        sourceId: source.id,
        sourceName: source.name,
        sourceKind: source.kind,
        query: request.query,
        fetchedAt: DateTime.now(),
        error: e.toString(),
      );
    }
  }
}
