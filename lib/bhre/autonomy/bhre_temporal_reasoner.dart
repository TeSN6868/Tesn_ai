import '../detail/bhre_detail.dart';
import 'bhre_context_fact.dart';
import 'bhre_context_store.dart';

class BhreTemporalReasoner {
  const BhreTemporalReasoner();

  void rememberTemporalDetails(
    List<BhreDetail> details,
    BhreContextStore store,
  ) {
    for (final detail in details) {
      if (detail.type != BhreDetailType.date &&
          detail.type != BhreDetailType.time) {
        continue;
      }

      store.add(
        BhreContextFact(
          id:
              'temporal-${DateTime.now().microsecondsSinceEpoch}',
          type: BhreFactType.temporal,
          value: detail.value,
          createdAt: DateTime.now(),
          confidence: detail.confidence,
          metadata: {
            'detailType': detail.type.name,
          },
        ),
      );
    }
  }

  String? latestTemporal(
    BhreContextStore store,
  ) {
    final temporalFacts = store.facts
        .where((fact) => fact.type == BhreFactType.temporal)
        .toList();

    if (temporalFacts.isEmpty) {
      return null;
    }

    return temporalFacts.last.value;
  }
}
