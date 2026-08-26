import '../detail/bhre_detail.dart';
import '../knowledge/bhre_understanding.dart';
import 'bhre_goal.dart';
import 'bhre_context_store.dart';

class BhreGoalManager {
  final BhreContextStore contextStore;
  final List<BhreGoal> _goals = [];

  BhreGoalManager(this.contextStore);

  List<BhreGoal> get goals =>
      List.unmodifiable(_goals);

  BhreGoal? get latest =>
      _goals.isEmpty ? null : _goals.last;

  BhreGoal? createFromUnderstanding(
    BhreUnderstanding understanding,
  ) {
    final action = _findAction(understanding.details);

    if (action == null) {
      return null;
    }

    final target = _resolveTarget(understanding);

    final scheduledTime = _findTemporal(
      understanding.details,
    );

    final goal = BhreGoal(
      id:
          'goal-${DateTime.now().microsecondsSinceEpoch}',
      action: action,
      target: target,
      scheduledTime: scheduledTime,
      createdAt: DateTime.now(),
      confidence: _goalConfidence(
        understanding.details,
      ),
    );

    _goals.add(goal);
    return goal;
  }

  String? _findAction(
    List<BhreDetail> details,
  ) {
    for (final detail in details) {
      if (detail.type == BhreDetailType.action) {
        return detail.value;
      }
    }

    return null;
  }

  String? _findTemporal(
    List<BhreDetail> details,
  ) {
    for (final detail in details) {
      if (detail.type == BhreDetailType.date ||
          detail.type == BhreDetailType.time) {
        return detail.value;
      }
    }

    return null;
  }

  String? _resolveTarget(
    BhreUnderstanding understanding,
  ) {
    final details = understanding.details;

    // ============================================================
    // 1. REFERENCE HARUS DIPROSES TERLEBIH DAHULU.
    //
    // Contoh:
    //   "Besok ingatkan saya mengambilnya."
    //
    // "-nya" tidak boleh dianggap sebagai entity baru.
    // Ia menunjuk kepada sesuatu dari konteks sebelumnya.
    // ============================================================
    final hasReference = details.any(
      (detail) =>
          detail.type == BhreDetailType.reference ||
          detail.metadata['kind'] == 'entityReference',
    );

    if (hasReference) {
      final previousObjects = contextStore.facts.where(
        (fact) =>
            fact.metadata['entityType'] == 'object',
      ).toList();

      if (previousObjects.isNotEmpty) {
        // Pilih object yang merupakan benda utama.
        //
        // Dalam:
        //   dokumen berada di meja
        //
        // "ambilnya" -> dokumen
        // bukan -> meja
        //
        // Untuk sementara kita menggunakan riwayat entity,
        // bukan entity hasil merge turn sekarang.
        return previousObjects.first.value;
      }
    }

    // ============================================================
    // 2. Object eksplisit dari input sekarang.
    // ============================================================
    for (final detail in details) {
      if (detail.type == BhreDetailType.object) {
        return detail.value;
      }
    }

    // ============================================================
    // 3. Fallback object dari memory.
    // ============================================================
    final previousObjects = contextStore.facts.where(
      (fact) =>
          fact.metadata['entityType'] == 'object',
    ).toList();

    if (previousObjects.isNotEmpty) {
      return previousObjects.last.value;
    }

    // ============================================================
    // 4. Person/place sebagai fallback.
    // ============================================================
    for (final entity in understanding.graph.entities) {
      final type = entity.type.name;

      if (type == 'person' ||
          type == 'place') {
        return entity.value;
      }
    }

    return null;
  }

  double _goalConfidence(
    List<BhreDetail> details,
  ) {
    final relevant = details.where(
      (detail) =>
          detail.type == BhreDetailType.action ||
          detail.type == BhreDetailType.object ||
          detail.type == BhreDetailType.date ||
          detail.type == BhreDetailType.time,
    );

    if (relevant.isEmpty) {
      return 0.0;
    }

    return relevant.fold<double>(
          0.0,
          (sum, detail) =>
              sum + detail.confidence,
        ) /
        relevant.length;
  }
}
