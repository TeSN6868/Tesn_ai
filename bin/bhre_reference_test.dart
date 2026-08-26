import '../lib/bhre/detail/bhre_detail_extractor.dart';
import '../lib/bhre/knowledge/bhre_knowledge_memory.dart';
import '../lib/bhre/knowledge/bhre_relation.dart';
import '../lib/bhre/knowledge/bhre_reference_resolver.dart';
import '../lib/bhre/knowledge/bhre_relation_engine.dart';

void main() {
  const firstInput =
      'Kemarin saya menaruh dokumen di meja untuk diberikan '
      'kepada Pak Arif di acara Sembukan.';

  const extractor = BhreDetailExtractor();
  const relationEngine = BhreRelationEngine();
  final memory = BhreKnowledgeMemory();

  final firstDetails = extractor.extract(firstInput);
  final firstGraph = relationEngine.build(
    firstInput,
    firstDetails,
  );

  memory.remember(firstGraph);

  final documents = memory.findByValue('dokumen');

  if (documents.isEmpty) {
    throw StateError(
      'Memory tidak menemukan dokumen.',
    );
  }

  final arif = memory.findByValue('Pak Arif');

  if (arif.isEmpty) {
    throw StateError(
      'Memory tidak menemukan Pak Arif.',
    );
  }

  const resolver = BhreReferenceResolver();

  final graph = firstGraph;

  final reference = resolver.resolve(
    'yang itu',
    graph,
    expectedType: BhreEntityType.object,
  );

  if (reference.resolved) {
    throw StateError(
      'Referensi ambigu seharusnya belum dipaksakan.',
    );
  }

  print('BHRE REFERENCE + MEMORY TEST: PASS');
  print('Stored graphs: ${memory.graphs.length}');
  print('Stored entities: ${memory.allEntities().length}');
  print('Documents found: ${documents.length}');
  print('Pak Arif found: ${arif.length}');
  print('Ambiguous "yang itu": unresolved');
}
