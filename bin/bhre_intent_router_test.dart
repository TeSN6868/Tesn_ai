import '../lib/integration/bjo_intent.dart';
import '../lib/integration/bhre_intent_router.dart';

void expectIntent(
  BhreIntentRouter router,
  String text,
  BJoIntentType expected,
) {
  final result = router.route(text);

  if (result.type != expected) {
    throw StateError(
      'Intent salah untuk "$text": '
      '${result.type}, expected $expected',
    );
  }
}

void main() {
  final router = BhreIntentRouter();

  expectIntent(
    router,
    'Halo BJo',
    BJoIntentType.chat,
  );

  expectIntent(
    router,
    'Tolong carikan berita terbaru',
    BJoIntentType.search,
  );

  expectIntent(
    router,
    'Panggil Raden',
    BJoIntentType.call,
  );

  expectIntent(
    router,
    'Dimana posisi saya?',
    BJoIntentType.location,
  );

  expectIntent(
    router,
    'Buka pengaturan',
    BJoIntentType.system,
  );

  expectIntent(
    router,
    '',
    BJoIntentType.unknown,
  );

  print('BHRE INTENT ROUTER TEST: PASS');
}
