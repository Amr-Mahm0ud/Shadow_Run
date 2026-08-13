import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:shadow_run/game/enemies/enemy_roster.dart';
import 'package:shadow_run/game/player/characters.dart';
import 'package:shadow_run/game/runner/enemy_director.dart';
import 'package:shadow_run/game/runner/runner_entities.dart';
import 'package:shadow_run/game/runner/runner_simulation.dart';

void main() {
  test('enemy roster contains all 23 designed enemies', () {
    expect(EnemyRoster.all.length, 23);
    expect(EnemyRoster.bosses.length, 4);
    expect(EnemyRoster.byId('grunt').displayName, 'GRUNT');
    expect(EnemyRoster.byId('juggernaut').isBoss, isTrue);
    expect(EnemyRoster.byId('scout_drone').flying, isTrue);
    expect(EnemyRoster.byId('shield_maiden').blocksRanged, isTrue);
  });

  test('director early pool stays basic', () {
    final d = EnemyDirector(Random(1));
    for (var i = 0; i < 30; i++) {
      final e = d.pickRegular(10);
      expect(
        ['grunt', 'raptor', 'scout_drone'].contains(e.id),
        isTrue,
        reason: e.id,
      );
    }
  });

  test('simulation spawns roster enemies with spritesheet ids', () {
    final sim = RunnerSimulation(seed: 42);
    sim.startPlaying();
    for (var i = 0; i < 200; i++) {
      sim.tick(0.05);
    }
    expect(sim.enemies, isNotEmpty);
    for (final e in sim.enemies) {
      expect(e.def.id, isNotEmpty);
      expect(e.def.spritesheet, contains('assets/enemies/'));
    }
  });

  test('player projectile damages grunt', () {
    final sim = RunnerSimulation(
      starterStats: CharacterCatalog.runner.baseStats,
      seed: 3,
    );
    sim.startPlaying();
    final grunt = RunnerEnemy(
      id: 'g1',
      def: EnemyRoster.grunt,
      x: 200,
      y: 0,
    )..ai = EnemyAiState.approach;
    sim.enemies.add(grunt);
    final hp = grunt.hp;
    sim.bufferInput(RunnerInput.ranged);
    for (var i = 0; i < 50; i++) {
      sim.tick(0.016);
    }
    expect(grunt.hp, lessThan(hp));
  });

  test('shield maiden absorbs ranged into shield', () {
    final sim = RunnerSimulation(seed: 5);
    sim.startPlaying();
    final maiden = RunnerEnemy(
      id: 'm1',
      def: EnemyRoster.shieldMaiden,
      x: 200,
      y: 0,
    )
      ..ai = EnemyAiState.approach
      ..shieldUp = true;
    final bodyHp = maiden.hp;
    final shield = maiden.shieldHp;
    expect(maiden.blocksRanged, isTrue);
    sim.enemies.add(maiden);
    sim.projectiles.add(
      RunnerProjectile(
        x: 210,
        y: 30,
        vx: 10,
        damage: 1,
        critical: false,
        fromPlayer: true,
        kind: ProjectileKind.bullet,
      ),
    );
    sim.tick(0.016);
    expect(maiden.shieldHp, lessThan(shield));
    expect(maiden.hp, bodyHp);
  });
}
