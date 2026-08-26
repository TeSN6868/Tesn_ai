import '../lib/bhre/agent/bhre_intent_router.dart';

void main() {
  const inputs = [
    'Buka percakapan dengan Andi',
    'buka percakapan dengan Andi',
    'Tolong buka percakapan dengan Andi',
  ];

  final router = BhreIntentRouter();

  for (final input in inputs) {
    final intent = router.route(input);
    print(input);
    print('  => ${intent.type}');
  }
}
