import '../detail/bhre_detail.dart';
import '../knowledge/bhre_understanding.dart';
import 'bhre_autonomous_state.dart';
import 'bhre_context_fact.dart';
import 'bhre_context_store.dart';
import 'bhre_goal_manager.dart';
import 'bhre_temporal_reasoner.dart';

class BhreAutonomousEngine {
  final BhreContextStore contextStore;
  final BhreTemporalReasoner temporalReasoner;
  late final BhreGoalManager goalManager;

  BhreAutonomousEngine({
    BhreContextStore? contextStore,
    BhreTemporalReasoner? temporalReasoner,
  })  : contextStore =
            contextStore ?? BhreContextStore(),
        temporalReasoner =
            temporalReasoner ?? const BhreTemporalReasoner() {
    goalManager = BhreGoalManager(this.contextStore);
  }

  BhreAutonomousState process(
    BhreUnderstanding understanding,
  ) {
    final details = understanding.details;

    temporalReasoner.rememberTemporalDetails(
      details,
      contextStore,
    );

    _rememberEntities(understanding);

    final goal =
        goalManager.createFromUnderstanding(
      understanding,
    );

    final hasGoal = goal != null;

    final hasMemory =
        contextStore.facts.isNotEmpty;

    final referenceDetails =
        details.where(
      (detail) =>
          detail.type == BhreDetailType.reference &&
          detail.metadata['kind'] ==
              'entityReference',
    );

    final requiresClarification =
        referenceDetails.isNotEmpty &&
        understanding.referenceDecisions.isEmpty;

    String? nextAction;

    if (requiresClarification) {
      nextAction = 'clarify_reference';
    } else if (hasGoal) {
      nextAction = 'continue_goal';
    } else if (hasMemory) {
      nextAction = 'maintain_context';
    } else {
      nextAction = 'respond';
    }

    return BhreAutonomousState(
      hasContext: details.isNotEmpty,
      hasMemory: hasMemory,
      hasGoal: hasGoal,
      requiresClarification:
          requiresClarification,
      nextAction: nextAction,
      confidence:
          _calculateConfidence(details),
    );
  }

  void _rememberEntities(
    BhreUnderstanding understanding,
  ) {
    for (final entity
        in understanding.graph.entities) {
      // Waktu bukan entity dunia.
      //
      // time/date sudah ditangani oleh
      // BhreTemporalReasoner.
      final type = entity.type.name;

      if (type == 'time' ||
          type == 'date') {
        continue;
      }

      contextStore.add(
        BhreContextFact(
          id:
              'entity-${DateTime.now().microsecondsSinceEpoch}',
          type: BhreFactType.entity,
          value: entity.value,
          createdAt: DateTime.now(),
          confidence: entity.confidence,
          metadata: {
            'entityType': type,
            'entityId': entity.id,
          },
        ),
      );
    }
  }

  double _calculateConfidence(
    List<BhreDetail> details,
  ) {
    if (details.isEmpty) {
      return 0.0;
    }

    final total = details.fold<double>(
      0.0,
      (sum, detail) =>
          sum + detail.confidence,
    );

    return total / details.length;
  }
}
