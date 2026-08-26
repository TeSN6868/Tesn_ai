import 'bhre_engine.dart';
import 'bhre_event.dart';
import 'bhre_response.dart';
import 'bhre_state.dart';

class BhreRuntime {
  final BhreEngine engine;

  bool _started = false;

  BhreRuntime({
    BhreEngine? engine,
  }) : engine = engine ?? BhreEngine();

  bool get isStarted => _started;

  BhreState get state => engine.state;

  Future<void> start() async {
    if (_started) return;
    _started = true;
  }

  Future<void> stop() async {
    if (!_started) return;
    _started = false;
  }

  Future<BhreResponse> dispatch(BhreEvent event) async {
    if (!_started) {
      await start();
    }

    return engine.handle(event);
  }
}
