import '../lib/bhre/knowledge/bhre_knowledge_domain.dart';
import '../lib/bhre/knowledge/bhre_knowledge_request.dart';
import '../lib/bhre/knowledge/bhre_knowledge_router.dart';

void main() {
  const router = BhreKnowledgeRouter();

  const cases = {
    'Apa itu blockchain?':
        BhreKnowledgeDomain.technology,

    'Berita AI terbaru':
        BhreKnowledgeDomain.technology,

    'Harga emas hari ini':
        BhreKnowledgeDomain.economy,

    'Gempa terbaru di Indonesia':
        BhreKnowledgeDomain.naturalDisaster,

    'Kenapa rupiah melemah?':
        BhreKnowledgeDomain.economy,

    'Apa perbedaan Flutter dan React Native?':
        BhreKnowledgeDomain.technology,

    'Cuaca besok di Wonogiri':
        BhreKnowledgeDomain.weather,

    'Sejarah kerajaan Majapahit':
        BhreKnowledgeDomain.history,
  };

  for (final entry in cases.entries) {
    final request = router.route(entry.key);

    print('');
    print('INPUT: ${entry.key}');
    print('DOMAIN: ${request.domain.name}');
    print('TYPE: ${request.type.name}');
    print('TIME: ${request.timeContext}');
    print('LOCATION: ${request.location}');

    if (request.domain != entry.value) {
      throw StateError(
        'Domain salah untuk: ${entry.key}',
      );
    }
  }

  final analysis = router.route(
    'Kenapa harga emas naik hari ini?',
  );

  if (analysis.domain != BhreKnowledgeDomain.economy) {
    throw StateError('Domain ekonomi gagal.');
  }

  if (analysis.type != BhreKnowledgeRequestType.current &&
      analysis.type != BhreKnowledgeRequestType.analysis) {
    throw StateError('Jenis request ekonomi gagal.');
  }

  print('');
  print('BHRE KNOWLEDGE ROUTER TEST: PASS');
}
