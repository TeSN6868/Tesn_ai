enum BhreIntentType {
  question,
  command,
  conversation,
  informationRequest,
  planning,
  reminder,
  alarm,
  navigation,
  search,
  automation,
  unknown,
}

class BhreIntent {
  final BhreIntentType type;
  final String rawInput;
  final Map<String, dynamic> parameters;

  const BhreIntent({
    required this.type,
    required this.rawInput,
    this.parameters = const {},
  });
}
