import '../knowledge/bhre_knowledge_domain.dart';
import '../knowledge/bhre_knowledge_request.dart';
import 'bhre_source_plan.dart';
import 'bhre_source_kind.dart';

class BhreSourcePlanner {
  const BhreSourcePlanner();

  BhreSourcePlan plan(BhreKnowledgeRequest request) {
    final domain = request.domain;
    final type = request.type;

    final fresh =
        type == BhreKnowledgeRequestType.latest ||
        type == BhreKnowledgeRequestType.current;

    switch (domain) {
      case BhreKnowledgeDomain.finance:
        return BhreSourcePlan(
          query: request.query,
          preferredSources: const [
            BhreSourceKind.financial,
            BhreSourceKind.official,
            BhreSourceKind.news,
          ],
          minimumSources:
              type == BhreKnowledgeRequestType.analysis ? 2 : 1,
          requiresVerification: true,
          requiresFreshData: true,
          priority: BhreSourcePriority.primary,
        );

      case BhreKnowledgeDomain.business:
        return BhreSourcePlan(
          query: request.query,
          preferredSources: const [
            BhreSourceKind.official,
            BhreSourceKind.financial,
            BhreSourceKind.news,
          ],
          minimumSources:
              type == BhreKnowledgeRequestType.analysis ? 2 : 1,
          requiresVerification: true,
          requiresFreshData: fresh,
          priority: BhreSourcePriority.primary,
        );

      case BhreKnowledgeDomain.economy:
        return BhreSourcePlan(
          query: request.query,
          preferredSources: const [
            BhreSourceKind.financial,
            BhreSourceKind.government,
            BhreSourceKind.news,
          ],
          minimumSources: type ==
                  BhreKnowledgeRequestType.analysis
              ? 2
              : 1,
          requiresVerification: true,
          requiresFreshData: fresh,
          priority: BhreSourcePriority.primary,
        );

      case BhreKnowledgeDomain.naturalDisaster:
        return BhreSourcePlan(
          query: request.query,
          preferredSources: const [
            BhreSourceKind.government,
            BhreSourceKind.scientific,
            BhreSourceKind.news,
          ],
          minimumSources: 2,
          requiresVerification: true,
          requiresFreshData: true,
          priority: BhreSourcePriority.primary,
        );

      case BhreKnowledgeDomain.environment:
        return BhreSourcePlan(
          query: request.query,
          preferredSources: const [
            BhreSourceKind.scientific,
            BhreSourceKind.government,
            BhreSourceKind.news,
          ],
          minimumSources:
              type == BhreKnowledgeRequestType.analysis ? 2 : 1,
          requiresVerification: true,
          requiresFreshData: fresh,
          priority: BhreSourcePriority.primary,
        );

      case BhreKnowledgeDomain.weather:
        return BhreSourcePlan(
          query: request.query,
          preferredSources: const [
            BhreSourceKind.government,
            BhreSourceKind.scientific,
          ],
          minimumSources: 1,
          requiresVerification: true,
          requiresFreshData: true,
          priority: BhreSourcePriority.primary,
        );

      case BhreKnowledgeDomain.it:
        return BhreSourcePlan(
          query: request.query,
          preferredSources: const [
            BhreSourceKind.documentation,
            BhreSourceKind.official,
            BhreSourceKind.news,
          ],
          minimumSources:
              type == BhreKnowledgeRequestType.analysis ? 2 : 1,
          requiresVerification: true,
          requiresFreshData: fresh,
          priority: BhreSourcePriority.primary,
        );

      case BhreKnowledgeDomain.technology:
        return BhreSourcePlan(
          query: request.query,
          preferredSources: const [
            BhreSourceKind.documentation,
            BhreSourceKind.official,
            BhreSourceKind.news,
          ],
          minimumSources: type ==
                  BhreKnowledgeRequestType.analysis
              ? 2
              : 1,
          requiresVerification: true,
          requiresFreshData: fresh,
          priority: BhreSourcePriority.secondary,
        );

      case BhreKnowledgeDomain.education:
        return BhreSourcePlan(
          query: request.query,
          preferredSources: const [
            BhreSourceKind.official,
            BhreSourceKind.reference,
            BhreSourceKind.scientific,
          ],
          minimumSources:
              type == BhreKnowledgeRequestType.analysis ? 2 : 1,
          requiresVerification: true,
          requiresFreshData: fresh,
          priority: BhreSourcePriority.primary,
        );

      case BhreKnowledgeDomain.science:
        return BhreSourcePlan(
          query: request.query,
          preferredSources: const [
            BhreSourceKind.scientific,
            BhreSourceKind.reference,
          ],
          minimumSources: 2,
          requiresVerification: true,
          requiresFreshData: fresh,
          priority: BhreSourcePriority.primary,
        );

      case BhreKnowledgeDomain.culture:
        return BhreSourcePlan(
          query: request.query,
          preferredSources: const [
            BhreSourceKind.official,
            BhreSourceKind.reference,
            BhreSourceKind.news,
          ],
          minimumSources:
              type == BhreKnowledgeRequestType.analysis ? 2 : 1,
          requiresVerification: true,
          requiresFreshData: fresh,
          priority: BhreSourcePriority.secondary,
        );

      case BhreKnowledgeDomain.history:
        return BhreSourcePlan(
          query: request.query,
          preferredSources: const [
            BhreSourceKind.reference,
            BhreSourceKind.scientific,
          ],
          minimumSources: 2,
          requiresVerification: true,
          requiresFreshData: false,
          priority: BhreSourcePriority.secondary,
        );

      case BhreKnowledgeDomain.politics:
      case BhreKnowledgeDomain.social:
      case BhreKnowledgeDomain.news:
        return BhreSourcePlan(
          query: request.query,
          preferredSources: const [
            BhreSourceKind.official,
            BhreSourceKind.government,
            BhreSourceKind.news,
          ],
          minimumSources: 2,
          requiresVerification: true,
          requiresFreshData: true,
          priority: BhreSourcePriority.primary,
        );

      case BhreKnowledgeDomain.sports:
        return BhreSourcePlan(
          query: request.query,
          preferredSources: const [
            BhreSourceKind.official,
            BhreSourceKind.news,
          ],
          minimumSources: 1,
          requiresVerification: true,
          requiresFreshData: true,
          priority: BhreSourcePriority.primary,
        );

      case BhreKnowledgeDomain.health:
        return BhreSourcePlan(
          query: request.query,
          preferredSources: const [
            BhreSourceKind.government,
            BhreSourceKind.scientific,
            BhreSourceKind.official,
          ],
          minimumSources: 2,
          requiresVerification: true,
          requiresFreshData: fresh,
          priority: BhreSourcePriority.primary,
        );

      case BhreKnowledgeDomain.local:
        return BhreSourcePlan(
          query: request.query,
          preferredSources: const [
            BhreSourceKind.government,
            BhreSourceKind.official,
            BhreSourceKind.news,
            BhreSourceKind.generalWeb,
          ],
          minimumSources:
              type == BhreKnowledgeRequestType.analysis ? 2 : 1,
          requiresVerification: true,
          requiresFreshData: fresh,
          priority: BhreSourcePriority.primary,
        );

      case BhreKnowledgeDomain.general:
      case BhreKnowledgeDomain.unknown:
        return BhreSourcePlan(
          query: request.query,
          preferredSources: const [
            BhreSourceKind.official,
            BhreSourceKind.reference,
            BhreSourceKind.news,
            BhreSourceKind.generalWeb,
          ],
          minimumSources: 1,
          requiresVerification: true,
          requiresFreshData: fresh,
          priority: BhreSourcePriority.tertiary,
        );
    }
  }
}
