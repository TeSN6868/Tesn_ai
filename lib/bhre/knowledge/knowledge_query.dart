class BhreKnowledgeQuery {
  final String question;
  final DateTime requestedAt;

  BhreKnowledgeQuery({
    required this.question,
    DateTime? requestedAt,
  }) : requestedAt = requestedAt ?? DateTime.now();
}
