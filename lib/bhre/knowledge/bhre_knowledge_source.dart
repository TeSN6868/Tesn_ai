enum BhreKnowledgeSourceType {
  web,
  news,
  api,
  government,
  scientific,
  database,
  memory,
  knowledgeGraph,
  userProvided,
  bhreGenerated,
  unknown,
}

class BhreKnowledgeSource {
  final String id;
  final String name;
  final BhreKnowledgeSourceType type;
  final String? uri;
  final double confidence;
  final bool verified;

  const BhreKnowledgeSource({
    required this.id,
    required this.name,
    required this.type,
    this.uri,
    this.confidence = 1.0,
    this.verified = false,
  });
}
