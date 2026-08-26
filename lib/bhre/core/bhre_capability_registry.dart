import 'bhre_capability.dart';

class BhreCapabilityRegistry {
  final Map<String, BhreCapability> _capabilities = {};

  Iterable<BhreCapability> get all => _capabilities.values;

  void register(BhreCapability capability) {
    _capabilities[capability.id] = capability;
  }

  BhreCapability? get(String id) {
    return _capabilities[id];
  }

  bool contains(String id) {
    return _capabilities.containsKey(id);
  }

  Future<void> initializeAll() async {
    for (final capability in _capabilities.values) {
      await capability.initialize();
    }
  }

  Future<void> disposeAll() async {
    for (final capability in _capabilities.values) {
      await capability.dispose();
    }
  }
}
