import 'package:flutter_test/flutter_test.dart';
import 'package:shadow_run/core/config/game_config.dart';
import 'package:shadow_run/game/engine/game_engine.dart';
import 'package:shadow_run/game/engine/game_phase.dart';
import 'package:shadow_run/game/player/player.dart';
import 'package:shadow_run/game/powerups/powerup.dart';
import 'package:shadow_run/game/systems/upgrades.dart';

void main() {
  group('GameEngine', () {
    test('player hit reduces lives and ends run at zero', () {
      final engine = GameEngine();
      engine.startPlaying();
      engine.player.run();
      engine.enemy.reset();

      expect(engine.evaluateCollisionAt(0), CollisionOutcome.playerHit);
      expect(engine.player.lives, GameConfig.startingLives - 1);

      engine.hitHandled = false;
      engine.player.run();
      engine.evaluateCollisionAt(0);
      engine.hitHandled = false;
      engine.player.run();
      final outcome = engine.evaluateCollisionAt(0);

      expect(outcome, CollisionOutcome.playerHit);
      expect(engine.phase, GamePhase.gameOver);
    });

    test('attack kills enemy and grants rewards', () {
      final engine = GameEngine();
      engine.startPlaying();
      engine.beginAttack();

      final outcome = engine.evaluateCollisionAt(0);
      expect(outcome, CollisionOutcome.enemyKilled);
      expect(engine.run.score, greaterThan(0));
      expect(engine.run.coinsEarned, greaterThan(0));
      expect(engine.run.xpEarned, greaterThan(0));
      expect(engine.run.enemiesDefeated, 1);
    });

    test('difficulty shortens enemy duration across waves', () {
      final engine = GameEngine();
      final first = engine.enemyDurationMs;
      final next = engine.advanceWaveDifficulty();
      expect(next, lessThan(first));
      expect(engine.run.waves, 1);
    });

    test('power-up damage increases player damage', () {
      final engine = GameEngine();
      final before = engine.player.stats.damage;
      engine.applyPowerUp(
        PowerUpCatalog.all.firstWhere((p) => p.id == PowerUpId.damage),
      );
      expect(engine.player.stats.damage, greaterThan(before));
    });
  });

  group('GameConfig', () {
    test('xp thresholds grow with level', () {
      expect(GameConfig.xpForLevel(1), GameConfig.xpPerLevelBase);
      expect(GameConfig.xpForLevel(3), greaterThan(GameConfig.xpForLevel(2)));
    });
  });

  group('UpgradeCatalog', () {
    test('cost increases with level', () {
      final upgrade = UpgradeCatalog.all.first;
      expect(upgrade.costForLevel(1), greaterThan(upgrade.costForLevel(0)));
    });
  });

  group('PlayerStats', () {
    test('characters have distinct profiles', () {
      final shadow = PlayerStats.starterShadow();
      final ninja = shadow.copyWith(speed: 1.35, maxHealth: 2, health: 2);
      expect(ninja.speed, greaterThan(shadow.speed));
      expect(ninja.maxHealth, lessThan(shadow.maxHealth));
    });
  });
}
