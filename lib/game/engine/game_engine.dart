import '../../core/config/game_config.dart';
import '../enemies/enemy.dart';
import '../player/player.dart';
import '../powerups/powerup.dart';
import 'game_phase.dart';

enum CollisionOutcome { none, playerHit, enemyKilled }

class RunStats {
  int score = 0;
  int coinsEarned = 0;
  int xpEarned = 0;
  int enemiesDefeated = 0;
  int waves = 0;
  Duration survived = Duration.zero;

  void reset() {
    score = 0;
    coinsEarned = 0;
    xpEarned = 0;
    enemiesDefeated = 0;
    waves = 0;
    survived = Duration.zero;
  }
}

/// UI-free game rules. Timers/animation stay in the feature layer.
class GameEngine {
  GameEngine({PlayerStats? starterStats})
      : _baseStats = starterStats ?? PlayerStats.starterShadow(),
        player = PlayerActor(stats: starterStats),
        enemy = EnemyActor() {
    resetRun();
  }

  final PlayerStats _baseStats;
  final PlayerActor player;
  final EnemyActor enemy;
  final RunStats run = RunStats();
  final List<PowerUpId> activePowerUps = [];

  GamePhase phase = GamePhase.idle;
  int enemyDurationMs = GameConfig.initialEnemyMs;
  int lastThemeScore = 0;
  bool hitHandled = false;
  bool waveHandled = false;
  bool skyAmber = true;

  void resetRun() {
    final healthBonus = _baseStats.maxHealth;
    player.stats = _baseStats.copyWith(
      health: healthBonus,
      maxHealth: healthBonus,
    );
    player.run();
    enemy.reset(EnemyCatalog.normal);
    run.reset();
    activePowerUps.clear();
    phase = GamePhase.countdown;
    enemyDurationMs = GameConfig.initialEnemyMs;
    lastThemeScore = 0;
    hitHandled = false;
    waveHandled = false;
    skyAmber = true;
  }

  void startPlaying() => phase = GamePhase.playing;

  void pause() {
    if (phase == GamePhase.playing || phase == GamePhase.boss) {
      phase = GamePhase.paused;
    }
  }

  void resume() {
    if (phase == GamePhase.paused) phase = GamePhase.playing;
  }

  void beginAttack() {
    if (!phase.allowsAttack) return;
    if (player.status == HeroStatus.die) return;
    player.attack();
  }

  void endAttackWindow() {
    if (phase == GamePhase.gameOver || phase == GamePhase.reward) return;
    if (player.status == HeroStatus.die && player.lives > 0) {
      player.run();
      return;
    }
    if (player.status == HeroStatus.attack) {
      player.run();
    }
  }

  CollisionOutcome evaluateCollisionAt(double dx) {
    if (!phase.isInteractive) return CollisionOutcome.none;

    if (dx < GameConfig.hitMaxX && dx > GameConfig.hitMinX) {
      if (hitHandled) return CollisionOutcome.none;
      hitHandled = true;
      return _resolveCollision();
    }
    if (dx >= GameConfig.hitMaxX) {
      hitHandled = false;
    }
    return CollisionOutcome.none;
  }

  bool shouldResetWave(double dx) {
    if (dx < GameConfig.resetX && !waveHandled) {
      waveHandled = true;
      return true;
    }
    return false;
  }

  CollisionOutcome _resolveCollision() {
    if (enemy.status == EnemyStatus.run && player.status == HeroStatus.run) {
      final dead = player.takeHit();
      if (dead) {
        phase = GamePhase.gameOver;
      }
      return CollisionOutcome.playerHit;
    }
    if (player.status == HeroStatus.attack && enemy.status == EnemyStatus.run) {
      enemy.dieFromHero(player.status);
      final def = enemy.definition;
      final coinMul = player.stats.coinMultiplier;
      final xpMul = player.stats.xpMultiplier;
      run.score += def.scoreReward;
      run.coinsEarned += (def.coinReward * coinMul).round();
      run.xpEarned += (def.xpReward * xpMul).round();
      run.enemiesDefeated += 1;
      return CollisionOutcome.enemyKilled;
    }
    return CollisionOutcome.none;
  }

  /// Returns true if theme colors should flip.
  bool maybeFlipTheme() {
    final score = run.score;
    if (score <= 0 ||
        score % GameConfig.themeScoreInterval != 0 ||
        score == lastThemeScore) {
      return false;
    }
    lastThemeScore = score;
    skyAmber = !skyAmber;
    return true;
  }

  int advanceWaveDifficulty() {
    enemy.reset(_pickNextEnemy());
    hitHandled = false;
    waveHandled = false;
    run.waves += 1;

    if (enemyDurationMs > GameConfig.minEnemyMs) {
      enemyDurationMs -= GameConfig.enemyStepMs;
      if (enemyDurationMs < GameConfig.minEnemyMs) {
        enemyDurationMs = GameConfig.minEnemyMs;
      }
    }

    final speed = enemy.definition.speedMultiplier;
    return (enemyDurationMs / speed).round().clamp(
          GameConfig.minEnemyMs ~/ 2,
          GameConfig.initialEnemyMs,
        );
  }

  EnemyDefinition _pickNextEnemy() {
    // Progressive variety: unlock fast then tank as waves increase.
    if (run.waves >= 8 && run.waves % 5 == 0) return EnemyCatalog.tank;
    if (run.waves >= 3 && run.waves % 2 == 0) return EnemyCatalog.fast;
    return EnemyCatalog.normal;
  }

  void applyPowerUp(PowerUpDefinition powerUp) {
    activePowerUps.add(powerUp.id);
    switch (powerUp.id) {
      case PowerUpId.damage:
        player.stats = player.stats.copyWith(damage: player.stats.damage + 0.25);
      case PowerUpId.attackSpeed:
        player.stats =
            player.stats.copyWith(attackSpeed: player.stats.attackSpeed + 0.15);
      case PowerUpId.moveSpeed:
        player.stats = player.stats.copyWith(speed: player.stats.speed + 0.15);
      case PowerUpId.maxHp:
        player.stats = player.stats.copyWith(
          maxHealth: player.stats.maxHealth + 1,
          health: player.stats.health + 1,
        );
      case PowerUpId.criticalHit:
        player.stats = player.stats
            .copyWith(criticalChance: player.stats.criticalChance + 0.08);
      case PowerUpId.coinMagnet:
        player.stats = player.stats
            .copyWith(coinMultiplier: player.stats.coinMultiplier + 0.25);
      case PowerUpId.xpBoost:
        player.stats =
            player.stats.copyWith(xpMultiplier: player.stats.xpMultiplier + 0.25);
      case PowerUpId.shield:
      case PowerUpId.lifeSteal:
      case PowerUpId.slowMotion:
        // Applied visually / via duration modifiers in later phases.
        break;
    }
  }

  bool get shouldOfferLevelUp {
    // Offer a power-up choice every 5 kills.
    return run.enemiesDefeated > 0 &&
        run.enemiesDefeated % 5 == 0 &&
        phase == GamePhase.playing;
  }

  void enterLevelUp() => phase = GamePhase.levelUp;

  void finishLevelUp() => phase = GamePhase.playing;

  void enterReward() => phase = GamePhase.reward;
}
