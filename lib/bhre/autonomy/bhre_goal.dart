class BhreGoal {
  final String id;
  final String action;
  final String? target;
  final String? scheduledTime;
  final DateTime createdAt;
  final double confidence;
  final bool completed;

  const BhreGoal({
    required this.id,
    required this.action,
    this.target,
    this.scheduledTime,
    required this.createdAt,
    this.confidence = 1.0,
    this.completed = false,
  });

  BhreGoal copyWith({
    String? action,
    String? target,
    String? scheduledTime,
    double? confidence,
    bool? completed,
  }) {
    return BhreGoal(
      id: id,
      action: action ?? this.action,
      target: target ?? this.target,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      createdAt: createdAt,
      confidence: confidence ?? this.confidence,
      completed: completed ?? this.completed,
    );
  }
}
