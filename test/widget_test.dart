import 'package:flutter_test/flutter_test.dart';
import 'package:eco_gestao/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const EcoGestaoApp());
    expect(find.text('EcoGestão'), findsWidgets);
  });
}
