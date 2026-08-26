enum BhreDetailType {
  person,
  place,
  object,
  action,
  time,
  date,
  purpose,
  reference,
  event,
  unknown,
}

class BhreDetail {
  final BhreDetailType type;
  final String value;
  final double confidence;
  final Map<String, dynamic> metadata;

  const BhreDetail({
    required this.type,
    required this.value,
    this.confidence = 1.0,
    this.metadata = const {},
  });

  BhreDetail copyWith({
    BhreDetailType? type,
    String? value,
    double? confidence,
    Map<String, dynamic>? metadata,
  }) {
    return BhreDetail(
      type: type ?? this.type,
      value: value ?? this.value,
      confidence: confidence ?? this.confidence,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() =>
      'BhreDetail(type: $type, value: "$value", confidence: $confidence)';
}
