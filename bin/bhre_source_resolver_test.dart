import '../lib/bhre/knowledge/bhre_knowledge_provider.dart';
import '../lib/bhre/knowledge/bhre_knowledge_record.dart';
import '../lib/bhre/knowledge/bhre_knowledge_request.dart';
import '../lib/bhre/knowledge/bhre_knowledge_router.dart';
import '../lib/bhre/knowledge/bhre_source_registry.dart';
import '../lib/bhre/source/bhre_source_kind.dart';
import '../lib/bhre/source/bhre_source_plan.dart';
import '../lib/bhre/source/bhre_source_planner.dart';
import '../lib/bhre/source/bhre_source_resolver.dart';

class TestProvider implements BhreKnowledgeProvider {
  @override
  final String id;

  @override
  final String name;

  @override
  final BhreSourceKind sourceKind;

  const TestProvider({
    required this.id,
    required this.name,
    required this.sourceKind,
  });

  @override
  bool supports(BhreKnowledgeRequest request) => true;

  @override
  Future<List<BhreKnowledgeRecord>> search(
    BhreKnowledgeRequest request,
  ) async {
    return const [];
  }
}

void main() {
  const router = BhreKnowledgeRouter();
  const planner = BhreSourcePlanner();
  const resolver = BhreSourceResolver();

  final registry = BhreSourceRegistry();

  registry.register(
    const TestProvider(
      id: 'bmkg',
      name: 'BMKG',
      sourceKind: BhreSourceKind.government,
    ),
  );

  registry.register(
    const TestProvider(
      id: 'scientific-earthquake',
      name: 'Scientific Earthquake Database',
      sourceKind: BhreSourceKind.scientific,
    ),
  );

  registry.register(
    const TestProvider(
      id: 'news-earthquake',
      name: 'Earthquake News',
      sourceKind: BhreSourceKind.news,
    ),
  );

  final request = router.route(
    'Gempa terbaru di Indonesia',
  );

  final plan = planner.plan(request);

  final resolved = resolver.resolve(
    request: request,
    plan: plan,
    registry: registry,
  );

  print('');
  print('INPUT: ${request.query}');
  print('DOMAIN: ${request.domain.name}');
  print('TYPE: ${request.type.name}');
  print('PLAN: ${plan.preferredSources}');
  print('');
  print('RESOLVED SOURCES:');

  for (final source in resolved) {
    print(
      '- ${source.id}'
      ' | ${source.name}'
      ' | ${source.kind.name}'
      ' | priority=${source.priorityIndex}',
    );
  }

  if (resolved.length != 3) {
    throw StateError(
      'Resolver seharusnya menghasilkan 3 provider.',
    );
  }

  if (resolved[0].kind != BhreSourceKind.government) {
    throw StateError(
      'Government harus menjadi sumber pertama.',
    );
  }

  if (resolved[1].kind != BhreSourceKind.scientific) {
    throw StateError(
      'Scientific harus menjadi sumber kedua.',
    );
  }

  if (resolved[2].kind != BhreSourceKind.news) {
    throw StateError(
      'News harus menjadi sumber ketiga.',
    );
  }

  if (resolved[0].id != 'bmkg') {
    throw StateError(
      'Provider government yang dipilih salah.',
    );
  }

  final ids = resolved.map((source) => source.id).toSet();

  if (ids.length != resolved.length) {
    throw StateError(
      'Resolver menghasilkan provider duplikat.',
    );
  }

  print('');
  print('BHRE SOURCE RESOLVER TEST: PASS');
}
