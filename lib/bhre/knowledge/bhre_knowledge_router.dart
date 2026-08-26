import 'bhre_knowledge_domain.dart';
import 'bhre_knowledge_request.dart';

class BhreKnowledgeRouter {
  const BhreKnowledgeRouter();

  BhreKnowledgeRequest route(String input) {
    final query = input.trim();
    final normalized = query.toLowerCase();

    if (query.isEmpty) {
      return const BhreKnowledgeRequest(
        query: '',
        domain: BhreKnowledgeDomain.unknown,
      );
    }

    final domain = _detectDomain(normalized);
    final type = _detectType(normalized);

    return BhreKnowledgeRequest(
      query: query,
      domain: domain,
      type: type,
      timeContext: _detectTimeContext(normalized),
      location: _detectLocation(normalized),
    );
  }

  BhreKnowledgeDomain _detectDomain(String text) {
    if (_containsAny(text, [
      'gempa',
      'tsunami',
      'gunung meletus',
      'letusan',
      'erupsi',
      'banjir',
      'longsor',
      'kebakaran hutan',
    ])) {
      return BhreKnowledgeDomain.naturalDisaster;
    }

    if (_containsAny(text, [
      'cuaca',
      'hujan',
      'angin',
      'suhu',
      'prakiraan',
      'badai',
    ])) {
      return BhreKnowledgeDomain.weather;
    }

    if (_containsAny(text, [
      'emas',
      'rupiah',
      'inflasi',
      'suku bunga',
      'ekonomi',
      'ekonomi indonesia',
      'pasar',
      'saham',
      'obligasi',
      'investasi',
    ])) {
      return BhreKnowledgeDomain.economy;
    }

    // ============================================================
    // IT / CYBERSECURITY / DIGITAL FORENSICS
    // ============================================================
    //
    // Cybersecurity dan Digital Forensics sengaja diprioritaskan
    // sebagai bagian utama domain teknologi Bree.
    //
    if (_containsAny(text, [
      'digital forensics',
      'digital forensic',
      'forensik digital',
      'forensik komputer',
      'computer forensics',
      'computer forensic',
      'mobile forensics',
      'mobile forensic',
      'network forensics',
      'network forensic',
      'disk forensics',
      'memory forensics',
      'forensic analysis',
      'analisis forensik',
      'bukti digital',
      'barang bukti digital',
      'digital evidence',
      'chain of custody',
      'autopsy',
      'volatility',
      'sleuth kit',
      'sleuthkit',
      'wireshark',
      'packet capture',
      'pcap',
      'malware analysis',
      'analisis malware',
      'incident response',
      'incident handling',
      'threat hunting',
      'threat intelligence',
      'penetration testing',
      'penetration test',
      'ethical hacking',
      'ethical hacker',
      'cybersecurity',
      'cyber security',
      'keamanan siber',
      'keamanan cyber',
      'kejahatan siber',
      'cybercrime',
      'cyber crime',
      'ransomware',
      'phishing',
      'exploit',
      'vulnerability',
      'kerentanan',
      'firewall',
      'ids',
      'ips',
      'soc',
      'siem',
    ])) {
      return BhreKnowledgeDomain.technology;
    }

    if (_containsAny(text, [
      'ai',
      'artificial intelligence',
      'kecerdasan buatan',
      'software',
      'hardware',
      'komputer',
      'programming',
      'pemrograman',
      'coding',
      'aplikasi',
      'teknologi',
      'internet',
      'database',
      'flutter',
      'dart',
      'server',
      'cloud',
      'api',
      'jaringan',
      'network',
      'linux',
      'android',
      'ios',
      'sistem operasi',
    ])) {
      return BhreKnowledgeDomain.technology;
    }

    if (_containsAny(text, [
      'berita',
      'kejadian',
      'terbaru',
      'terkini',
      'hari ini',
      'dunia hari ini',
    ])) {
      return BhreKnowledgeDomain.news;
    }

    if (_containsAny(text, [
      'masyarakat',
      'sosial',
      'budaya',
      'tradisi',
      'perilaku masyarakat',
      'fenomena sosial',
    ])) {
      return BhreKnowledgeDomain.social;
    }

    if (_containsAny(text, [
      'politik',
      'presiden',
      'pemerintah',
      'pemilu',
      'menteri',
      'parlemen',
      'dpr',
    ])) {
      return BhreKnowledgeDomain.politics;
    }

    if (_containsAny(text, [
      'ilmiah',
      'penelitian',
      'jurnal',
      'fisika',
      'kimia',
      'biologi',
      'astronomi',
      'sains',
    ])) {
      return BhreKnowledgeDomain.science;
    }

    if (_containsAny(text, [
      'sejarah',
      'kerajaan',
      'perang',
      'peradaban',
      'sejarah indonesia',
    ])) {
      return BhreKnowledgeDomain.history;
    }

    if (_containsAny(text, [
      'sepak bola',
      'football',
      'basket',
      'olahraga',
      'liga',
      'piala dunia',
    ])) {
      return BhreKnowledgeDomain.sports;
    }

    if (_containsAny(text, [
      'kesehatan',
      'penyakit',
      'obat',
      'gejala',
      'dokter',
    ])) {
      return BhreKnowledgeDomain.health;
    }

    return BhreKnowledgeDomain.general;
  }

  BhreKnowledgeRequestType _detectType(String text) {
    // ANALYSIS harus diprioritaskan.
    //
    // Contoh:
    // "Kenapa harga emas naik hari ini?"
    //
    // Walaupun mengandung "hari ini" dan "harga",
    // maksud utamanya adalah meminta analisis/penyebab.
    if (_containsAny(text, [
      'kenapa',
      'mengapa',
      'penyebab',
      'apa penyebab',
      'faktor',
      'alasan',
      'dampak',
      'dampaknya',
      'pengaruh',
      'mengapa bisa',
      'kenapa bisa',
      'apa yang menyebabkan',
      'apa sebab',
      'analisis',
    ])) {
      return BhreKnowledgeRequestType.analysis;
    }

    // Permintaan informasi terbaru.
    if (_containsAny(text, [
      'terbaru',
      'terkini',
      'hari ini',
      'sekarang',
      'saat ini',
      'update',
      'update terbaru',
    ])) {
      return BhreKnowledgeRequestType.latest;
    }

    // Nilai/kondisi saat ini.
    if (_containsAny(text, [
      'harga',
      'berapa',
      'nilai',
      'kurs',
      'suhu',
      'jumlah',
    ])) {
      return BhreKnowledgeRequestType.current;
    }

    // Perbandingan.
    if (_containsAny(text, [
      'bandingkan',
      'perbedaan',
      'beda',
      'mana yang lebih',
    ])) {
      return BhreKnowledgeRequestType.comparison;
    }

    // Penjelasan konsep.
    if (_containsAny(text, [
      'apa itu',
      'jelaskan',
      'jelasin',
      'pengertian',
      'maksudnya',
    ])) {
      return BhreKnowledgeRequestType.explanation;
    }

    // Pertanyaan waktu kejadian.
    if (_containsAny(text, ['kapan', 'kapan terjadi', 'kapan berlangsung'])) {
      return BhreKnowledgeRequestType.event;
    }

    return BhreKnowledgeRequestType.search;
  }

  String? _detectTimeContext(String text) {
    if (_containsAny(text, ['hari ini', 'sekarang', 'saat ini'])) {
      return 'today';
    }

    if (_containsAny(text, ['kemarin'])) {
      return 'yesterday';
    }

    if (_containsAny(text, ['besok'])) {
      return 'tomorrow';
    }

    if (_containsAny(text, ['terbaru', 'terkini'])) {
      return 'latest';
    }

    return null;
  }

  String? _detectLocation(String text) {
    if (text.contains('indonesia')) {
      return 'Indonesia';
    }

    if (text.contains('jakarta')) {
      return 'Jakarta';
    }

    if (text.contains('jawa')) {
      return 'Jawa';
    }

    if (text.contains('wonogiri')) {
      return 'Wonogiri';
    }

    return null;
  }

  bool _containsAny(String text, List<String> patterns) {
    return patterns.any(text.contains);
  }
}
