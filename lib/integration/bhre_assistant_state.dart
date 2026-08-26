enum BhreAssistantStatus {
  idle,
  starting,
  thinking,
  responding,
  error,
}

class BhreAssistantState {
  final BhreAssistantStatus status;
  final String? lastMessage;
  final String? lastResponse;
  final String? lastIntent;
  final String? error;

  const BhreAssistantState({
    this.status = BhreAssistantStatus.idle,
    this.lastMessage,
    this.lastResponse,
    this.lastIntent,
    this.error,
  });

  BhreAssistantState copyWith({
    BhreAssistantStatus? status,
    String? lastMessage,
    String? lastResponse,
    String? lastIntent,
    String? error,
    bool clearError = false,
  }) {
    return BhreAssistantState(
      status: status ?? this.status,
      lastMessage: lastMessage ?? this.lastMessage,
      lastResponse: lastResponse ?? this.lastResponse,
      lastIntent: lastIntent ?? this.lastIntent,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
