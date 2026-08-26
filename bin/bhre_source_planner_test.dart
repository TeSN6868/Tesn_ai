import '../lib/bhre/knowledge/bhre_knowledge_router.dart';
import '../lib/bhre/knowledge/bhre_knowledge_domain.dart';
import '../lib/bhre/source/bhre_source_planner.dart';

void main() {
  const router = BhreKnowledgeRouter();
  const planner = BhreSourcePlanner();

  final cases = [
    'Harga emas hari ini',
    'Kenapa rupiah melemah?',
    'Gempa terbaru di Indonesia',
    'Apa itu blockchain?',
    'Sejarah kerajaan Majapahit',
    'Cuaca besok di Wonogiri',
  ];

  for (final input in cases) {
    final request = router.route(input);
    final plan = planner.plan(request);

    print('');
    print('INPUT: $input');
    print('DOMAIN: ${request.domain.name}');
    print('TYPE: ${request.type.name}');
    print('SOURCES: ${plan.preferredSources}');
    print('MIN SOURCES: ${plan.minimumSources}');
    print('VERIFY: ${plan.requiresVerification}');
    print('FRESH DATA: ${plan.requiresFreshData}');
    print('PRIORITY: ${plan.priority.name}');
  }

  final economy = planner.plan(
    router.route('Kenapa harga emas naik hari ini?'),
  );

  if (economy.preferredSources.isEmpty) {
    throw StateError(
      'Source plan ekonomi kosong.',
    );
  }

  if (!economy.requiresVerification) {
    throw StateError(
      'Informasi ekonomi harus diverifikasi.',
    );
  }

  if (economy.minimumSources < 2) {
    throw StateError(
      'Analisis ekonomi membutuhkan minimal dua sumber.',
    );
  }

  print('');
  print('BHRE SOURCE PLANNER TEST: PASS');
}
