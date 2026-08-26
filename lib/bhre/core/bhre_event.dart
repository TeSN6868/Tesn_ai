enum BhreEventType {
  userMessage,
  voiceInput,
  systemEvent,
  scheduledEvent,
  locationChanged,
  notificationReceived,
  toolResult,
}

class BhreEvent {
  final BhreEventType type;
  final String payload;
  final DateTime timestamp;

  BhreEvent({required this.type, required this.payload, DateTime? timestamp})
    : timestamp = timestamp ?? DateTime.now();
}
