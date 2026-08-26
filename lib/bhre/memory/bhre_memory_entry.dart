import '../models/bhre_context.dart';
import '../perception/bhre_observation.dart';

class BhreMemoryEntry {
  final String id;
  final String content;
  final BhreObservationType type;
  final BhreContext context;
  final DateTime timestamp;

  const BhreMemoryEntry({
    required this.id,
    required this.content,
    required this.type,
    required this.context,
    required this.timestamp,
  });
}
