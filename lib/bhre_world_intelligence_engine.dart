import 'bhre_world_analyzer.dart';
import 'bhre_world_source.dart';
import 'bhre_world_database.dart';
import 'bhre_world_event.dart';
import 'bhre_world_ingestor.dart';
import 'bhre_world_intelligence.dart';
import 'bhre_world_source_manager.dart';

class BhreWorldIntelligenceSnapshot {
  final DateTime generatedAt;
  final int totalStoredEvents;
  final int todayEvents;
  final int importantEvents;

  final List<BhreWorldCluster> clusters;
  final List<BhreWorldTrend> trends;
  final List<BhreWorldEvent> topEvents;

  final BhreWorldDailyReport dailyReport;

  const BhreWorldIntelligenceSnapshot({
    required this.generatedAt,
    required this.totalStoredEvents,
    required this.todayEvents,
    required this.importantEvents,
    required this.clusters,
    required this.trends,
    required this.topEvents,
    required this.dailyReport,
  });

  bool get hasImportantEvents => importantEvents > 0;

  String get summary {
    if (todayEvents == 0) {
      return 'Belum ada peristiwa dunia yang tercatat untuk hari ini.';
    }

    return 'Hari ini Bree mencatat $todayEvents peristiwa '
        'dengan $importantEvents peristiwa penting '
        'dan ${clusters.length} kelompok peristiwa.';
  }
}

class BhreWorldIntelligenceEngine {
  final BhreWorldDatabase database;
  final BhreWorldIngestor ingestor;
  final BhreWorldAnalyzer analyzer;
  final BhreWorldIntelligence intelligence;
  final BhreWorldSourceManager sourceManager;

  BhreWorldIntelligenceEngine({
    BhreWorldDatabase? database,
    BhreWorldIngestor? ingestor,
    BhreWorldAnalyzer? analyzer,
    BhreWorldIntelligence? intelligence,
    BhreWorldSourceManager? sourceManager,
  }) : database = database ?? BhreWorldDatabase(),
       ingestor = ingestor ?? BhreWorldIngestor(),
       analyzer = analyzer ?? BhreWorldAnalyzer(),
       intelligence = intelligence ?? BhreWorldIntelligence(),
       sourceManager = sourceManager ?? BhreWorldSourceManager();

  Future<BhreWorldSyncReport> synchronize({DateTime? since}) async {
    final report = await sourceManager.sync(since: since);

    if (report.addedEvents > 0) {
      final events = sourceManager.ingestor.events;

      await database.saveAll(events);
    }

    return report;
  }

  Future<BhreWorldIntelligenceSnapshot> analyze({int eventLimit = 1000}) async {
    final events = await database.latest(limit: eventLimit);

    final now = DateTime.now();

    final startOfToday = DateTime(now.year, now.month, now.day);

    final startOfTomorrow = startOfToday.add(const Duration(days: 1));

    final startOfYesterday = startOfToday.subtract(const Duration(days: 1));

    final today = events
        .where((event) {
          return !event.publishedAt.isBefore(startOfToday) &&
              event.publishedAt.isBefore(startOfTomorrow);
        })
        .toList(growable: false);

    final yesterday = events
        .where((event) {
          return !event.publishedAt.isBefore(startOfYesterday) &&
              event.publishedAt.isBefore(startOfToday);
        })
        .toList(growable: false);

    final clusters = analyzer.cluster(today);

    final trends = analyzer.detectTrends(current: today, previous: yesterday);

    final importantEvents = today
        .where((event) => event.importance >= 0.70)
        .toList(growable: false);

    final topEvents = [...today]
      ..sort((a, b) {
        final importance = b.importance.compareTo(a.importance);

        if (importance != 0) {
          return importance;
        }

        return b.publishedAt.compareTo(a.publishedAt);
      });

    final dailyReport = await _buildDailyReport(startOfToday);

    return BhreWorldIntelligenceSnapshot(
      generatedAt: DateTime.now(),
      totalStoredEvents: await database.count(),
      todayEvents: today.length,
      importantEvents: importantEvents.length,
      clusters: List.unmodifiable(clusters),
      trends: List.unmodifiable(trends),
      topEvents: List.unmodifiable(topEvents.take(20)),
      dailyReport: dailyReport,
    );
  }

  Future<BhreWorldDailyReport> _buildDailyReport(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);

    return intelligence.analyzeDate(start);
  }

  Future<List<BhreWorldEvent>> search(String query, {int limit = 50}) async {
    return database.search(query, limit: limit);
  }

  Future<List<BhreWorldEvent>> latest({int limit = 50}) async {
    return database.latest(limit: limit);
  }

  Future<List<BhreWorldEvent>> important({
    double minimumImportance = 0.70,
    int limit = 50,
  }) async {
    return database.important(
      minimumImportance: minimumImportance,
      limit: limit,
    );
  }

  void registerSource(BhreWorldSource source) {
    sourceManager.register(source);
  }

  void unregisterSource(String sourceId) {
    sourceManager.unregister(sourceId);
  }

  List<BhreWorldSource> get sources => sourceManager.sources;

  Future<void> close() async {
    await database.close();
  }
}
