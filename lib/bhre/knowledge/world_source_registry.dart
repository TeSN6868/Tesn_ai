import 'world_source.dart';

class BhreWorldSourceRegistry {
  final Map<String, BhreWorldSource> _sources = {};

  void register(BhreWorldSource source) {
    _sources[source.id] = source;
  }

  List<BhreWorldSource> get enabledSources {
    return _sources.values
        .where((source) => source.enabled)
        .toList(growable: false);
  }

  BhreWorldSource? get(String id) {
    return _sources[id];
  }
}
