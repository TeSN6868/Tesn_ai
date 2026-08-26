enum BhreObservationType {
  userMessage,
  voiceInput,
  systemEvent,
  scheduledEvent,
  locationChanged,
  notificationReceived,
  toolResult,
}

class BhreObservation {
  final BhreObservationType type;
  final String value;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  const BhreObservation({
    required this.type,
    required this.value,
    required this.timestamp,
    this.metadata = const {},
  });

  BhreObservation copyWith({
    BhreObservationType? type,
    String? value,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
  }) {
    return BhreObservation(
      type: type ?? this.type,
      value: value ?? this.value,
      timestamp: timestamp ?? this.timestamp,
      metadata: metadata ?? this.metadata,
    );
  }
}
