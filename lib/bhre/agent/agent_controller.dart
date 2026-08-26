import '../core/bhre_engine.dart';
import '../core/bhre_event.dart';
import '../core/bhre_response.dart';
import '../core/bhre_bootstrap.dart';
import '../tools/bhre_tool_executor.dart';
import 'agent_goal.dart';

class BhreAgentController {
  final BhreEngine engine;
  final BhreToolExecutor toolExecutor;

  BhreAgentController({
    BhreEngine? engine,
    BhreToolExecutor? toolExecutor,
  })  : engine = engine ?? BhreEngine(),
        toolExecutor = toolExecutor ??
            BhreToolExecutor(
              registry: BhreBootstrap.createToolRegistry(),
            );

  Future<BhreResponse> receive(BhreGoal goal) async {
    final event = BhreEvent(
      type: BhreEventType.userMessage,
      payload: goal.instruction,
    );

    final engineResponse = await engine.handle(event);

    final toolResult = await toolExecutor.execute(goal.instruction);

    if (!toolResult.startsWith('Aku belum memiliki')) {
      return BhreResponse(
        text: toolResult,
        shouldSpeak: true,
        shouldExecuteAction: true,
      );
    }

    return engineResponse;
  }
}
