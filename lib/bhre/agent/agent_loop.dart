import '../core/bhre_response.dart';
import 'agent_controller.dart';
import 'agent_goal.dart';

class BhreAgentLoop {
  final BhreAgentController controller;

  BhreAgentLoop({
    BhreAgentController? controller,
  }) : controller = controller ?? BhreAgentController();

  Future<BhreResponse> execute(String instruction) {
    final goal = BhreGoal(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      instruction: instruction,
    );

    return controller.receive(goal);
  }
}
