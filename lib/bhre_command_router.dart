enum BhreCommandType { security, deviceStatus, navigation, call, chat, unknown }

class BhreCommand {
  final BhreCommandType type;
  final String rawText;
  final String? argument;

  const BhreCommand({required this.type, required this.rawText, this.argument});
}

class BhreCommandRouter {
  static BhreCommand parse(String input) {
    final raw = input.trim();
    final text = raw.toLowerCase();

    if (text.isEmpty) {
      return const BhreCommand(type: BhreCommandType.unknown, rawText: '');
    }

    if (_containsAny(text, [
      'keamanan',
      'security',
      'cek keamanan',
      'periksa keamanan',
    ])) {
      return BhreCommand(type: BhreCommandType.security, rawText: raw);
    }

    if (_containsAny(text, [
      'cek perangkat',
      'cek hp',
      'kondisi hp',
      'kondisi perangkat',
      'status perangkat',
    ])) {
      return BhreCommand(type: BhreCommandType.deviceStatus, rawText: raw);
    }

    if (_containsAny(text, ['navigasi', 'petunjuk jalan', 'arah', 'rute'])) {
      return BhreCommand(type: BhreCommandType.navigation, rawText: raw);
    }

    final callIndex = text.indexOf('panggil ');

    if (callIndex >= 0) {
      final name = raw.substring(callIndex + 'panggil '.length).trim();

      return BhreCommand(
        type: BhreCommandType.call,
        rawText: raw,
        argument: name.isEmpty ? null : name,
      );
    }

    return BhreCommand(type: BhreCommandType.chat, rawText: raw);
  }

  static bool _containsAny(String text, List<String> phrases) {
    for (final phrase in phrases) {
      if (text.contains(phrase)) {
        return true;
      }
    }

    return false;
  }
}
