import 'dart:math';

import '../enemies/enemy_roster.dart';
import 'runner_entities.dart';

/// Difficulty-aware enemy / hazard / boss selection.
class EnemyDirector {
  EnemyDirector(this._rng);

  final Random _rng;
  double bossTimer = 75;
  int bossIndex = 0;
  bool bossActive = false;

  void reset() {
    bossTimer = 75;
    bossIndex = 0;
    bossActive = false;
  }

  void onBossDefeated() => bossActive = false;

  /// Ground-only roster — flying / bird-like drones are excluded.
  EnemyDefinition pickRegular(double survived) {
    final roll = _rng.nextDouble();
    if (survived < 18) {
      if (roll < 0.5) return EnemyRoster.grunt;
      if (roll < 0.8) return EnemyRoster.raptor;
      return EnemyRoster.sentinel;
    }
    if (survived < 40) {
      if (roll < 0.22) return EnemyRoster.grunt;
      if (roll < 0.4) return EnemyRoster.raptor;
      if (roll < 0.58) return EnemyRoster.sentinel;
      if (roll < 0.75) return EnemyRoster.shocker;
      return EnemyRoster.guardian;
    }
    if (survived < 70) {
      if (roll < 0.14) return EnemyRoster.sentinel;
      if (roll < 0.28) return EnemyRoster.guardian;
      if (roll < 0.42) return EnemyRoster.shieldMaiden;
      if (roll < 0.56) return EnemyRoster.executioner;
      if (roll < 0.7) return EnemyRoster.voidStalker;
      if (roll < 0.85) return EnemyRoster.steelBrute;
      return EnemyRoster.warMachine;
    }
    if (roll < 0.12) return EnemyRoster.executioner;
    if (roll < 0.24) return EnemyRoster.voidStalker;
    if (roll < 0.36) return EnemyRoster.steelBrute;
    if (roll < 0.48) return EnemyRoster.warMachine;
    if (roll < 0.6) return EnemyRoster.fortress;
    if (roll < 0.72) return EnemyRoster.chaosEngineer;
    if (roll < 0.86) return EnemyRoster.riftReaper;
    return EnemyRoster.shieldMaiden;
  }

  EnemyDefinition? maybeBoss(double survived, double dt) {
    if (bossActive) return null;
    bossTimer -= dt;
    if (bossTimer > 0) return null;
    if (survived < 55) {
      bossTimer = 20;
      return null;
    }
    final bosses = EnemyRoster.bosses;
    final def = bosses[bossIndex % bosses.length];
    bossIndex++;
    bossTimer = 95 + _rng.nextDouble() * 25;
    bossActive = true;
    return def;
  }

  HazardKind pickHazard(double survived) {
    final roll = _rng.nextDouble();
    if (survived < 25) {
      return roll < 0.55 ? HazardKind.spike : HazardKind.laserBar;
    }
    if (roll < 0.25) return HazardKind.spike;
    if (roll < 0.45) return HazardKind.laserTurret;
    if (roll < 0.65) return HazardKind.electricFloor;
    if (roll < 0.82) return HazardKind.fallingDebris;
    return HazardKind.explosiveBarrel;
  }
}
