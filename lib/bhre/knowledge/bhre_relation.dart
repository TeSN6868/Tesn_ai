enum BhreEntityType {
  person,
  place,
  object,
  event,
  time,
  date,
  unknown,
}

class BhreEntity {
  final String id;
  final BhreEntityType type;
  final String value;
  final double confidence;
  final Map<String, dynamic> metadata;

  const BhreEntity({
    required this.id,
    required this.type,
    required this.value,
    this.confidence = 1.0,
    this.metadata = const {},
  });

  @override
  String toString() =>
      'BhreEntity(id: $id, type: $type, value: "$value", '
      'confidence: $confidence)';
}

class BhreRelation {
  final String subjectId;
  final String relation;
  final String objectId;
  final double confidence;
  final Map<String, dynamic> metadata;

  const BhreRelation({
    required this.subjectId,
    required this.relation,
    required this.objectId,
    this.confidence = 1.0,
    this.metadata = const {},
  });

  @override
  String toString() =>
      'BhreRelation($subjectId --$relation--> $objectId)';
}
