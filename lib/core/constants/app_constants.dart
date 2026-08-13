/// App-wide product constants. Store package IDs stay in native projects.
class AppConstants {
  AppConstants._();

  static const String appName = 'SHADOW//RUN';
  static const String appNameDisplay = 'SHADOW//RUN';
  static const String packageName = 'shadow_run';
  static const String tagline = 'SURVIVE THE NIGHT.';
  static const String taglineSecondary = 'Grow stronger each run.';
  static const String aboutLine = 'SHADOW//RUN — cyberpunk action runner';
  static const String appVersion = '1.0.0';
  static const String privacyContact = 'support@shadowrun.game';

  /// Legacy GetStorage keys — keep reading for migration.
  static const String legacyScoreFirst = 'first';
  static const String legacyScoreSecond = 'second';
  static const String legacyScoreThird = 'third';

  static const String storageHighScores = 'high_scores_v1';
  static const String storageProgress = 'player_progress_v1';
  static const String storageSettings = 'settings_v1';
  static const String storageMissions = 'missions_v1';
}
