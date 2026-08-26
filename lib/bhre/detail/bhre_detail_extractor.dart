import 'bhre_detail.dart';

class BhreDetailExtractor {
  const BhreDetailExtractor();

  List<BhreDetail> extract(String input) {
    final text = input.trim();
    if (text.isEmpty) return const [];

    final normalized = text.toLowerCase();
    final details = <BhreDetail>[];

    _extractPeople(text, normalized, details);
    _extractPlaces(text, normalized, details);
    _extractTime(text, normalized, details);
    _extractDates(text, normalized, details);
    _extractObjects(text, normalized, details);
    _extractActions(text, normalized, details);
    _extractReferences(text, normalized, details);

    return List.unmodifiable(details);
  }

  void _extractPeople(
    String text,
    String normalized,
    List<BhreDetail> details,
  ) {
    final pattern = RegExp(
      r'\b(?:pak|bapak|bu|ibu|mas|mbak|kang|dek)\s+'
      r'[A-Za-zÀ-ÿ]+(?:\s+[A-Za-zÀ-ÿ]+)?'
      r'(?=\s+(?:di|ke|dari|untuk|karena|agar|supaya|yang|pada|dengan)\b|[,.!?]|$)',
      caseSensitive: false,
    );

    for (final match in pattern.allMatches(text)) {
      final value = match.group(0)!.trim();

      if (value.isEmpty) continue;

      details.add(
        BhreDetail(
          type: BhreDetailType.person,
          value: value,
          confidence: 0.98,
        ),
      );
    }
  }

  void _extractPlaces(
    String text,
    String normalized,
    List<BhreDetail> details,
  ) {
    final patterns = <RegExp>[
      // "di acara Sembukan" -> "acara Sembukan"
      RegExp(
        r'\bdi\s+(acara\s+[^,.!?]+?)(?=\s+(?:karena|untuk|agar|supaya)\b|[,.!?]|$)',
        caseSensitive: false,
      ),

      // "di Pantai Sembukan" -> "Pantai Sembukan"
      RegExp(
        r'\bdi\s+((?:pantai|desa|kecamatan|kota|rumah|kantor|sekolah|'
        r'pasar|masjid|pendopo|lapangan)\s+[^,.!?]+?)(?=\s+'
        r'(?:karena|untuk|agar|supaya)\b|[,.!?]|$)',
        caseSensitive: false,
      ),

      // "ke Pantai Sembukan"
      RegExp(
        r'\bke\s+((?:pantai|desa|kecamatan|kota|rumah|kantor|sekolah|'
        r'pasar|masjid|pendopo|lapangan)\s+[^,.!?]+?)(?=\s+'
        r'(?:karena|untuk|agar|supaya)\b|[,.!?]|$)',
        caseSensitive: false,
      ),

      // "menuju Pantai Sembukan"
      RegExp(
        r'\bmenuju\s+((?:pantai|desa|kecamatan|kota|rumah|kantor|sekolah|'
        r'pasar|masjid|pendopo|lapangan)\s+[^,.!?]+?)(?=\s+'
        r'(?:karena|untuk|agar|supaya)\b|[,.!?]|$)',
        caseSensitive: false,
      ),
    ];

    final seen = <String>{};

    for (final pattern in patterns) {
      for (final match in pattern.allMatches(text)) {
        final value = match.group(1)!.trim();

        if (value.isEmpty) continue;

        final key = value.toLowerCase();
        if (!seen.add(key)) continue;

        details.add(
          BhreDetail(
            type: BhreDetailType.place,
            value: value,
            confidence: 0.95,
          ),
        );
      }
    }
  }

  void _extractTime(
    String text,
    String normalized,
    List<BhreDetail> details,
  ) {
    const expressions = [
      'pagi',
      'siang',
      'sore',
      'malam',
      'sebentar lagi',
      'nanti',
      'besok',
      'lusa',
      'kemarin',
      'tadi',
    ];

    for (final expression in expressions) {
      if (normalized.contains(expression)) {
        final type = expression == 'besok' ||
                expression == 'lusa' ||
                expression == 'kemarin' ||
                expression == 'tadi'
            ? BhreDetailType.date
            : BhreDetailType.time;

        details.add(
          BhreDetail(
            type: type,
            value: expression,
            confidence: 0.9,
          ),
        );
      }
    }
  }

  void _extractDates(
    String text,
    String normalized,
    List<BhreDetail> details,
  ) {
    final datePattern = RegExp(
      r'\b\d{1,2}[/-]\d{1,2}(?:[/-]\d{2,4})?\b',
    );

    for (final match in datePattern.allMatches(text)) {
      details.add(
        BhreDetail(
          type: BhreDetailType.date,
          value: match.group(0)!,
          confidence: 0.98,
        ),
      );
    }
  }

  void _extractObjects(
    String text,
    String normalized,
    List<BhreDetail> details,
  ) {
    const objects = [
      'dokumen',
      'surat',
      'buku',
      'berkas',
      'tas',
      'kunci',
      'hp',
      'ponsel',
      'uang',
      'barang',
      'foto',
      'file',
    ];

    const locations = [
      'meja',
      'kursi',
      'lemari',
      'tas',
      'laci',
      'rak',
      'lantai',
    ];

    for (final value in [...objects, ...locations]) {
      if (RegExp(r'\b' + value + r'\b').hasMatch(normalized)) {
        details.add(
          BhreDetail(
            type: BhreDetailType.object,
            value: value,
            confidence: 0.90,
          ),
        );
      }
    }
  }

  void _extractActions(
    String text,
    String normalized,
    List<BhreDetail> details,
  ) {
    const actions = [
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
      'ingatkan',
      'buatkan',
      'ambil',
      'cari',
      'periksa',
      'siapkan',
    ];

    for (final action in actions) {
      if (RegExp(r'\b' + action + r'\b').hasMatch(normalized)) {
        details.add(
          BhreDetail(
            type: BhreDetailType.action,
            value: action,
            confidence: 0.95,
          ),
        );
      }
    }
  }

  void _extractReferences(
    String text,
    String normalized,
    List<BhreDetail> details,
  ) {
    const references = [
      'yang itu',
      'yang tadi',
      'yang kemarin',
      'yang sebelumnya',
      'itu',
      'ini',
      'tersebut',
      'sebelumnya',
    ];

    for (final reference in references) {
      if (normalized.contains(reference)) {
        details.add(
          BhreDetail(
            type: BhreDetailType.reference,
            value: reference,
            confidence: 0.8,
            metadata: const {
              'kind': 'entityReference',
            },
          ),
        );
      }
    }

    // Reference bentuk enklitik Bahasa Indonesia:
    //
    // mengambilnya
    // membawanya
    // mengirimnya
    // menyimpannya
    //
    // "-nya" berarti benda/orang yang sudah disebut
    // sebelumnya dalam konteks.
    final nyaPattern = RegExp(
      r'\b[a-zA-ZÀ-ÿ]{4,}nya\b',
      caseSensitive: false,
    );

    for (final match in nyaPattern.allMatches(normalized)) {
      final word = match.group(0);

      if (word == null || word.isEmpty) continue;

      details.add(
        BhreDetail(
          type: BhreDetailType.reference,
          value: '-nya',
          confidence: 0.92,
          metadata: {
            'kind': 'entityReference',
            'sourceWord': word,
            'referenceForm': 'enclitic',
          },
        ),
      );
    }
  }
}
