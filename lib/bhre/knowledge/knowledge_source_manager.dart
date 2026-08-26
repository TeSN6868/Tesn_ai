import 'knowledge_provider.dart';

class BhreKnowledgeSourceManager {
  final Map<String, BhreKnowledgeProvider> _providers = {};

  void register(BhreKnowledgeProvider provider) {
    _providers[provider.id] = provider;
  }

  Iterable<BhreKnowledgeProvider> get providers => _providers.values;

  BhreKnowledgeProvider? get(String id) {
    return _providers[id];
  }

  bool contains(String id) {
    return _providers.containsKey(id);
  }
}
