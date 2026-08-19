/// Tunables for the 2.5D action runner. Keep numbers here — not in widgets.
class RunnerConfig {
  RunnerConfig._();

  static const double gravity = 2200;

  /// Hop just over ground enemies (~66–74) and floor spikes (~30).
  static const double jumpVelocity = 590;
  static const double maxJumpVelocity = 640;
  static const double groundY = 0; // simulation space; painter maps to screen
  static const double runSpeedBase = 320;
  static const double playerX = 140;

  /// Shifted right so left-hand buttons do not cover the runner.
  static const double playerXButtons = 248;

  static const double playerWidth = 48;
  static const double playerHeight = 72;
  static const double slideHeight = 40;

  static const double dodgeSpeed = 520;
  static const double dodgeDuration = 0.28;
  static const double dodgeCooldown = 0.85;
  static const double dodgeIFrame = 0.28;
  static const double dodgeAmplitude = 46;

  static const double slideDuration = 0.55;

  static const double meleeRange = 92;
  static const double meleeHeight = 70;
  static const double meleeDuration = 0.28;
  static const double meleeComboWindow = 0.45;
  static const double hitStop = 0.045;

  static const int rangedMaxCharges = 3;
  static const double rangedReload = 3.5;
  static const double rangedSpeed = 620;
  static const double rangedRadius = 10;
  static const double rangedDamage = 1.25;

  static const double inputBuffer = 0.12;
  static const double invulnAfterHit = 1.0;

  static const int startingHealth = 3;
  static const double spawnIntervalStart = 2.4;
  static const double spawnIntervalMin = 0.95;

  static const int killScore = 100;
  static const int killCoins = 3;
  static const int killXp = 8;
  static const double distanceScorePerMeter = 2.5;
}
