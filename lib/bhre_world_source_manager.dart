import 'bhre_world_ingestor.dart';
import 'bhre_world_source.dart';

class BhreWorldSourceManager {
  final BhreWorldIngestor ingestor;

  final List<BhreWorldSource> _sources = [];

  BhreWorldSourceManager({BhreWorldIngestor? ingestor})
    : ingestor = ingestor ?? BhreWorldIngestor();

  List<BhreWorldSource> get sources => List.unmodifiable(_sources);

  void register(BhreWorldSource source) {
    _sources.removeWhere((item) => item.id == source.id);

    _sources.add(source);
  }

  void unregister(String sourceId) {
    _sources.removeWhere((source) => source.id == sourceId);
  }

  Future<BhreWorldSyncReport> sync({DateTime? since}) async {
    if (_sources.isEmpty) {
      return BhreWorldSyncReport(
        results: const [],
        addedEvents: 0,
        startedAt: DateTime.now(),
        finishedAt: DateTime.now(),
      );
    }

    final startedAt = DateTime.now();

    final futures = _sources.map(
      (source) => _fetchSource(source, since: since),
    );

    final results = await Future.wait(futures);

    var addedEvents = 0;

    for (final result in results) {
      if (!result.success || result.events.isEmpty) {
        continue;
      }

      addedEvents += await ingestor.ingest(result.events);
    }

    return BhreWorldSyncReport(
      results: List.unmodifiable(results),
      addedEvents: addedEvents,
      startedAt: startedAt,
      finishedAt: DateTime.now(),
    );
  }

  Future<BhreWorldSourceResult> _fetchSource(
    BhreWorldSource source, {
    DateTime? since,
  }) async {
    try {
      final events = await source.fetch(since: since);

      return BhreWorldSourceResult(
        sourceId: source.id,
        sourceName: source.name,
        events: List.unmodifiable(events),
        fetchedAt: DateTime.now(),
      );
    } catch (error) {
      return BhreWorldSourceResult(
        sourceId: source.id,
        sourceName: source.name,
        events: const [],
        fetchedAt: DateTime.now(),
        error: error.toString(),
      );
    }
  }

  void clearSources() {
    _sources.clear();
  }
}

class BhreWorldSyncReport {
  final List<BhreWorldSourceResult> results;
  final int addedEvents;
  final DateTime startedAt;
  final DateTime finishedAt;

  const BhreWorldSyncReport({
    required this.results,
    required this.addedEvents,
    required this.startedAt,
    required this.finishedAt,
  });

  int get sourceCount => results.length;

  int get successfulSources => results.where((result) => result.success).length;

  int get failedSources => results.where((result) => !result.success).length;

  int get downloadedEvents =>
      results.fold<int>(0, (total, result) => total + result.count);

  Duration get duration => finishedAt.difference(startedAt);

  bool get success => failedSources == 0;

  String get summary {
    if (sourceCount == 0) {
      return 'Belum ada sumber informasi yang terdaftar.';
    }

    return 'Sinkronisasi selesai: '
        '$successfulSources/$sourceCount sumber berhasil, '
        '$downloadedEvents peristiwa diterima, '
        '$addedEvents peristiwa baru disimpan.';
  }
}
