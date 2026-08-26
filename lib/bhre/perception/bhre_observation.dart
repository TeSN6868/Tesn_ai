enum BhreObservationType {
  location,
  time,
  device,
  notification,
  calendar,
  network,
  voice,
  environment,
}

class BhreObservation {
  final BhreObservationType type;
  final String value;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  BhreObservation({
    required this.type,
    required this.value,
    DateTime? timestamp,
    this.metadata = const {},
  }) : timestamp = timestamp ?? DateTime.now();
}
