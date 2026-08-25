import 'bhre_world_event.dart';

class BhreWorldIngestor {
  final List<BhreWorldEvent> _events = [];

  List<BhreWorldEvent> get events =>
      List.unmodifiable(_events);

  Future<int> ingest(
    List<BhreWorldEvent> incoming,
  ) async {
    var added = 0;

    for (final event in incoming) {
      final exists = _events.any(
        (item) => item.id == event.id,
      );

      if (exists) {
        continue;
      }

      _events.add(event);
      added++;
    }

    _events.sort(
      (a, b) => b.publishedAt.compareTo(a.publishedAt),
    );

    return added;
  }

  List<BhreWorldEvent> latest({
    int limit = 20,
  }) {
    if (limit <= 0) {
      return const [];
    }

    return _events
        .take(limit)
        .toList(growable: false);
  }

  List<BhreWorldEvent> byCategory(
    BhreWorldCategory category, {
    int limit = 20,
  }) {
    return _events
        .where((event) => event.category == category)
        .take(limit)
        .toList(growable: false);
  }

  List<BhreWorldEvent> byCountry(
    String country, {
    int limit = 20,
  }) {
    final clean = country.trim().toLowerCase();

    if (clean.isEmpty) {
      return const [];
    }

    return _events
        .where(
          (event) =>
              event.country.toLowerCase() == clean,
        )
        .take(limit)
        .toList(growable: false);
  }

  List<BhreWorldEvent> important({
    double minimumImportance = 0.70,
    int limit = 20,
  }) {
    return _events
        .where(
          (event) =>
              event.importance >= minimumImportance,
        )
        .take(limit)
        .toList(growable: false);
  }

  List<BhreWorldEvent> search(
    String query, {
    int limit = 20,
  }) {
    final clean = query.trim().toLowerCase();

    if (clean.isEmpty) {
      return const [];
    }

    final words = clean
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toSet();

    final scored = <_ScoredWorldEvent>[];

    for (final event in _events) {
      final title = event.title.toLowerCase();
      final description =
          event.description.toLowerCase();
      final country = event.country.toLowerCase();

      var score = 0;

      for (final word in words) {
        if (title.contains(word)) {
          score += 5;
        }

        if (description.contains(word)) {
          score += 2;
        }

        if (country.contains(word)) {
          score += 4;
        }

        if (event.category.name.contains(word)) {
          score += 3;
        }
      }

      if (score > 0) {
        scored.add(
          _ScoredWorldEvent(
            event: event,
            score: score,
          ),
        );
      }
    }

    scored.sort(
      (a, b) => b.score.compareTo(a.score),
    );

    return scored
        .take(limit)
        .map((item) => item.event)
        .toList(growable: false);
  }

  void clear() {
    _events.clear();
  }
}

class _ScoredWorldEvent {
  final BhreWorldEvent event;
  final int score;

  const _ScoredWorldEvent({
    required this.event,
    required this.score,
  });
}
