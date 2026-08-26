import 'bhre_source_kind.dart';

enum BhreSourcePriority {
  primary,
  secondary,
  tertiary,
}

class BhreSourcePlan {
  final String query;
  final List<BhreSourceKind> preferredSources;
  final int minimumSources;
  final bool requiresVerification;
  final bool requiresFreshData;
  final BhreSourcePriority priority;

  const BhreSourcePlan({
    required this.query,
    required this.preferredSources,
    this.minimumSources = 1,
    this.requiresVerification = true,
    this.requiresFreshData = false,
    this.priority = BhreSourcePriority.secondary,
  });

  @override
  String toString() {
    return 'BhreSourcePlan('
        'query: "$query", '
        'sources: $preferredSources, '
        'minimumSources: $minimumSources, '
        'verification: $requiresVerification, '
        'freshData: $requiresFreshData, '
        'priority: $priority'
        ')';
  }
}
