import 'bhre_world_event.dart';
import 'bhre_world_ingestor.dart';

class BhreWorldDailyReport {
  final DateTime date;
  final int totalEvents;
  final int importantEvents;
  final Map<BhreWorldCategory, int> categoryCounts;
  final List<BhreWorldEvent> topEvents;
  final List<String> countries;
  final DateTime generatedAt;

  const BhreWorldDailyReport({
    required this.date,
    required this.totalEvents,
    required this.importantEvents,
    required this.categoryCounts,
    required this.topEvents,
    required this.countries,
    required this.generatedAt,
  });

  List<BhreWorldCategory> get dominantCategories {
    final entries = categoryCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return entries
        .take(3)
        .map((entry) => entry.key)
        .toList(growable: false);
  }

  String get summary {
    if (totalEvents == 0) {
      return 'Belum ada informasi dunia yang tersimpan untuk hari ini.';
    }

    final categories = dominantCategories
        .map((category) => category.name)
        .join(', ');

    return 'Hari ini terdapat $totalEvents peristiwa '
        'yang tercatat, dengan $importantEvents peristiwa '
        'berprioritas tinggi. Topik dominan: $categories.';
  }
}

class BhreWorldIntelligence {
  final BhreWorldIngestor ingestor;

  BhreWorldIntelligence({
    BhreWorldIngestor? ingestor,
  }) : ingestor = ingestor ?? BhreWorldIngestor();

  Future<BhreWorldDailyReport> analyzeToday() async {
    final now = DateTime.now();

    final start = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final end = start.add(
      const Duration(days: 1),
    );

    final today = ingestor.events.where((event) {
      return !event.publishedAt.isBefore(start) &&
          event.publishedAt.isBefore(end);
    }).toList(growable: false);

    return _buildReport(
      date: start,
      events: today,
    );
  }

  Future<BhreWorldDailyReport> analyzeDate(
    DateTime date,
  ) async {
    final start = DateTime(
      date.year,
      date.month,
      date.day,
    );

    final end = start.add(
      const Duration(days: 1),
    );

    final events = ingestor.events.where((event) {
      return !event.publishedAt.isBefore(start) &&
          event.publishedAt.isBefore(end);
    }).toList(growable: false);

    return _buildReport(
      date: start,
      events: events,
    );
  }

  List<BhreWorldEvent> trending({
    int limit = 10,
  }) {
    final events = [...ingestor.events];

    events.sort(
      (a, b) {
        final importance =
            b.importance.compareTo(a.importance);

        if (importance != 0) {
          return importance;
        }

        return b.publishedAt.compareTo(a.publishedAt);
      },
    );

    return events
        .take(limit)
        .toList(growable: false);
  }

  List<BhreWorldEvent> related(
    String query, {
    int limit = 10,
  }) {
    return ingestor.search(
      query,
      limit: limit,
    );
  }

  BhreWorldDailyReport _buildReport({
    required DateTime date,
    required List<BhreWorldEvent> events,
  }) {
    final categoryCounts =
        <BhreWorldCategory, int>{};

    final countries = <String>{};

    for (final event in events) {
      categoryCounts[event.category] =
          (categoryCounts[event.category] ?? 0) + 1;

      if (event.country.trim().isNotEmpty) {
        countries.add(event.country.trim());
      }
    }

    final importantEvents = events
        .where((event) => event.importance >= 0.70)
        .length;

    final topEvents = [...events]
      ..sort(
        (a, b) {
          final importance =
              b.importance.compareTo(a.importance);

          if (importance != 0) {
            return importance;
          }

          return b.publishedAt.compareTo(a.publishedAt);
        },
      );

    return BhreWorldDailyReport(
      date: date,
      totalEvents: events.length,
      importantEvents: importantEvents,
      categoryCounts: Map.unmodifiable(categoryCounts),
      topEvents: topEvents
          .take(10)
          .toList(growable: false),
      countries: countries.toList(growable: false),
      generatedAt: DateTime.now(),
    );
  }
}
