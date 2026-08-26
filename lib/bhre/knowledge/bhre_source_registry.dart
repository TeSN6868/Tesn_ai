import 'bhre_knowledge_provider.dart';
import 'bhre_knowledge_request.dart';

class BhreSourceRegistry {
  final List<BhreKnowledgeProvider> _providers = [];

  void register(BhreKnowledgeProvider provider) {
    final existingIndex = _providers.indexWhere(
      (item) => item.id == provider.id,
    );

    if (existingIndex >= 0) {
      _providers[existingIndex] = provider;
      return;
    }

    _providers.add(provider);
  }

  bool contains(String providerId) {
    return _providers.any((provider) => provider.id == providerId);
  }

  BhreKnowledgeProvider? find(String providerId) {
    for (final provider in _providers) {
      if (provider.id == providerId) {
        return provider;
      }
    }

    return null;
  }

  List<BhreKnowledgeProvider> get providers {
    return List.unmodifiable(_providers);
  }

  List<BhreKnowledgeProvider> resolve(
    BhreKnowledgeRequest request,
  ) {
    return List.unmodifiable(
      _providers.where(
        (provider) => provider.supports(request),
      ),
    );
  }

  void clear() {
    _providers.clear();
  }
}
