class BhreKnowledgeItem {
  final String id;
  final String title;
  final String content;
  final List<String> tags;
  final DateTime createdAt;

  const BhreKnowledgeItem({
    required this.id,
    required this.title,
    required this.content,
    required this.tags,
    required this.createdAt,
  });
}

class BhreKnowledgeCore {
  final List<BhreKnowledgeItem> _items = [];

  List<BhreKnowledgeItem> get items =>
      List.unmodifiable(_items);

  void add({
    required String id,
    required String title,
    required String content,
    List<String> tags = const [],
  }) {
    final normalizedId = id.trim();

    if (normalizedId.isEmpty) {
      throw ArgumentError('ID knowledge tidak boleh kosong.');
    }

    _items.removeWhere((item) => item.id == normalizedId);

    _items.add(
      BhreKnowledgeItem(
        id: normalizedId,
        title: title.trim(),
        content: content.trim(),
        tags: tags.map((tag) => tag.trim().toLowerCase()).toList(),
        createdAt: DateTime.now(),
      ),
    );
  }

  List<BhreKnowledgeItem> search(String query) {
    final text = query.trim().toLowerCase();

    if (text.isEmpty) return const [];

    final words = text
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toSet();

    final scored = <_ScoredKnowledge>[];

    for (final item in _items) {
      var score = 0;

      final title = item.title.toLowerCase();
      final content = item.content.toLowerCase();

      for (final word in words) {
        if (title.contains(word)) {
          score += 5;
        }

        if (content.contains(word)) {
          score += 2;
        }

        if (item.tags.any((tag) => tag.contains(word))) {
          score += 4;
        }
      }

      if (score > 0) {
        scored.add(
          _ScoredKnowledge(
            item: item,
            score: score,
          ),
        );
      }
    }

    scored.sort(
      (a, b) => b.score.compareTo(a.score),
    );

    return scored
        .map((entry) => entry.item)
        .toList(growable: false);
  }

  void remove(String id) {
    _items.removeWhere((item) => item.id == id);
  }

  void clear() {
    _items.clear();
  }
}

class _ScoredKnowledge {
  final BhreKnowledgeItem item;
  final int score;

  const _ScoredKnowledge({
    required this.item,
    required this.score,
  });
}
