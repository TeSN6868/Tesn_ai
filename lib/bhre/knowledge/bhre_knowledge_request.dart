import 'bhre_knowledge_domain.dart';

enum BhreKnowledgeRequestType {
  fact,
  current,
  latest,
  explanation,
  comparison,
  analysis,
  event,
  search,
}

class BhreKnowledgeRequest {
  final String query;
  final BhreKnowledgeDomain domain;
  final BhreKnowledgeRequestType type;
  final String? timeContext;
  final String? location;
  final int maxSources;

  const BhreKnowledgeRequest({
    required this.query,
    this.domain = BhreKnowledgeDomain.general,
    this.type = BhreKnowledgeRequestType.search,
    this.timeContext,
    this.location,
    this.maxSources = 5,
  });
}
