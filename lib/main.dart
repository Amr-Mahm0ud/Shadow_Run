import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get_storage/get_storage.dart';

import 'core/config/orientation_config.dart';
import 'core/constants/app_constants.dart';
import 'core/l10n/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/responsive.dart';
import 'features/settings/settings_screen.dart';
import 'features/splash/loading_screen.dart';
import 'services/service_locator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await OrientationConfig.lockLandscape();
  await GetStorage.init();
  await AppServices.init();
  runApp(const ShadowRunApp());
}

class ShadowRunApp extends StatefulWidget {
  const ShadowRunApp({super.key});

  @override
  State<ShadowRunApp> createState() => _ShadowRunAppState();
}

class _ShadowRunAppState extends State<ShadowRunApp>
    with WidgetsBindingObserver {
  final _settingsTick = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppServices.feedback.syncMusic();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _settingsTick.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Only react to true backgrounding — `inactive` fires during
    // navigation/orientation and was killing BGM mid-run.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      AppServices.feedback.pauseMusic();
    } else if (state == AppLifecycleState.resumed) {
      AppServices.feedback.syncMusic();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsScope(
      notifier: _settingsTick,
      child: ValueListenableBuilder<int>(
        valueListenable: _settingsTick,
        builder: (context, _, __) {
          final localeCode = AppServices.settings.read().localeCode;
          final locale = Locale(localeCode);
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.dark(),
            locale: locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            builder: (context, child) {
              return ResponsiveAppFrame(
                child: child ?? const SizedBox.shrink(),
              );
            },
            home: const LoadingScreen(),
          );
        },
      ),
    );
  }
}
