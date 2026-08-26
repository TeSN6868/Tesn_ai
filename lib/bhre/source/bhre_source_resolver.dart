import '../knowledge/bhre_knowledge_provider.dart';
import '../knowledge/bhre_knowledge_request.dart';
import '../knowledge/bhre_source_registry.dart';
import 'bhre_source_kind.dart';
import 'bhre_source_plan.dart';

class BhreResolvedSource {
  final BhreKnowledgeProvider provider;
  final BhreSourceKind kind;
  final int priorityIndex;

  const BhreResolvedSource({
    required this.provider,
    required this.kind,
    required this.priorityIndex,
  });

  String get id => provider.id;

  String get name => provider.name;

  @override
  String toString() {
    return 'BhreResolvedSource('
        'id: $id, '
        'name: $name, '
        'kind: $kind, '
        'priorityIndex: $priorityIndex'
        ')';
  }
}

class BhreSourceResolver {
  const BhreSourceResolver();

  List<BhreResolvedSource> resolve({
    required BhreKnowledgeRequest request,
    required BhreSourcePlan plan,
    required BhreSourceRegistry registry,
  }) {
    final providers = registry.resolve(request);

    if (providers.isEmpty || plan.preferredSources.isEmpty) {
      return const [];
    }

    final result = <BhreResolvedSource>[];
    final usedProviderIds = <String>{};

    for (var priorityIndex = 0;
        priorityIndex < plan.preferredSources.length;
        priorityIndex++) {
      final preferredKind = plan.preferredSources[priorityIndex];

      for (final provider in providers) {
        if (usedProviderIds.contains(provider.id)) {
          continue;
        }

        if (provider.sourceKind != preferredKind) {
          continue;
        }

        usedProviderIds.add(provider.id);

        result.add(
          BhreResolvedSource(
            provider: provider,
            kind: provider.sourceKind,
            priorityIndex: priorityIndex,
          ),
        );
      }
    }

    return List.unmodifiable(result);
  }
}
