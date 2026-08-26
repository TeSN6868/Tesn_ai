import 'bhre_observation.dart';

class BhrePerception {
  final int maxObservations;
  final List<BhreObservation> _observations = [];

  BhrePerception({
    this.maxObservations = 100,
  }) : assert(maxObservations > 0);

  List<BhreObservation> get observations =>
      List.unmodifiable(_observations);

  BhreObservation? get latest =>
      _observations.isEmpty ? null : _observations.last;

  void observe(BhreObservation observation) {
    _observations.add(observation);

    if (_observations.length > maxObservations) {
      _observations.removeRange(
        0,
        _observations.length - maxObservations,
      );
    }
  }

  void clear() {
    _observations.clear();
  }
}
