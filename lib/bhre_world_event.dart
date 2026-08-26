enum BhreWorldCategory {
  politics,
  economy,
  technology,
  science,
  health,
  disaster,
  conflict,
  environment,
  sports,
  culture,
  crime,
  transportation,
  other,
}

class BhreWorldEvent {
  final String id;
  final String title;
  final String description;
  final String source;
  final String url;
  final String country;
  final BhreWorldCategory category;
  final DateTime publishedAt;
  final DateTime collectedAt;
  final double importance;

  const BhreWorldEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.source,
    required this.url,
    required this.country,
    required this.category,
    required this.publishedAt,
    required this.collectedAt,
    required this.importance,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'source': source,
      'url': url,
      'country': country,
      'category': category.name,
      'published_at': publishedAt.millisecondsSinceEpoch,
      'collected_at': collectedAt.millisecondsSinceEpoch,
      'importance': importance,
    };
  }

  factory BhreWorldEvent.fromMap(Map<String, Object?> map) {
    final categoryName = map['category'] as String? ?? 'other';

    final category = BhreWorldCategory.values.firstWhere(
      (value) => value.name == categoryName,
      orElse: () => BhreWorldCategory.other,
    );

    return BhreWorldEvent(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      source: map['source'] as String,
      url: map['url'] as String,
      country: map['country'] as String,
      category: category,
      publishedAt: DateTime.fromMillisecondsSinceEpoch(
        map['published_at'] as int,
      ),
      collectedAt: DateTime.fromMillisecondsSinceEpoch(
        map['collected_at'] as int,
      ),
      importance: (map['importance'] as num).toDouble(),
    );
  }
}
