import '../knowledge/bhre_knowledge_request.dart';
import 'bhre_source_fetch_result.dart';
import 'bhre_source_resolver.dart';

abstract interface class BhreSourceFetcher {
  Future<BhreSourceFetchResult> fetch({
    required BhreKnowledgeRequest request,
    required BhreResolvedSource source,
  });
}
