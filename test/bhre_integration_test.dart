import 'package:flutter_test/flutter_test.dart';
import '../lib/integration/bhre_integration.dart';

void main() {
  test('BHRE integration smoke test', () async {
    final bhre = BhreIntegration();

    await bhre.start();

    expect(await bhre.app.isStarted, true);

    final response = await bhre.sendMessage('Halo BHRE');

    expect(response, 'Aku mendengarkan: Halo BHRE');

    await bhre.stop();

    expect(bhre.app.isStarted, false);
  });
}
