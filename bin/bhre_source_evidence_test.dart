import 'dart:io';

import '../lib/bhre/source/bhre_source_evidence.dart';
import '../lib/bhre/source/bhre_source_evidence_collector.dart';
import '../lib/bhre/source/bhre_source_fetch_result.dart';
import '../lib/bhre/source/bhre_source_kind.dart';

void main() {
  final now = DateTime(2026, 8, 26, 10, 0);

  final results = [
    BhreSourceFetchResult.success(
      sourceId: 'bmkg',
      sourceName: 'BMKG',
      sourceKind: BhreSourceKind.government,
      query: 'Gempa terbaru di Indonesia',
      content: 'Gempa M 5.2 terdeteksi di wilayah Indonesia.',
      uri: 'https://example.test/bmkg',
      fetchedAt: now,
    ),
    BhreSourceFetchResult.failure(
      sourceId: 'broken-source',
      sourceName: 'Broken Source',
      sourceKind: BhreSourceKind.government,
      query: 'Gempa terbaru di Indonesia',
      fetchedAt: now,
      error: 'Connection failed',
    ),
    BhreSourceFetchResult.success(
      sourceId: 'empty-source',
      sourceName: 'Empty Source',
      sourceKind: BhreSourceKind.government,
      query: 'Gempa terbaru di Indonesia',
      content: '   ',
      fetchedAt: now,
    ),
    BhreSourceFetchResult.success(
      sourceId: 'scientific-earthquake',
      sourceName: 'Scientific Earthquake Database',
      sourceKind: BhreSourceKind.scientific,
      query: 'Gempa terbaru di Indonesia',
      content: 'Scientific observation confirms seismic activity.',
      fetchedAt: now,
    ),
  ];

  const collector = BhreSourceEvidenceCollector();

  final evidence = collector.collect(results);

  stdout.writeln('');
  stdout.writeln('INPUT RESULTS: ${results.length}');
  stdout.writeln('USABLE EVIDENCE: ${evidence.length}');

  for (final item in evidence) {
    stdout.writeln(
      '- ${item.sourceId}'
      ' | ${item.sourceName}'
      ' | usable=${item.usable}',
    );
  }

  if (evidence.length != 2) {
    throw StateError(
      'Collector harus menghasilkan tepat 2 evidence usable.',
    );
  }

  if (evidence[0].sourceId != 'bmkg') {
    throw StateError(
      'Evidence pertama harus berasal dari BMKG.',
    );
  }

  if (evidence[1].sourceId != 'scientific-earthquake') {
    throw StateError(
      'Evidence kedua harus berasal dari scientific source.',
    );
  }

  if (!evidence.every((item) => item.usable)) {
    throw StateError(
      'Evidence yang dikumpulkan harus usable.',
    );
  }

  if (evidence.any((item) => item.sourceId == 'broken-source')) {
    throw StateError(
      'Fetch failure tidak boleh menjadi evidence.',
    );
  }

  if (evidence.any((item) => item.sourceId == 'empty-source')) {
    throw StateError(
      'Content kosong tidak boleh menjadi evidence.',
    );
  }

  final direct = BhreSourceEvidence.fromFetch(results.first);

  if (direct.content.isEmpty) {
    throw StateError(
      'Evidence dari fetch sukses harus membawa content.',
    );
  }

  stdout.writeln('');
  stdout.writeln('BHRE SOURCE EVIDENCE TEST: PASS');
}
