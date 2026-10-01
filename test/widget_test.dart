import 'package:flutter_test/flutter_test.dart';
import 'package:teduh/main.dart';

void main() {
  testWidgets('App renders TeduhApp successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const TeduhApp());
    expect(find.byType(TeduhApp), findsOneWidget);
  });
}
