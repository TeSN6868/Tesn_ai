class BhreContext {
  final DateTime timestamp;
  final String? location;
  final String? currentActivity;
  final Map<String, dynamic> data;

  const BhreContext({
    required this.timestamp,
    this.location,
    this.currentActivity,
    this.data = const {},
  });

  BhreContext copyWith({
    DateTime? timestamp,
    String? location,
    String? currentActivity,
    Map<String, dynamic>? data,
  }) {
    return BhreContext(
      timestamp: timestamp ?? this.timestamp,
      location: location ?? this.location,
      currentActivity: currentActivity ?? this.currentActivity,
      data: data ?? this.data,
    );
  }
}
