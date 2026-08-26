class BhreResponse {
  final String text;
  final bool shouldSpeak;
  final bool shouldExecuteAction;

  const BhreResponse({
    required this.text,
    this.shouldSpeak = true,
    this.shouldExecuteAction = false,
  });
}
