import 'knowledge_engine.dart';
import 'knowledge_query.dart';
import 'knowledge_verifier.dart';
import 'knowledge_verification.dart';

class BhreKnowledgePipeline {
  final BhreKnowledgeEngine engine;
  final BhreKnowledgeVerifier verifier;

  BhreKnowledgePipeline({
    BhreKnowledgeEngine? engine,
    BhreKnowledgeVerifier? verifier,
  })  : engine = engine ?? BhreKnowledgeEngine(),
        verifier = verifier ?? BhreKnowledgeVerifier();

  Future<BhreKnowledgeVerification> ask(
    BhreKnowledgeQuery query,
  ) async {
    final results = await engine.search(query.question);

    return verifier.verify(
      query.question,
      results,
    );
  }
}
