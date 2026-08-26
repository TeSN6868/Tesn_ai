class BhreAutonomousState {
  final bool hasContext;
  final bool hasMemory;
  final bool hasGoal;
  final bool requiresClarification;
  final String? nextAction;
  final double confidence;

  const BhreAutonomousState({
    required this.hasContext,
    required this.hasMemory,
    required this.hasGoal,
    required this.requiresClarification,
    required this.nextAction,
    required this.confidence,
  });
}
