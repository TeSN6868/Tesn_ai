import 'package:flutter_test/flutter_test.dart';
import 'package:m8_messenger/main.dart';

void main() {
  testWidgets('M8 Messenger menampilkan halaman login', (WidgetTester tester) async {
    await tester.pumpWidget(const M8App());

    expect(find.text('M8 Messenger'), findsOneWidget);
    expect(find.text('Email / Nomor HP'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('MASUK KE M8'), findsOneWidget);
    expect(find.text('DAFTAR AKUN M8'), findsOneWidget);
  });
}
