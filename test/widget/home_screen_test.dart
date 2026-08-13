import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadow_run/core/l10n/app_localizations.dart';
import 'package:shadow_run/core/theme/app_theme.dart';
import 'package:shadow_run/data/local/key_value_store.dart';
import 'package:shadow_run/features/home/home_screen.dart';
import 'package:shadow_run/services/service_locator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await AppServices.init(storageOverride: MemoryStore());
  });

  testWidgets('Home screen shows SHADOW//RUN branding and play CTA',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 720));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const HomeScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('SURVIVE THE NIGHT.'), findsOneWidget);
    expect(find.text('Grow stronger each run.'), findsOneWidget);
    expect(find.text('PLAY'), findsOneWidget);
    expect(find.text('Characters'), findsOneWidget);
    expect(find.text('Upgrades'), findsOneWidget);
  });
}
