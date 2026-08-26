enum BJoAssistantStatus {
  idle,
  thinking,
  responding,
  error,
}

class BJoAssistantState {
  final BJoAssistantStatus status;
  final String? lastMessage;
  final String? lastResponse;
  final String? error;

  const BJoAssistantState({
    this.status = BJoAssistantStatus.idle,
    this.lastMessage,
    this.lastResponse,
    this.error,
  });

  BJoAssistantState copyWith({
    BJoAssistantStatus? status,
    String? lastMessage,
    String? lastResponse,
    String? error,
    bool clearError = false,
  }) {
    return BJoAssistantState(
      status: status ?? this.status,
      lastMessage: lastMessage ?? this.lastMessage,
      lastResponse: lastResponse ?? this.lastResponse,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
