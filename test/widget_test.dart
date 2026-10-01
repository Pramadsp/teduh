import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Sanity widget test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Teduh App Test')),
        ),
      ),
    );
    expect(find.text('Teduh App Test'), findsOneWidget);
  });
}
