/// Centralized gameplay / economy numbers. Do not scatter magic values in UI.
class GameConfig {
  GameConfig._();

  // --- Core run ---
  static const int startingLives = 3;
  static const int killScore = 5;
  static const int killCoins = 3;
  static const int killXp = 8;
  static const int themeScoreInterval = 50;

  static const int initialEnemyMs = 6000;
  static const int minEnemyMs = 1500;
  static const int enemyStepMs = 200;

  static const double hitMinX = -0.2;
  static const double hitMaxX = 0.5;
  static const double resetX = -1.5;

  static const int spriteFrameMs = 120;
  static const int attackWindowDivisor = 8;

  // --- Progression ---
  static const int xpPerLevelBase = 100;
  static const double xpPerLevelGrowth = 1.25;

  static const int startingCoins = 0;
  static const int startingGems = 0;

  // --- Ads / monetization (inactive until flags on) ---
  static const int interstitialEveryNRuns = 4;

  static int xpForLevel(int level) {
    if (level <= 1) return xpPerLevelBase;
    var total = xpPerLevelBase.toDouble();
    for (var i = 2; i <= level; i++) {
      total *= xpPerLevelGrowth;
    }
    return total.round();
  }
}
