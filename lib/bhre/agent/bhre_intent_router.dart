import '../cognition/bhre_intent.dart';

class BhreIntentRouter {
  BhreIntent route(String input) {
    final text = input.trim();

    if (text.isEmpty) {
      return const BhreIntent(type: BhreIntentType.unknown, rawInput: '');
    }

    final normalized = text.toLowerCase();

    if (_containsAny(normalized, ['alarm', 'bangunkan', 'bangun'])) {
      return BhreIntent(type: BhreIntentType.alarm, rawInput: text);
    }

    if (_containsAny(normalized, ['ingatkan', 'pengingat', 'reminder'])) {
      return BhreIntent(type: BhreIntentType.reminder, rawInput: text);
    }

    if (_containsAny(normalized, ['rencanakan', 'rencana', 'siapkan'])) {
      return BhreIntent(type: BhreIntentType.planning, rawInput: text);
    }

    if (_containsAny(normalized, [
      'navigasi',
      'jalan ke',
      'arah ke',
      'pergi ke',
    ])) {
      return BhreIntent(type: BhreIntentType.navigation, rawInput: text);
    }

    // Perintah tindakan harus diprioritaskan sebelum
    // klasifikasi pertanyaan/informasi.
    if (_containsAny(normalized, [
      'buka',
      'tutup',
      'putar',
      'kirim',
      'hapus',
      'simpan',
      'hubungi',
      'telepon',
      'panggil',
      'mulai',
      'berhenti',
      'nyalakan',
      'matikan',
      'lakukan',
      'buatkan',
      'tolong',
    ])) {
      return BhreIntent(type: BhreIntentType.command, rawInput: text);
    }

    if (_containsAny(normalized, [
      'cari',
      'berita',
      'informasi',
      'apa yang terjadi',
      'berapa',
      'kapan',
      'di mana',
      'dimana',
      'siapa',
      'mengapa',
      'kenapa',
    ])) {
      return BhreIntent(
        type: BhreIntentType.informationRequest,
        rawInput: text,
      );
    }

    if (text.endsWith('?')) {
      return BhreIntent(type: BhreIntentType.question, rawInput: text);
    }

    return BhreIntent(type: BhreIntentType.conversation, rawInput: text);
  }

  bool _containsAny(String text, List<String> patterns) {
    return patterns.any(text.contains);
  }
}
