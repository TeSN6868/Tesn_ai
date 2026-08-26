import 'bhre_knowledge_domain.dart';
import 'bhre_knowledge_source.dart';

class BhreKnowledgeRecord {
  final String id;
  final String topic;
  final String content;
  final BhreKnowledgeDomain domain;
  final List<BhreKnowledgeSource> sources;
  final DateTime createdAt;
  final DateTime? observedAt;
  final double confidence;
  final bool verified;
  final String generatedBy;

  const BhreKnowledgeRecord({
    required this.id,
    required this.topic,
    required this.content,
    required this.domain,
    this.sources = const [],
    required this.createdAt,
    this.observedAt,
    this.confidence = 0.0,
    this.verified = false,
    this.generatedBy = 'Bree',
  });

  BhreKnowledgeRecord copyWith({
    String? id,
    String? topic,
    String? content,
    BhreKnowledgeDomain? domain,
    List<BhreKnowledgeSource>? sources,
    DateTime? createdAt,
    DateTime? observedAt,
    double? confidence,
    bool? verified,
    String? generatedBy,
  }) {
    return BhreKnowledgeRecord(
      id: id ?? this.id,
      topic: topic ?? this.topic,
      content: content ?? this.content,
      domain: domain ?? this.domain,
      sources: sources ?? this.sources,
      createdAt: createdAt ?? this.createdAt,
      observedAt: observedAt ?? this.observedAt,
      confidence: confidence ?? this.confidence,
      verified: verified ?? this.verified,
      generatedBy: generatedBy ?? this.generatedBy,
    );
  }
}
