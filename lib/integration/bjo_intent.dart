enum BJoIntentType { chat, search, call, location, system, unknown }

class BJoIntent {
  final BJoIntentType type;
  final String text;
  final double confidence;

  const BJoIntent({
    required this.type,
    required this.text,
    this.confidence = 1.0,
  });

  @override
  String toString() {
    return 'BJoIntent(type: $type, confidence: $confidence, text: $text)';
  }
}
