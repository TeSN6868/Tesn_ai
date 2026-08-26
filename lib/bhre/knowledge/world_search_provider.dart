import 'dart:convert';

import '../connectivity/network/bhre_http_client.dart';
import '../source/bhre_source_kind.dart';
import 'bhre_knowledge_provider.dart';
import 'bhre_knowledge_record.dart';
import 'bhre_knowledge_request.dart';
import 'bhre_knowledge_source.dart';
import 'world_search_request.dart';

class BhreWorldSearchProvider implements BhreKnowledgeProvider {
  final BhreHttpClient httpClient;

  BhreWorldSearchProvider({required this.httpClient});

  @override
  String get id => 'world_search';

  @override
  String get name => 'World Search';

  @override
  BhreSourceKind get sourceKind => BhreSourceKind.generalWeb;

  @override
  bool supports(BhreKnowledgeRequest request) {
    return true;
  }

  @override
  Future<List<BhreKnowledgeRecord>> search(BhreKnowledgeRequest request) async {
    final worldRequest = BhreWorldSearchRequest(query: request.query);
    final normalized = worldRequest.query.trim();

    if (normalized.isEmpty) {
      return const [];
    }

    try {
      final encoded = Uri.encodeQueryComponent(normalized);

      final response = await httpClient.get('/api/world-search?q=$encoded');

      if (!response.isSuccess || response.body.trim().isEmpty) {
        return const [];
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! Map) {
        return const [];
      }

      final rawResults = decoded['results'];

      if (rawResults is! List) {
        return const [];
      }

      final now = DateTime.now();
      final results = <BhreKnowledgeRecord>[];

      var index = 0;

      for (final raw in rawResults) {
        if (raw is! Map) continue;

        final title = (raw['title'] ?? 'Pengetahuan dunia').toString().trim();

        final content =
            (raw['content'] ?? raw['snippet'] ?? raw['description'] ?? '')
                .toString()
                .trim();

        final sourceName = (raw['source'] ?? 'World Search').toString().trim();

        if (content.isEmpty) continue;

        final fullContent = title.isEmpty ? content : '$title\n$content';

        results.add(
          BhreKnowledgeRecord(
            id: 'world_search_${now.microsecondsSinceEpoch}_$index',
            topic: title.isEmpty ? normalized : title,
            content: fullContent,
            domain: request.domain,
            sources: [
              BhreKnowledgeSource(
                id: sourceName.isEmpty ? 'world_search' : sourceName,
                type: BhreKnowledgeSourceType.web,
                name: sourceName.isEmpty ? 'World Search' : sourceName,
              ),
            ],
            createdAt: now,
            observedAt: now,
            confidence: 0.8,
            verified: false,
            generatedBy: 'BhreWorldSearchProvider',
          ),
        );

        index++;
      }

      return List.unmodifiable(results);
    } catch (_) {
      return const [];
    }
  }
}
