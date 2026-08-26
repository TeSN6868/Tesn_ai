import '../models/bhre_context.dart';

class BhreContextManager {
  BhreContext? _current;

  BhreContext? get current => _current;

  bool get hasContext => _current != null;

  void setContext(BhreContext context) {
    _current = context;
  }

  void clear() {
    _current = null;
  }

  BhreContext ensureContext({
    String? sessionId,
    String? userId,
    BhreSource source = BhreSource.bjo,
    String locale = 'id-ID',
  }) {
    final existing = _current;
    if (existing != null) return existing;

    final context = BhreContext(
      sessionId:
          sessionId ??
          'bhre-${DateTime.now().microsecondsSinceEpoch}',
      userId: userId,
      source: source,
      locale: locale,
      createdAt: DateTime.now(),
    );

    _current = context;
    return context;
  }
}
