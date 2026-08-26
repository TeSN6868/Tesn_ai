import 'dart:io';
import '../lib/bhre/knowledge/bhre_knowledge_provider.dart';
import '../lib/bhre/knowledge/bhre_knowledge_record.dart';
import '../lib/bhre/knowledge/bhre_knowledge_request.dart';
import '../lib/bhre/knowledge/bhre_knowledge_router.dart';
import '../lib/bhre/knowledge/bhre_source_registry.dart';
import '../lib/bhre/source/bhre_source_fetch_pipeline.dart';
import '../lib/bhre/source/bhre_source_fetch_result.dart';
import '../lib/bhre/source/bhre_source_fetcher.dart';
import '../lib/bhre/source/bhre_source_kind.dart';
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
  Future<List<BhreKnowledgeRecord>> search(BhreKnowledgeRequest request) async {
    return const [];
  }
}

class TestFetcher implements BhreSourceFetcher {
  final Set<String> failures;

  const TestFetcher({this.failures = const {}});

  @override
  Future<BhreSourceFetchResult> fetch({
    required BhreKnowledgeRequest request,
    required BhreResolvedSource source,
  }) async {
    final now = DateTime.now();

    if (failures.contains(source.id)) {
      return BhreSourceFetchResult.failure(
        sourceId: source.id,
        sourceName: source.name,
        sourceKind: source.kind,
        query: request.query,
        fetchedAt: now,
        error: 'Simulated fetch failure.',
      );
    }

    return BhreSourceFetchResult.success(
      sourceId: source.id,
      sourceName: source.name,
      sourceKind: source.kind,
      query: request.query,
      content: 'Data from ${source.name}',
      fetchedAt: now,
    );
  }
}

void main() async {
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

  final request = router.route('Gempa terbaru di Indonesia');

  final plan = planner.plan(request);

  final resolved = resolver.resolve(
    request: request,
    plan: plan,
    registry: registry,
  );

  final pipeline = BhreSourceFetchPipeline(fetcher: const TestFetcher());

  final results = await pipeline.fetchAll(request: request, sources: resolved);

  stdout.writeln('');
  stdout.writeln('INPUT: ${request.query}');
  stdout.writeln('RESOLVED: ${resolved.length}');
  stdout.writeln('FETCHED: ${results.length}');

  for (final result in results) {
    stdout.writeln(
      '- ${result.sourceId}'
      ' | success=${result.success}'
      ' | content=${result.content}',
    );
  }

  if (results.length != 3) {
    throw StateError('Pipeline harus menghasilkan tiga hasil.');
  }

  if (!results.every((result) => result.success)) {
    throw StateError('Semua provider test seharusnya berhasil.');
  }

  if (results[0].sourceId != 'bmkg') {
    throw StateError('Urutan hasil harus mengikuti resolver.');
  }

  if (results[1].sourceId != 'scientific-earthquake') {
    throw StateError('Urutan scientific salah.');
  }

  if (results[2].sourceId != 'news-earthquake') {
    throw StateError('Urutan news salah.');
  }

  stdout.writeln('');
  stdout.writeln('BHRE SOURCE FETCH PIPELINE TEST: PASS');
}
