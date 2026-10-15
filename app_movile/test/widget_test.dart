import 'package:flutter_test/flutter_test.dart';
import 'package:sabores_de_huaraz/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SaboresDeHuarazApp());
    expect(find.byType(SaboresDeHuarazApp), findsOneWidget);
  });
}
