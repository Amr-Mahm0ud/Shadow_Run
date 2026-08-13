import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadow_run/core/theme/app_theme.dart';
import 'package:shadow_run/data/local/key_value_store.dart';
import 'package:shadow_run/features/characters/characters_screen.dart';
import 'package:shadow_run/services/service_locator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await AppServices.init(storageOverride: MemoryStore());
  });

  testWidgets('Characters screen fits iPhone landscape height', (tester) async {
    // Matches the overflowing constraints from the device log (~715×326 body).
    await tester.binding.setSurfaceSize(const Size(852, 393));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: const CharactersScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('OPERATIVES'), findsOneWidget);
    expect(find.text('RUNNER'), findsWidgets);
    expect(find.textContaining('COINS'), findsOneWidget);
  });
}
