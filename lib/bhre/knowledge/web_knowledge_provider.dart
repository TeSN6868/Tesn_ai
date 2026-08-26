import 'knowledge_provider.dart';
import 'knowledge_result.dart';
import 'knowledge_source.dart';

class BhreWebKnowledgeProvider implements BhreKnowledgeProvider {
  @override
  String get id => 'web';

  @override
  Future<List<BhreKnowledgeResult>> search(String query) async {
    // Network retrieval akan dipasang pada integration layer.
    return [
      BhreKnowledgeResult(
        query: query,
        content: '',
        source: const BhreKnowledgeSource(
          id: 'web',
          name: 'World Web',
          description: 'External web knowledge source.',
        ),
        retrievedAt: DateTime.now(),
        confidence: 0,
      ),
    ];
  }
}
