import 'knowledge_provider.dart';
import 'knowledge_result.dart';

class BhreKnowledgeEngine {
  final List<BhreKnowledgeProvider> _providers = [];

  void register(BhreKnowledgeProvider provider) {
    _providers.add(provider);
  }

  Future<List<BhreKnowledgeResult>> search(String query) async {
    final results = <BhreKnowledgeResult>[];

    for (final provider in _providers) {
      try {
        final providerResults = await provider.search(query);
        results.addAll(providerResults);
      } catch (_) {
        // Satu sumber gagal tidak boleh mematikan seluruh pencarian.
      }
    }

    results.sort((a, b) => b.confidence.compareTo(a.confidence));

    return results;
  }
}
