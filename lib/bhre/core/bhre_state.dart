enum BhreRuntimeState {
  idle,
  listening,
  thinking,
  speaking,
  executing,
  error,
}

class BhreState {
  final BhreRuntimeState runtime;
  final String? currentTask;

  const BhreState({
    this.runtime = BhreRuntimeState.idle,
    this.currentTask,
  });

  BhreState copyWith({
    BhreRuntimeState? runtime,
    String? currentTask,
  }) {
    return BhreState(
      runtime: runtime ?? this.runtime,
      currentTask: currentTask ?? this.currentTask,
    );
  }
}
