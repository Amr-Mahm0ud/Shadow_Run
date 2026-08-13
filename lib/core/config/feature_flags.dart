/// Runtime feature flags for safer rollout. Persist later via remote config.
class FeatureFlags {
  FeatureFlags._();

  static bool adsEnabled = false;
  static bool leaderboardEnabled = false;
  static bool cloudSaveEnabled = false;
  static bool shopEnabled = false;
  static bool bossEnabled = false;
  static bool dailyRewardsEnabled = false;
  static bool missionsEnabled = true;
  static bool experimentalFeatures = false;
  static bool powerUpsEnabled = true;
  static bool pauseEnabled = true;
}
