class BhreGoal {
  final String id;
  final String instruction;
  final DateTime createdAt;

  BhreGoal({
    required this.id,
    required this.instruction,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}
