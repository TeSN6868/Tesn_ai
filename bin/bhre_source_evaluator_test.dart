import 'dart:io';

import '../lib/bhre/source/bhre_source_evidence.dart';
import '../lib/bhre/source/bhre_source_evaluation.dart';
import '../lib/bhre/source/bhre_source_evaluator.dart';
import '../lib/bhre/source/bhre_source_fetch_result.dart';
import '../lib/bhre/source/bhre_source_kind.dart';

void main() {
  final now = DateTime(2026, 8, 26, 10, 0);

  final freshResult = BhreSourceFetchResult.success(
    sourceId: 'bmkg',
    sourceName: 'BMKG',
    sourceKind: BhreSourceKind.government,
    query: 'Gempa terbaru di Indonesia',
    content: 'Gempa M 5.2 terdeteksi.',
    fetchedAt: now,
  );

  final oldResult = BhreSourceFetchResult.success(
    sourceId: 'old-source',
    sourceName: 'Old Source',
    sourceKind: BhreSourceKind.government,
    query: 'Gempa terbaru di Indonesia',
    content: 'Data lama.',
    fetchedAt: now.subtract(const Duration(days: 3)),
  );

  final failedResult = BhreSourceFetchResult.failure(
    sourceId: 'failed-source',
    sourceName: 'Failed Source',
    sourceKind: BhreSourceKind.government,
    query: 'Gempa terbaru di Indonesia',
    fetchedAt: now,
    error: 'Connection failed',
  );

  final freshEvidence = BhreSourceEvidence.fromFetch(freshResult);
  final oldEvidence = BhreSourceEvidence.fromFetch(oldResult);
  final failedEvidence = BhreSourceEvidence.fromFetch(failedResult);

  const evaluator = BhreSourceEvaluator();

  final fresh = evaluator.evaluate(
    freshEvidence,
    now: now,
  );

  final old = evaluator.evaluate(
    oldEvidence,
    now: now,
  );

  final failed = evaluator.evaluate(
    failedEvidence,
    now: now,
  );

  stdout.writeln('');
  stdout.writeln('FRESH SOURCE:');
  stdout.writeln(
    '- ${fresh.evidence.sourceId}'
    ' | confidence=${fresh.confidence}'
    ' | verified=${fresh.verified}'
    ' | fresh=${fresh.fresh}',
  );

  stdout.writeln('');
  stdout.writeln('OLD SOURCE:');
  stdout.writeln(
    '- ${old.evidence.sourceId}'
    ' | confidence=${old.confidence}'
    ' | verified=${old.verified}'
    ' | fresh=${old.fresh}',
  );

  stdout.writeln('');
  stdout.writeln('FAILED SOURCE:');
  stdout.writeln(
    '- ${failed.evidence.sourceId}'
    ' | confidence=${failed.confidence}'
    ' | verified=${failed.verified}'
    ' | fresh=${failed.fresh}',
  );

  if (!fresh.fresh) {
    throw StateError(
      'Fresh source harus dikenali sebagai fresh.',
    );
  }

  if (fresh.confidence != 1.0) {
    throw StateError(
      'Fresh usable source harus memiliki confidence 1.0.',
    );
  }

  if (!fresh.verified) {
    throw StateError(
      'Fresh usable source harus verified.',
    );
  }

  if (old.fresh) {
    throw StateError(
      'Source berumur tiga hari tidak boleh dianggap fresh.',
    );
  }

  if (old.confidence != 0.75) {
    throw StateError(
      'Source lama yang usable harus memiliki confidence 0.75.',
    );
  }

  if (!old.verified) {
    throw StateError(
      'Source lama yang usable tetap dapat diverifikasi.',
    );
  }

  if (failed.confidence != 0.0) {
    throw StateError(
      'Failed source harus memiliki confidence 0.0.',
    );
  }

  if (failed.verified) {
    throw StateError(
      'Failed source tidak boleh verified.',
    );
  }

  stdout.writeln('');
  stdout.writeln('BHRE SOURCE EVALUATOR TEST: PASS');
}
