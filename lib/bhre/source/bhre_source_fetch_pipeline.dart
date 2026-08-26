import '../knowledge/bhre_knowledge_request.dart';
import 'bhre_source_fetch_result.dart';
import 'bhre_source_fetcher.dart';
import 'bhre_source_resolver.dart';

class BhreSourceFetchPipeline {
  final BhreSourceFetcher fetcher;

  const BhreSourceFetchPipeline({required this.fetcher});

  Future<List<BhreSourceFetchResult>> fetchAll({
    required BhreKnowledgeRequest request,
    required List<BhreResolvedSource> sources,
  }) async {
    final results = <BhreSourceFetchResult>[];

    for (final source in sources) {
      final result = await fetcher.fetch(request: request, source: source);

      results.add(result);
    }

    return List.unmodifiable(results);
  }
}
