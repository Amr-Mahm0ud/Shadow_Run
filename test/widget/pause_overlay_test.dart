import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadow_run/core/l10n/app_localizations.dart';
import 'package:shadow_run/core/theme/app_theme.dart';
import 'package:shadow_run/features/gameplay/pause_menu.dart';
import 'package:shadow_run/game/engine/game_phase.dart';

void main() {
  testWidgets('PauseMenu fires resume restart settings home', (tester) async {
    var resumed = false;
    var restarted = false;
    var settings = false;
    var home = false;

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
        home: PauseMenu(
          onResume: () => resumed = true,
          onRestart: () => restarted = true,
          onSettings: () => settings = true,
          onHome: () => home = true,
        ),
      ),
    );

    expect(find.text('PAUSED'), findsOneWidget);

    await tester.tap(find.text('RESUME'));
    await tester.pump();
    expect(resumed, isTrue);

    await tester.tap(find.text('RESTART'));
    await tester.pump();
    expect(restarted, isTrue);

    await tester.tap(find.text('Settings'));
    await tester.pump();
    expect(settings, isTrue);

    await tester.tap(find.text('HOME'));
    await tester.pump();
    expect(home, isTrue);
  });

  test('paused phase blocks gameplay interaction', () {
    expect(GamePhase.paused.isInteractive, isFalse);
    expect(GamePhase.paused.allowsAttack, isFalse);
    expect(GamePhase.playing.isInteractive, isTrue);
  });
}
