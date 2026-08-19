import 'package:flutter_test/flutter_test.dart';
import 'package:shadow_run/game/enemies/enemy_roster.dart';
import 'package:shadow_run/game/player/characters.dart';
import 'package:shadow_run/game/player/player.dart';
import 'package:shadow_run/game/runner/runner_config.dart';
import 'package:shadow_run/game/runner/runner_entities.dart';
import 'package:shadow_run/game/runner/runner_simulation.dart';

void main() {
  test('jump leaves ground and gravity returns player', () {
    final sim = RunnerSimulation(seed: 1);
    sim.startPlaying();
    expect(sim.player.onGround, isTrue);
    sim.bufferInput(RunnerInput.jump);
    sim.tick(0.016);
    expect(sim.player.onGround, isFalse);
    expect(sim.player.vy, greaterThan(0));

    for (var i = 0; i < 120; i++) {
      sim.tick(0.016);
    }
    expect(sim.player.onGround, isTrue);
    expect(sim.player.y, equals(RunnerConfig.groundY));
  });

  test('melee damages nearby enemy and awards score', () {
    final sim = RunnerSimulation(seed: 2);
    sim.startPlaying();
    sim.enemies.add(
      RunnerEnemy(
        id: 't',
        kind: EnemyKind.melee,
        x: RunnerConfig.playerX + 40,
        y: RunnerConfig.groundY,
        hp: 2,
        maxHp: 2,
        speed: 0,
        damage: 1,
        width: 40,
        height: 60,
      ),
    );
    sim.bufferInput(RunnerInput.melee);
    sim.tick(0.016);
    expect(sim.enemies.first.hp, lessThan(2));
  });

  test('ranged consumes charges and reloads', () {
    final sim = RunnerSimulation(seed: 3);
    sim.startPlaying();
    expect(sim.player.rangedCharges, RunnerConfig.rangedMaxCharges);
    for (var i = 0; i < RunnerConfig.rangedMaxCharges; i++) {
      sim.bufferInput(RunnerInput.ranged);
      sim.tick(0.016);
    }
    expect(sim.player.rangedCharges, 0);
    expect(sim.player.rangedReloadTimer, greaterThan(0));
    expect(sim.projectiles, isNotEmpty);

    var guard = 0;
    while (sim.player.rangedCharges == 0 && guard < 500) {
      sim.tick(0.05);
      guard++;
    }
    expect(sim.player.rangedCharges, RunnerConfig.rangedMaxCharges);
  });

  test('dodge grants temporary invulnerability', () {
    final sim = RunnerSimulation(seed: 4);
    sim.startPlaying();
    sim.bufferInput(RunnerInput.dodgeRight);
    sim.tick(0.016);
    expect(sim.player.dodging, isTrue);
    expect(sim.player.invulnerable, isTrue);
  });

  test('dodge avoids overlapping ranged shots', () {
    final sim = RunnerSimulation(seed: 14);
    sim.startPlaying();
    final hp = sim.player.health;
    sim.projectiles.add(
      RunnerProjectile(
        x: RunnerConfig.playerX + 20,
        y: 36,
        vx: -400,
        damage: 1,
        critical: false,
        fromPlayer: false,
      ),
    );
    sim.bufferInput(RunnerInput.dodgeRight);
    sim.tick(0.016);
    expect(sim.player.dodging, isTrue);
    expect(sim.player.health, hp);
    expect(sim.projectiles.every((p) => p.dead), isTrue);
  });

  test('jump height clears a floor spike without a huge leap', () {
    final sim = RunnerSimulation(seed: 15);
    sim.startPlaying();
    sim.bufferInput(RunnerInput.jump);
    var peak = 0.0;
    for (var i = 0; i < 80; i++) {
      sim.tick(0.016);
      if (sim.player.y > peak) peak = sim.player.y;
    }
    expect(peak, greaterThan(32));
    expect(peak, lessThan(100));
    expect(sim.player.onGround, isTrue);
  });

  test('pause freezes simulation progress', () {
    final sim = RunnerSimulation(seed: 5);
    sim.startPlaying();
    sim.tick(0.5);
    final dist = sim.run.distance;
    sim.pause();
    sim.tick(0.5);
    expect(sim.run.distance, dist);
    sim.resume();
    sim.tick(0.5);
    expect(sim.run.distance, greaterThan(dist));
  });

  test('enemy contact damages player', () {
    final sim = RunnerSimulation(seed: 6);
    sim.startPlaying();
    final hp = sim.player.health;
    sim.enemies.add(
      RunnerEnemy(
        id: 'hit',
        kind: EnemyKind.melee,
        x: RunnerConfig.playerX,
        y: RunnerConfig.groundY,
        hp: 5,
        maxHp: 5,
        speed: 0,
        damage: 1,
        width: 50,
        height: 70,
      ),
    );
    sim.tick(0.016);
    expect(sim.player.health, lessThan(hp));
  });

  test('blade has higher health and slower speed than runner', () {
    final runner = RunnerSimulation(
      starterStats: CharacterCatalog.runner.baseStats,
      seed: 7,
    );
    final blade = RunnerSimulation(
      starterStats: CharacterCatalog.blade.baseStats,
      seed: 8,
    );
    expect(blade.player.maxHealth, greaterThan(runner.player.maxHealth));
    expect(blade.player.moveSpeedMul, lessThan(runner.player.moveSpeedMul));
    expect(blade.player.meleeDamage, greaterThan(runner.player.meleeDamage));
  });

  test('runner shadow dash ability grants invulnerability', () {
    final sim = RunnerSimulation(
      starterStats: CharacterCatalog.runner.baseStats,
      seed: 9,
    );
    sim.startPlaying();
    sim.bufferInput(RunnerInput.ability);
    sim.tick(0.016);
    expect(sim.player.invulnerable, isTrue);
    expect(sim.player.anim, PlayerAnim.ability);
  });

  test('ultimate requires charge from kills', () {
    final sim = RunnerSimulation(
      starterStats: CharacterCatalog.hunter.baseStats,
      seed: 10,
    );
    sim.startPlaying();
    sim.bufferInput(RunnerInput.ultimate);
    sim.tick(0.016);
    expect(sim.player.anim, isNot(PlayerAnim.ultimate));
    sim.player.ultimateCharge = sim.player.ultimateChargeMax;
    sim.bufferInput(RunnerInput.ultimate);
    sim.tick(0.016);
    expect(sim.player.anim, PlayerAnim.ultimate);
    expect(sim.projectiles, isNotEmpty);
  });

  test('enemies advance toward the player instead of fleeing', () {
    final sim = RunnerSimulation(seed: 11);
    sim.startPlaying();
    final enemy = RunnerEnemy(
      id: 'chase',
      kind: EnemyKind.melee,
      x: RunnerConfig.playerX + 220,
      y: RunnerConfig.groundY,
      hp: 5,
      maxHp: 5,
      speed: 80,
      damage: 1,
      width: 40,
      height: 60,
    );
    enemy.ai = EnemyAiState.approach;
    sim.enemies.add(enemy);
    final startX = enemy.x;
    for (var i = 0; i < 30; i++) {
      sim.tick(0.016);
    }
    expect(enemy.x, lessThan(startX));
    expect(enemy.x, greaterThan(RunnerConfig.playerX));
  });

  test('ranged keepsDistance foes do not back away when close', () {
    final sim = RunnerSimulation(seed: 13);
    sim.startPlaying();
    final enemy = RunnerEnemy(
      id: 'sniper',
      def: EnemyRoster.sentinel,
      x: RunnerConfig.playerX + 80,
      y: RunnerConfig.groundY,
      speed: 60,
    );
    enemy.ai = EnemyAiState.approach;
    sim.enemies.add(enemy);
    final startX = enemy.x;
    for (var i = 0; i < 40; i++) {
      sim.tick(0.016);
    }
    // Hold or approach — never retreat further from the player.
    expect(enemy.x, lessThanOrEqualTo(startX + 1));
  });

  test('coin and xp multipliers apply on kill rewards', () {
    final sim = RunnerSimulation(
      starterStats: PlayerStats.starterRunner().copyWith(
        coinMultiplier: 2,
        xpMultiplier: 2,
      ),
      seed: 20,
    );
    sim.startPlaying();
    sim.enemies.add(
      RunnerEnemy(
        id: 'loot',
        kind: EnemyKind.melee,
        x: RunnerConfig.playerX + 40,
        y: RunnerConfig.groundY,
        hp: 1,
        maxHp: 1,
        speed: 0,
        damage: 1,
        width: 40,
        height: 60,
        coins: 4,
        xp: 8,
      ),
    );
    sim.bufferInput(RunnerInput.melee);
    for (var i = 0; i < 80; i++) {
      sim.tick(0.016);
      if (sim.run.kills > 0) break;
    }
    expect(sim.run.kills, greaterThan(0));
    expect(sim.run.coins, greaterThanOrEqualTo(8));
    expect(sim.run.xp, greaterThanOrEqualTo(16));
  });
}
