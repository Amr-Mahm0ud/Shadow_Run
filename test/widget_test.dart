import 'package:flutter_test/flutter_test.dart';
import 'package:multi_media_game/design/home.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('Home screen loads', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: Home()));
    expect(find.text('Avengers Game'), findsOneWidget);
    expect(find.text('Start Game'), findsOneWidget);
    expect(find.text('High Scores'), findsOneWidget);
  });
}
