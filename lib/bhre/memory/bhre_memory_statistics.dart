class BhreMemoryStatistics {
  final int conversation;
  final int knowledge;
  final int context;
  final int persistent;
  final int important;
  final int knowledgeGraphs;

  const BhreMemoryStatistics({
    this.conversation = 0,
    this.knowledge = 0,
    this.context = 0,
    this.persistent = 0,
    this.important = 0,
    this.knowledgeGraphs = 0,
  });

  int get total =>
      conversation + knowledge + context + persistent + knowledgeGraphs;

  Map<String, dynamic> toMap() {
    return {
      'conversation': conversation,
      'knowledge': knowledge,
      'context': context,
      'persistent': persistent,
      'important': important,
      'knowledgeGraphs': knowledgeGraphs,
      'total': total,
    };
  }
}
