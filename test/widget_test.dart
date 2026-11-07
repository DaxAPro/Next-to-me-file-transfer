import 'package:flutter_test/flutter_test.dart';
import 'package:next_to_me/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const NextToMeApp());
    expect(find.text('NextToMe'), findsWidgets);
  });
}
