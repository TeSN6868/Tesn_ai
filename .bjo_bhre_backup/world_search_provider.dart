import 'dart:convert';

import '../connectivity/network/bhre_http_client.dart';
import 'knowledge_provider.dart';
import 'knowledge_result.dart';
import 'knowledge_source.dart';
import 'world_search_request.dart';

class BhreWorldSearchProvider implements BhreKnowledgeProvider {
  final BhreHttpClient httpClient;

  BhreWorldSearchProvider({required this.httpClient});

  @override
  String get id => 'world_search';

  @override
  Future<List<BhreKnowledgeResult>> search(String query) async {
    final request = BhreWorldSearchRequest(query: query);
    final normalized = request.query.trim();

    if (normalized.isEmpty) {
      return const [];
    }

    try {
      final encoded = Uri.encodeQueryComponent(normalized);

      final response = await httpClient.get('/api/world-search?q=$encoded');

      if (!response.isSuccess || response.body.trim().isEmpty) {
        return const [];
      }

      final decoded = _decodeJson(response.body);

      if (decoded is! Map) {
        return const [];
      }

      final rawResults = decoded['results'];

      if (rawResults is! List) {
        return const [];
      }

      final now = DateTime.now();
      final results = <BhreKnowledgeResult>[];

      for (final raw in rawResults) {
        if (raw is! Map) continue;

        final title = (raw['title'] ?? 'Pengetahuan dunia').toString().trim();

        final content = (raw['content'] ?? raw['snippet'] ?? '')
            .toString()
            .trim();

        final sourceName = (raw['source'] ?? 'World Search').toString().trim();

        if (content.isEmpty) continue;

        results.add(
          BhreKnowledgeResult(
            query: normalized,
            content: title.isEmpty ? content : '$title\n$content',
            source: BhreKnowledgeSource(
              id: sourceName.isEmpty ? 'world_search' : sourceName,
              name: sourceName.isEmpty ? 'World Search' : sourceName,
              description: 'Sumber pengetahuan dunia dari pencarian web.',
            ),
            retrievedAt: now,
            confidence: 0.8,
          ),
        );
      }

      return List.unmodifiable(results);
    } catch (_) {
      return const [];
    }
  }

  dynamic _decodeJson(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }
}
