import '../data/local/key_value_store.dart';
import '../data/local/local_storage.dart';
import '../data/repositories/high_score_repository.dart';
import '../data/repositories/mission_repository.dart';
import '../data/repositories/progress_repository.dart';
import '../data/repositories/settings_repository.dart';
import 'analytics/analytics_service.dart';
import 'crash_reporting/crash_reporting_service.dart';
import 'feedback/feedback_service.dart';

/// Simple service locator for MVP. Replace with DI package if the graph grows.
class AppServices {
  AppServices._();

  static late final KeyValueStore storage;
  static late final HighScoreRepository highScores;
  static late final ProgressRepository progress;
  static late final SettingsRepository settings;
  static late final MissionRepository missions;
  static late final AnalyticsService analytics;
  static late final CrashReportingService crashReporting;
  static late final FeedbackService feedback;

  static bool _ready = false;
  static bool get isReady => _ready;

  static Future<void> init({KeyValueStore? storageOverride}) async {
    storage = storageOverride ?? LocalStorage();
    highScores = HighScoreRepository(storage);
    progress = ProgressRepository(storage);
    settings = SettingsRepository(storage);
    missions = MissionRepository(storage);
    analytics = AnalyticsService();
    crashReporting = CrashReportingService();
    feedback = FeedbackService();
    await analytics.logAppOpen();
    _ready = true;
  }
}
