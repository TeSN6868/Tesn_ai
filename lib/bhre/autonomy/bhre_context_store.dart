import 'bhre_context_fact.dart';

class BhreContextStore {
  final int maxFacts;
  final List<BhreContextFact> _facts = [];

  BhreContextStore({
    this.maxFacts = 500,
  }) : assert(maxFacts > 0);

  List<BhreContextFact> get facts =>
      List.unmodifiable(_facts);

  void add(BhreContextFact fact) {
    _facts.add(fact);

    if (_facts.length > maxFacts) {
      _facts.removeRange(
        0,
        _facts.length - maxFacts,
      );
    }
  }

  List<BhreContextFact> find(String query) {
    final normalized = query.trim().toLowerCase();

    if (normalized.isEmpty) {
      return const [];
    }

    return List.unmodifiable(
      _facts.where(
        (fact) =>
            fact.value.toLowerCase().contains(normalized),
      ),
    );
  }

  List<BhreContextFact> recent([int count = 20]) {
    if (_facts.isEmpty || count <= 0) {
      return const [];
    }

    final start =
        _facts.length > count
            ? _facts.length - count
            : 0;

    return List.unmodifiable(
      _facts.sublist(start),
    );
  }

  void clear() {
    _facts.clear();
  }
}
