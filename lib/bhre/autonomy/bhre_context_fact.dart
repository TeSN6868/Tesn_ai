enum BhreFactType {
  entity,
  relation,
  temporal,
  action,
  goal,
}

class BhreContextFact {
  final String id;
  final BhreFactType type;
  final String value;
  final DateTime createdAt;
  final double confidence;
  final Map<String, dynamic> metadata;

  const BhreContextFact({
    required this.id,
    required this.type,
    required this.value,
    required this.createdAt,
    this.confidence = 1.0,
    this.metadata = const {},
  });
}
