import '../connectivity/network/bhre_http_client.dart';
import 'knowledge_provider.dart';
import 'knowledge_result.dart';
import 'world_search_request.dart';

class BhreWorldSearchProvider implements BhreKnowledgeProvider {
  final BhreHttpClient httpClient;

  BhreWorldSearchProvider({
    required this.httpClient,
  });

  @override
  String get id => 'world_search';

  @override
  Future<List<BhreKnowledgeResult>> search(String query) async {
    final request = BhreWorldSearchRequest(query: query);

    if (request.query.trim().isEmpty) {
      return const [];
    }

    // Endpoint pencarian dunia akan dipasang pada integration layer.
    return const [];
  }
}
