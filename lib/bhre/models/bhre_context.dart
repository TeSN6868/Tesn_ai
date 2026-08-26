enum BhreSource {
  bjo,
  system,
  voice,
  notification,
  scheduled,
  location,
  unknown,
}

class BhreContext {
  final String sessionId;
  final String? userId;
  final BhreSource source;
  final String locale;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  const BhreContext({
    required this.sessionId,
    this.userId,
    this.source = BhreSource.unknown,
    this.locale = 'id-ID',
    required this.createdAt,
    this.metadata = const {},
  });

  BhreContext copyWith({
    String? sessionId,
    String? userId,
    BhreSource? source,
    String? locale,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
  }) {
    return BhreContext(
      sessionId: sessionId ?? this.sessionId,
      userId: userId ?? this.userId,
      source: source ?? this.source,
      locale: locale ?? this.locale,
      createdAt: createdAt ?? this.createdAt,
      metadata: metadata ?? this.metadata,
    );
  }
}
