import '../models/bhre_context.dart';
import '../perception/bhre_observation.dart';
import 'bhre_memory_entry.dart';

class BhreMemory {
  final int maxEntries;
  final List<BhreMemoryEntry> _entries = [];

  BhreMemory({
    this.maxEntries = 200,
  }) : assert(maxEntries > 0);

  List<BhreMemoryEntry> get entries =>
      List.unmodifiable(_entries);

  BhreMemoryEntry? get latest =>
      _entries.isEmpty ? null : _entries.last;

  void remember({
    required String content,
    required BhreObservationType type,
    required BhreContext context,
    String? id,
    DateTime? timestamp,
  }) {
    final entry = BhreMemoryEntry(
      id: id ?? 'memory-${DateTime.now().microsecondsSinceEpoch}',
      content: content,
      type: type,
      context: context,
      timestamp: timestamp ?? DateTime.now(),
    );

    _entries.add(entry);

    if (_entries.length > maxEntries) {
      _entries.removeRange(
        0,
        _entries.length - maxEntries,
      );
    }
  }

  List<BhreMemoryEntry> recent([int count = 10]) {
    if (count <= 0 || _entries.isEmpty) {
      return const [];
    }

    final start =
        _entries.length > count ? _entries.length - count : 0;

    return List.unmodifiable(
      _entries.sublist(start),
    );
  }

  List<BhreMemoryEntry> search(String query) {
    final normalized = query.trim().toLowerCase();

    if (normalized.isEmpty) {
      return const [];
    }

    return List.unmodifiable(
      _entries.where(
        (entry) =>
            entry.content.toLowerCase().contains(normalized),
      ),
    );
  }

  void clear() {
    _entries.clear();
  }
}
