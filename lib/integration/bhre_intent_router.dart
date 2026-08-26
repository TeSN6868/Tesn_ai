import 'bjo_intent.dart';

class BhreIntentRouter {
  BJoIntent route(String input) {
    final text = input.trim();
    final normalized = text.toLowerCase();

    if (text.isEmpty) {
      return const BJoIntent(
        type: BJoIntentType.unknown,
        text: '',
        confidence: 1.0,
      );
    }

    if (_containsAny(normalized, [
      'telepon',
      'teleponi',
      'panggil',
      'hubungi',
      'call',
    ])) {
      return BJoIntent(
        type: BJoIntentType.call,
        text: text,
        confidence: 0.95,
      );
    }

    if (_containsAny(normalized, [
      'dimana',
      'di mana',
      'lokasi',
      'posisi saya',
      'posisi',
      'arah',
      'jalan ke',
    ])) {
      return BJoIntent(
        type: BJoIntentType.location,
        text: text,
        confidence: 0.90,
      );
    }

    if (_containsAny(normalized, [
      'cari',
      'carikan',
      'temukan',
      'search',
      'berita',
      'informasi tentang',
    ])) {
      return BJoIntent(
        type: BJoIntentType.search,
        text: text,
        confidence: 0.90,
      );
    }

    if (_containsAny(normalized, [
      'pengaturan',
      'setting',
      'setelan',
      'aktifkan',
      'matikan',
      'hapus sesi',
    ])) {
      return BJoIntent(
        type: BJoIntentType.system,
        text: text,
        confidence: 0.90,
      );
    }

    return BJoIntent(
      type: BJoIntentType.chat,
      text: text,
      confidence: 0.70,
    );
  }

  bool _containsAny(String text, List<String> keywords) {
    return keywords.any(text.contains);
  }
}
