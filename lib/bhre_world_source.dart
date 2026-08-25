import 'bhre_world_event.dart';

abstract class BhreWorldSource {
  String get id;

  String get name;

  Future<List<BhreWorldEvent>> fetch({
    DateTime? since,
  });
}

class BhreWorldSourceResult {
  final String sourceId;
  final String sourceName;
  final List<BhreWorldEvent> events;
  final DateTime fetchedAt;
  final String? error;

  const BhreWorldSourceResult({
    required this.sourceId,
    required this.sourceName,
    required this.events,
    required this.fetchedAt,
    this.error,
  });

  bool get success => error == null;

  int get count => events.length;
}
