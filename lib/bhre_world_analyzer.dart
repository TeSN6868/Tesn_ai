import 'bhre_world_event.dart';

class BhreWorldCluster {
  final String id;
  final String topic;
  final List<BhreWorldEvent> events;
  final double confidence;
  final double importance;

  const BhreWorldCluster({
    required this.id,
    required this.topic,
    required this.events,
    required this.confidence,
    required this.importance,
  });

  int get sourceCount => events.map((event) => event.source).toSet().length;

  int get countryCount => events.map((event) => event.country).toSet().length;

  BhreWorldEvent get primaryEvent {
    final sorted = [...events]
      ..sort((a, b) {
        final importance = b.importance.compareTo(a.importance);

        if (importance != 0) return importance;

        return b.publishedAt.compareTo(a.publishedAt);
      });

    return sorted.first;
  }
}

class BhreWorldTrend {
  final String topic;
  final int currentCount;
  final int previousCount;
  final double growth;
  final double importance;
  final List<BhreWorldEvent> events;

  const BhreWorldTrend({
    required this.topic,
    required this.currentCount,
    required this.previousCount,
    required this.growth,
    required this.importance,
    required this.events,
  });

  bool get accelerating => growth > 0;

  String get direction {
    if (growth > 1.0) return 'MENINGKAT TAJAM';
    if (growth > 0.25) return 'MENINGKAT';
    if (growth < -0.25) return 'MENURUN';
    return 'STABIL';
  }
}

class BhreWorldAnalyzer {
  List<BhreWorldCluster> cluster(List<BhreWorldEvent> events) {
    final clusters = <String, List<BhreWorldEvent>>{};

    for (final event in events) {
      final key = _topicKey(event);

      clusters.putIfAbsent(key, () => []);
      clusters[key]!.add(event);
    }

    final result = <BhreWorldCluster>[];

    for (final entry in clusters.entries) {
      final group = entry.value;

      if (group.isEmpty) continue;

      final importance = group
          .map((event) => event.importance)
          .reduce((a, b) => a > b ? a : b);

      final sourceCount = group.map((event) => event.source).toSet().length;

      final confidence = _calculateConfidence(group, sourceCount);

      result.add(
        BhreWorldCluster(
          id: entry.key,
          topic: _buildTopic(group),
          events: List.unmodifiable(group),
          confidence: confidence,
          importance: importance,
        ),
      );
    }

    result.sort((a, b) {
      final importance = b.importance.compareTo(a.importance);

      if (importance != 0) return importance;

      return b.confidence.compareTo(a.confidence);
    });

    return List.unmodifiable(result);
  }

  List<BhreWorldTrend> detectTrends({
    required List<BhreWorldEvent> current,
    required List<BhreWorldEvent> previous,
  }) {
    final currentGroups = _groupByTopic(current);
    final previousGroups = _groupByTopic(previous);

    final trends = <BhreWorldTrend>[];

    for (final entry in currentGroups.entries) {
      final topic = entry.key;
      final currentEvents = entry.value;

      final previousEvents = previousGroups[topic] ?? const [];

      final currentCount = currentEvents.length;
      final previousCount = previousEvents.length;

      final growth = previousCount == 0
          ? 1.0
          : (currentCount - previousCount) / previousCount;

      final importance = currentEvents
          .map((event) => event.importance)
          .reduce((a, b) => a > b ? a : b);

      trends.add(
        BhreWorldTrend(
          topic: topic,
          currentCount: currentCount,
          previousCount: previousCount,
          growth: growth,
          importance: importance,
          events: List.unmodifiable(currentEvents),
        ),
      );
    }

    trends.sort((a, b) {
      final importance = b.importance.compareTo(a.importance);

      if (importance != 0) return importance;

      return b.growth.compareTo(a.growth);
    });

    return List.unmodifiable(trends);
  }

  String _topicKey(BhreWorldEvent event) {
    final words = _normalize(
      event.title,
    ).split(' ').where((word) => word.length >= 4).take(6).toList();

    if (words.isEmpty) {
      return '${event.category.name}:${event.country}';
    }

    return '${event.category.name}:${words.join('-')}';
  }

  String _buildTopic(List<BhreWorldEvent> events) {
    final primary = events.first;

    return primary.title.trim();
  }

  Map<String, List<BhreWorldEvent>> _groupByTopic(List<BhreWorldEvent> events) {
    final result = <String, List<BhreWorldEvent>>{};

    for (final event in events) {
      final key = _topicKey(event);

      result.putIfAbsent(key, () => []);
      result[key]!.add(event);
    }

    return result;
  }

  double _calculateConfidence(List<BhreWorldEvent> events, int sourceCount) {
    var confidence = 0.40;

    if (sourceCount >= 2) {
      confidence += 0.20;
    }

    if (sourceCount >= 3) {
      confidence += 0.15;
    }

    if (events.length >= 3) {
      confidence += 0.10;
    }

    final hasUrl = events.any((event) => event.url.trim().isNotEmpty);

    if (hasUrl) {
      confidence += 0.05;
    }

    if (confidence > 1.0) {
      confidence = 1.0;
    }

    return confidence;
  }

  String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
