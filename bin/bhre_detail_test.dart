import '../lib/bhre/detail/bhre_detail_extractor.dart';
import '../lib/bhre/detail/bhre_detail.dart';

void main() {
  const input =
      'Besok sore tolong ingatkan saya membawa dokumen yang kemarin '
      'saya taruh di meja, karena akan saya berikan ke Pak Arif '
      'di acara Sembukan.';

  const extractor = BhreDetailExtractor();
  final details = extractor.extract(input);

  void requireDetail(BhreDetailType type, String value) {
    final found = details.any(
      (detail) =>
          detail.type == type &&
          detail.value.toLowerCase() == value.toLowerCase(),
    );

    if (!found) {
      throw StateError(
        'Detail tidak ditemukan: $type = $value\n'
        'Hasil: $details',
      );
    }
  }

  requireDetail(BhreDetailType.person, 'Pak Arif');
  requireDetail(BhreDetailType.place, 'acara Sembukan');
  requireDetail(BhreDetailType.action, 'ingatkan');
  requireDetail(BhreDetailType.time, 'sore');
  requireDetail(BhreDetailType.date, 'besok');
  requireDetail(BhreDetailType.reference, 'yang kemarin');

  print('BHRE DETAIL ENGINE TEST: PASS');
  print('Input: $input');
  print('Detail count: ${details.length}');

  for (final detail in details) {
    print(
      '${detail.type.name}: ${detail.value} '
      '(confidence=${detail.confidence})',
    );
  }
}
