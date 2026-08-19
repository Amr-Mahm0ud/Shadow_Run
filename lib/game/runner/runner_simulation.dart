import 'dart:math';

import '../enemies/enemy_roster.dart';
import '../player/characters.dart';
import '../player/player.dart';
import 'enemy_director.dart';
import 'runner_config.dart';
import 'runner_entities.dart';

/// UI-free action-runner simulation. Drive with [tick] + [bufferInput].
class RunnerSimulation {
  RunnerSimulation({PlayerStats? starterStats, int? seed})
      : _rng = Random(seed),
        player = RunnerPlayer() {
    director = EnemyDirector(_rng);
    _applyStats(starterStats ?? PlayerStats.starterRunner());
    reset();
  }

  final Random _rng;
  late final EnemyDirector director;
  final RunnerPlayer player;
  final RunnerStats run = RunnerStats();
  final List<RunnerEnemy> enemies = [];
  final List<RunnerProjectile> projectiles = [];
  final List<RunnerHazard> hazards = [];
  final List<RunnerParticle> particles = [];
  final List<RunnerFloatingText> floatingTexts = [];

  RunnerPhase phase = RunnerPhase.countdown;

  /// World X of the runner. Pushed right when on-screen buttons are enabled.
  double playerWorldX = RunnerConfig.playerX;
  double scrollX = 0;
  double spawnTimer = 0;
  double shake = 0;
  int _id = 0;
  RunnerInput? _buffered;
  double _bufferAge = 0;
  String worldId = 'cyber_city';
  CharacterDefinition character = CharacterCatalog.runner;
  double _runSpeedBase = 1;
  void Function(RunnerSfx event)? onSfx;
  bool _bossWarned = false;

  void _sfx(RunnerSfx event) => onSfx?.call(event);

  ActiveBoss? get activeBoss {
    for (final e in enemies) {
      if (!e.dead && e.isBoss) return ActiveBoss(e);
    }
    return null;
  }

  void _applyStats(PlayerStats s) {
    character = CharacterCatalog.byId(s.characterId);
    player.characterId = character.id;
    player.maxHealth = s.maxHealth;
    player.health = s.health;
    player.meleeMul = character.meleeMul;
    player.rangedMul = character.rangedMul;
    player.armorMul = character.armorMul;
    player.meleeDamage = s.damage * character.meleeMul;
    player.rangedDamage =
        RunnerConfig.rangedDamage * s.damage * character.rangedMul;
    player.critChance = s.criticalChance;
    player.critMult = s.criticalDamage;
    player.moveSpeedMul = s.speed;
    player.jumpMul = 1 + (s.speed - 1) * 0.25;
    player.meleeSpeedMul = s.attackSpeed.clamp(0.7, 1.8);
    player.reloadMul = 1 / s.effectiveReloadSpeed.clamp(0.6, 2.0);
    player.coinMultiplier = s.coinMultiplier.clamp(1.0, 3.0);
    player.xpMultiplier = s.xpMultiplier.clamp(1.0, 3.0);
    player.rangedMaxCharges = RunnerConfig.rangedMaxCharges;
    player.rangedCharges = player.rangedMaxCharges;
    player.abilityCooldownMax = character.abilityCooldown;
    player.ultimateChargeMax = character.ultimateChargeKills.toDouble();
    player.abilityCooldown = 0;
    player.ultimateCharge = 0;
    _runSpeedBase = player.moveSpeedMul;
  }

  void reset({PlayerStats? playerStats}) {
    if (playerStats != null) _applyStats(playerStats);
    player.y = RunnerConfig.groundY;
    player.vy = 0;
    player.xOffset = 0;
    player.onGround = true;
    player.sliding = false;
    player.dodging = false;
    player.invulnerable = false;
    player.anim = PlayerAnim.run;
    player.health = player.maxHealth;
    player.comboStep = 0;
    player.meleeTimer = 0;
    player.comboTimer = 0;
    player.slideTimer = 0;
    player.dodgeTimer = 0;
    player.dodgeCooldown = 0;
    player.invulnTimer = 0;
    player.rangedCharges = player.rangedMaxCharges;
    player.rangedReloadTimer = 0;
    player.hitStopTimer = 0;
    player.abilityCooldown = 0;
    player.abilityTimer = 0;
    player.ultimateCharge = 0;
    player.ultimateTimer = 0;
    player.markActive = false;
    player.markTimer = 0;
    player.timeFractureActive = false;
    player.timeFractureTimer = 0;
    player.landTimer = 0;
    player.animTime = 0;
    player.disruptTimer = 0;
    director.reset();
    enemies.clear();
    projectiles.clear();
    hazards.clear();
    particles.clear();
    floatingTexts.clear();
    run.score = 0;
    run.coins = 0;
    run.xp = 0;
    run.kills = 0;
    run.bestCombo = 0;
    run.combo = 0;
    run.comboTimer = 0;
    run.distance = 0;
    run.survived = 0;
    run.multiplier = 1;
    run.bossesDefeated = 0;
    scrollX = 0;
    spawnTimer = 1.2;
    shake = 0;
    phase = RunnerPhase.countdown;
    _buffered = null;
    _bufferAge = 0;
    _bossWarned = false;
    worldId = 'cyber_city';
  }

  void startPlaying() => phase = RunnerPhase.playing;

  void pause() {
    if (phase == RunnerPhase.playing) phase = RunnerPhase.paused;
  }

  void resume() {
    if (phase == RunnerPhase.paused) phase = RunnerPhase.playing;
  }

  void bufferInput(RunnerInput input) {
    if (phase != RunnerPhase.playing && phase != RunnerPhase.countdown) return;
    _buffered = input;
    _bufferAge = 0;
    if (phase == RunnerPhase.playing) {
      _tryConsumeBuffer();
    }
  }

  void tick(double dt) {
    if (phase == RunnerPhase.paused ||
        phase == RunnerPhase.reward ||
        phase == RunnerPhase.dead) {
      if (phase == RunnerPhase.dead) {
        player.animTime += dt;
        _updateVfx(dt);
      }
      return;
    }

    if (phase == RunnerPhase.countdown) return;

    if (player.hitStopTimer > 0) {
      player.hitStopTimer -= dt;
      _updateVisualOnly(dt);
      return;
    }

    final clamped = dt.clamp(0.0, 0.05);
    run.survived += clamped;
    player.animTime += clamped;
    _bufferAge += clamped;
    if (_buffered != null && _bufferAge > RunnerConfig.inputBuffer) {
      _buffered = null;
    }
    _tryConsumeBuffer();

    _updatePlayer(clamped);
    final dx = _updateWorld(clamped);
    _updateEnemies(clamped, dx);
    _updateCombat(clamped);
    _updateBossSpawn(clamped);
    _spawn(clamped);
    _updateVfx(clamped);
    shake = (shake - clamped * 8).clamp(0.0, 12.0);

    if (player.health <= 0 && phase == RunnerPhase.playing) {
      phase = RunnerPhase.dead;
      player.anim = PlayerAnim.dead;
      player.animTime = 0;
    }
  }

  void enterReward() => phase = RunnerPhase.reward;

  void _tryConsumeBuffer() {
    final input = _buffered;
    if (input == null || phase != RunnerPhase.playing) return;
    final ok = switch (input) {
      RunnerInput.jump => _jump(),
      RunnerInput.slide => _slide(),
      RunnerInput.dodgeLeft => _dodge(-1),
      RunnerInput.dodgeRight => _dodge(1),
      RunnerInput.melee => _melee(),
      RunnerInput.ranged => _ranged(),
      RunnerInput.ability => _ability(),
      RunnerInput.ultimate => _ultimate(),
    };
    if (ok) _buffered = null;
  }

  bool _jump({double power = 1}) {
    if (!player.onGround || player.sliding) return false;
    if (player.abilityTimer > 0 || player.ultimateTimer > 0) return false;
    var p = power.clamp(0.92, 1.04);
    if (player.disruptTimer > 0.4) p *= 0.8;
    player.vy = (RunnerConfig.jumpVelocity * player.jumpMul * p)
        .clamp(0, RunnerConfig.maxJumpVelocity * player.jumpMul);
    player.onGround = false;
    player.anim = PlayerAnim.jump;
    player.animTime = 0;
    _burst(playerWorldX, player.y + 8, 6, _accentColor);
    _sfx(RunnerSfx.jump);
    return true;
  }

  bool _slide() {
    if (!player.onGround || player.dodging) return false;
    if (player.abilityTimer > 0 || player.ultimateTimer > 0) return false;
    player.sliding = true;
    player.slideTimer = RunnerConfig.slideDuration;
    player.anim = PlayerAnim.slide;
    player.animTime = 0;
    player.comboStep = 0;
    _sfx(RunnerSfx.slide);
    return true;
  }

  bool _dodge(int dir) {
    if (player.dodgeCooldown > 0 || player.sliding) return false;
    if (player.abilityTimer > 0 || player.ultimateTimer > 0) return false;
    player.dodging = true;
    player.dodgeDir = dir >= 0 ? 1 : -1;
    player.dodgeTimer = RunnerConfig.dodgeDuration;
    player.dodgeCooldown = RunnerConfig.dodgeCooldown;
    player.invulnerable = true;
    player.invulnTimer = RunnerConfig.dodgeIFrame;
    player.xOffset = 0;
    player.anim = PlayerAnim.dodge;
    player.animTime = 0;
    _burst(playerWorldX, player.y + 36, 10, _accentColor);
    _spawnVfx('afterimage');
    _sfx(RunnerSfx.dodge);
    return true;
  }

  bool _melee() {
    if (player.sliding || player.dodging) return false;
    if (player.abilityTimer > 0 || player.ultimateTimer > 0) return false;
    if (player.meleeTimer > 0.08 && player.comboTimer <= 0) return false;

    if (player.comboTimer > 0 && player.comboStep > 0 && player.comboStep < 3) {
      player.comboStep += 1;
    } else {
      player.comboStep = 1;
    }
    player.meleeTimer = RunnerConfig.meleeDuration / player.meleeSpeedMul;
    player.comboTimer = RunnerConfig.meleeComboWindow;
    player.anim = switch (player.comboStep) {
      2 => PlayerAnim.melee2,
      3 => PlayerAnim.melee3,
      _ => PlayerAnim.melee1,
    };
    player.animTime = 0;
    final hit = _resolveMeleeHits();
    _spawnVfx('slash');
    // Miss = air swing; hit = impact only (never both at full volume).
    _sfx(hit ? RunnerSfx.meleeHit : RunnerSfx.meleeMiss);
    return true;
  }

  bool _ranged() {
    if (player.rangedCharges <= 0) return false;
    if (player.sliding) return false;
    if (player.abilityTimer > 0 || player.ultimateTimer > 0) return false;
    player.rangedCharges -= 1;
    player.anim = PlayerAnim.ranged;
    player.animTime = 0;
    if (player.rangedCharges == 0) {
      player.rangedReloadTimer = RunnerConfig.rangedReload * player.reloadMul;
      _sfx(RunnerSfx.reload);
    }
    final crit = _rng.nextDouble() < player.critChance;
    var dmg = player.rangedDamage * (crit ? player.critMult : 1);
    if (player.markActive) dmg *= 1.35;
    projectiles.add(
      RunnerProjectile(
        x: playerWorldX + 40,
        y: player.y + player.height * 0.55,
        vx: RunnerConfig.rangedSpeed,
        damage: dmg,
        critical: crit,
        kind: character.id == 'hunter'
            ? ProjectileKind.plasma
            : ProjectileKind.standard,
        colorValue: _accentColor,
      ),
    );
    _burst(playerWorldX + 36, player.y + 40, 8, _accentColor);
    _spawnVfx('muzzle');
    shake = max(shake, 2.5);
    _sfx(RunnerSfx.ranged);
    return true;
  }

  bool _ability() {
    if (!player.abilityReady) return false;
    if (player.sliding || player.dodging) return false;
    player.abilityCooldown = player.abilityCooldownMax;
    player.abilityTimer = 0.55;
    player.anim = PlayerAnim.ability;
    player.animTime = 0;
    switch (character.abilityId) {
      case CharacterAbilityId.shadowDash:
        _shadowDash();
      case CharacterAbilityId.markTarget:
        _markTarget();
      case CharacterAbilityId.heavySlash:
        _heavySlash();
      case CharacterAbilityId.phase:
        _phase();
    }
    floatingTexts.add(
      RunnerFloatingText(
        x: playerWorldX,
        y: player.y + player.height + 20,
        text: character.abilityName,
        critical: true,
      ),
    );
    _sfx(RunnerSfx.ability);
    return true;
  }

  bool _ultimate() {
    if (!player.ultimateReady) return false;
    if (player.sliding) return false;
    player.ultimateCharge = 0;
    player.ultimateTimer = 0.85;
    player.anim = PlayerAnim.ultimate;
    player.animTime = 0;
    switch (character.ultimateId) {
      case CharacterUltimateId.phantomStrike:
        _phantomStrike();
      case CharacterUltimateId.rainOfLight:
        _rainOfLight();
      case CharacterUltimateId.voidCleave:
        _voidCleave();
      case CharacterUltimateId.timeFracture:
        _timeFracture();
    }
    floatingTexts.add(
      RunnerFloatingText(
        x: playerWorldX,
        y: player.y + player.height + 28,
        text: character.ultimateName,
        critical: true,
      ),
    );
    shake = max(shake, 9);
    _sfx(RunnerSfx.ultimate);
    return true;
  }

  void _shadowDash() {
    player.invulnerable = true;
    player.invulnTimer = 0.45;
    player.dodging = true;
    player.dodgeDir = 1;
    player.dodgeTimer = 0.4;
    player.xOffset = 0;
    _spawnVfx('dash');
    _spawnVfx('afterimage');
    final box = RunnerRect(
      playerWorldX,
      player.y,
      160,
      player.height,
    );
    for (final e in enemies) {
      if (e.dead) continue;
      if (!box.overlaps(e.hitbox)) continue;
      _damageEnemy(e, player.meleeDamage * 1.4, true, knockback: 160);
    }
  }

  void _markTarget() {
    player.markActive = true;
    player.markTimer = 6;
    _spawnVfx('mark');
    for (final e in enemies) {
      if (e.dead) continue;
      if (e.x > playerWorldX - 20 && e.x < playerWorldX + 420) {
        e.marked = true;
        e.markTimer = 6;
      }
    }
  }

  void _heavySlash() {
    player.meleeTimer = 0.4;
    player.comboStep = 3;
    _spawnVfx('slash');
    final box = RunnerRect(
      playerWorldX + 10,
      player.y,
      RunnerConfig.meleeRange * 1.55,
      RunnerConfig.meleeHeight * 1.2,
    );
    for (final e in enemies) {
      if (e.dead) continue;
      if (!box.overlaps(e.hitbox)) continue;
      _damageEnemy(e, player.meleeDamage * 2.4, true, knockback: 220);
    }
    player.hitStopTimer = RunnerConfig.hitStop * 2;
    shake = max(shake, 8);
  }

  void _phase() {
    player.invulnerable = true;
    player.invulnTimer = 1.1;
    _runSpeedBase = player.moveSpeedMul;
    player.moveSpeedMul = _runSpeedBase * 1.35;
    _spawnVfx('phase');
    _spawnVfx('particles');
  }

  void _phantomStrike() {
    player.invulnerable = true;
    player.invulnTimer = 0.7;
    _spawnVfx('afterimage');
    _spawnVfx('dash');
    for (var i = 0; i < 3; i++) {
      final box = RunnerRect(
        playerWorldX + i * 50.0,
        player.y,
        90,
        player.height + 10,
      );
      for (final e in enemies) {
        if (e.dead) continue;
        if (!box.overlaps(e.hitbox)) continue;
        _damageEnemy(
          e,
          player.meleeDamage * (1.2 + i * 0.35),
          true,
          knockback: 100 + i * 40,
        );
      }
    }
  }

  void _rainOfLight() {
    _spawnVfx('muzzle');
    for (var i = 0; i < 8; i++) {
      projectiles.add(
        RunnerProjectile(
          x: playerWorldX + 80 + i * 42.0,
          y: player.y + 140 + _rng.nextDouble() * 40,
          vx: 40,
          vy: -420 - _rng.nextDouble() * 80,
          damage: player.rangedDamage * 1.1,
          critical: i % 3 == 0,
          kind: ProjectileKind.rain,
          colorValue: _accentColor,
        ),
      );
    }
  }

  void _voidCleave() {
    _spawnVfx('wave');
    projectiles.add(
      RunnerProjectile(
        x: playerWorldX + 50,
        y: player.y + player.height * 0.5,
        vx: 480,
        damage: player.meleeDamage * 2.8,
        critical: true,
        kind: ProjectileKind.voidWave,
        colorValue: _accentColor,
      ),
    );
  }

  void _timeFracture() {
    player.timeFractureActive = true;
    player.timeFractureTimer = 4.5;
    player.invulnerable = true;
    player.invulnTimer = 0.6;
    _spawnVfx('fracture');
    _spawnVfx('particles');
    for (final e in enemies) {
      if (e.dead) continue;
      e.slowMul = 0.35;
      e.markTimer = max(e.markTimer, 4.5);
    }
  }

  int get _accentColor {
    final c = character.accent;
    return (0xFF << 24) |
        (((c.r * 255.0).round() & 0xFF) << 16) |
        (((c.g * 255.0).round() & 0xFF) << 8) |
        ((c.b * 255.0).round() & 0xFF);
  }

  void _spawnVfx(String key) {
    final mapped = switch (key) {
      'slash' =>
        '${character.id == 'blade' ? 'blade' : character.id == 'phantom' ? 'phantom' : 'runner'}_slash',
      'dash' => 'runner_dash',
      'afterimage' =>
        character.id == 'phantom' ? 'phantom_phase' : 'runner_afterimage',
      'muzzle' => 'hunter_muzzle',
      'mark' => 'hunter_mark',
      'wave' => 'blade_wave',
      'phase' => 'phantom_phase',
      'particles' => 'phantom_particles',
      'fracture' => 'phantom_fracture',
      _ => 'runner_slash',
    };
    // Remap character-specific slash for hunter
    final vfxKey =
        character.id == 'hunter' && key == 'slash' ? 'hunter_impact' : mapped;
    particles.add(
      RunnerParticle(
        x: playerWorldX + 36,
        y: player.y + player.height * 0.55,
        vx: 20,
        vy: 10,
        life: 0.35,
        colorValue: _accentColor,
        size: 18,
        vfxKey: vfxKey,
      ),
    );
  }

  RunnerRect _meleeHitbox() {
    final finisher = player.comboStep >= 3;
    final range = RunnerConfig.meleeRange *
        (finisher ? 1.15 : 1) *
        (character.id == 'blade' ? 1.2 : 1);
    return RunnerRect(
      playerWorldX + player.xOffset + 20,
      player.y + 10,
      range,
      RunnerConfig.meleeHeight,
    );
  }

  bool _resolveMeleeHits() {
    final finisher = player.comboStep >= 3;
    final box = _meleeHitbox();
    var hit = false;
    for (final e in enemies) {
      if (e.dead) continue;
      if (!box.overlaps(e.hitbox)) continue;
      final crit = _rng.nextDouble() < player.critChance;
      var dmg = player.meleeDamage * (finisher ? 1.75 : 1);
      if (crit) dmg *= player.critMult;
      _damageEnemy(
        e,
        dmg,
        crit,
        knockback: finisher ? 140 : 70,
        playHitSfx: false,
      );
      hit = true;
    }
    if (_deflectEnemyProjectiles(box)) {
      hit = true;
    }
    if (hit) {
      player.hitStopTimer = RunnerConfig.hitStop * (finisher ? 1.6 : 1);
      shake = max(shake, finisher ? 7 : 3.5);
    }
    return hit;
  }

  /// Melee swings destroy enemy projectiles that overlap the blade arc.
  bool _deflectEnemyProjectiles(RunnerRect meleeBox) {
    var blocked = false;
    for (final p in projectiles) {
      if (p.dead || p.fromPlayer) continue;
      final radius =
          p.kind == ProjectileKind.voidWave ? 28.0 : RunnerConfig.rangedRadius;
      final pb = RunnerRect(
        p.x - radius,
        p.y - radius,
        radius * 2,
        radius * 2,
      );
      if (!meleeBox.overlaps(pb)) continue;
      p.dead = true;
      blocked = true;
      _sfx(RunnerSfx.block);
      particles.add(
        RunnerParticle(
          x: p.x,
          y: p.y,
          vx: 40,
          vy: -60,
          life: 0.22,
          colorValue: 0xFF00E5FF,
          size: 14,
          vfxKey: character.id == 'blade' ? 'blade_slash' : 'runner_slash',
        ),
      );
      floatingTexts.add(
        RunnerFloatingText(
          x: p.x,
          y: p.y + 20,
          text: 'BLOCK',
          critical: false,
        ),
      );
    }
    return blocked;
  }

  void _damageEnemy(
    RunnerEnemy e,
    double dmg,
    bool crit, {
    double knockback = 60,
    bool fromRanged = false,
    bool playHitSfx = true,
  }) {
    if (e.ai == EnemyAiState.death) return;
    var finalDmg = dmg;
    if (e.marked && fromRanged) finalDmg *= 1.4;
    if (player.timeFractureActive) finalDmg *= 1.45;
    if (fromRanged && e.blocksRanged) {
      final absorb = min(finalDmg, e.shieldHp);
      e.shieldHp -= absorb;
      finalDmg -= absorb;
      if (e.shieldHp <= 0) e.shieldUp = false;
    }
    if (finalDmg <= 0) {
      e.ai = EnemyAiState.hit;
      e.stateTimer = 0.15;
      e.anim = EnemyAnim.hit;
      return;
    }
    e.hp -= finalDmg;
    e.hitFlash = 0.12;
    e.x += knockback * 0.016 * 60;
    floatingTexts.add(
      RunnerFloatingText(
        x: e.x + e.width * 0.5,
        y: e.y + e.height,
        text: crit
            ? '${finalDmg.toStringAsFixed(0)}!'
            : finalDmg.toStringAsFixed(0),
        critical: crit,
      ),
    );
    _burst(
      e.x + e.width * 0.5,
      e.y + e.height * 0.5,
      crit ? 14 : 8,
      crit ? 0xFFFFB703 : 0xFFFFFFFF,
    );
    if (playHitSfx) _sfx(RunnerSfx.enemyHit);
    if (e.hp <= 0) {
      if (e.isBoss) {
        director.onBossDefeated();
        run.bossesDefeated += 1;
        _bossWarned = false;
      }
      e.ai = EnemyAiState.death;
      e.stateTimer = 0.5;
      e.anim = EnemyAnim.death;
      return;
    }
    e.ai = EnemyAiState.hit;
    e.stateTimer = 0.15;
    e.anim = EnemyAnim.hit;
  }

  void _onKill(RunnerEnemy e) {
    run.kills += 1;
    run.combo += 1;
    run.comboTimer = 2.5;
    run.bestCombo = max(run.bestCombo, run.combo);
    run.multiplier = (1 + run.combo * 0.05).clamp(1.0, 4.0);
    final scoreGain =
        (e.score * run.multiplier).round() + RunnerConfig.killScore ~/ 5;
    run.score += scoreGain;
    run.coins += max(1, (e.coins * player.coinMultiplier).round());
    run.xp += max(1, (e.xp * player.xpMultiplier).round());
    player.ultimateCharge =
        (player.ultimateCharge + 1).clamp(0, player.ultimateChargeMax);
    _burst(e.x + e.width / 2, e.y + e.height / 2, 18, _accentColor);
    shake = max(shake, 4);
    _sfx(RunnerSfx.enemyKill);
    _sfx(RunnerSfx.pickup);
  }

  void _updatePlayer(double dt) {
    if (player.disruptTimer > 0) player.disruptTimer -= dt;
    if (player.invulnTimer > 0) {
      player.invulnTimer -= dt;
      if (player.invulnTimer <= 0) {
        player.invulnerable = false;
        // End PHASE speed surge with i-frames.
        if (character.abilityId == CharacterAbilityId.phase &&
            player.moveSpeedMul > _runSpeedBase &&
            _runSpeedBase > 0) {
          player.moveSpeedMul = _runSpeedBase;
        }
      }
    }
    if (player.dodgeCooldown > 0) player.dodgeCooldown -= dt;
    if (player.abilityCooldown > 0) player.abilityCooldown -= dt;
    if (player.abilityTimer > 0) {
      player.abilityTimer -= dt;
      if (player.abilityTimer <= 0 && player.onGround) {
        player.anim = PlayerAnim.run;
      }
    }
    if (player.ultimateTimer > 0) {
      player.ultimateTimer -= dt;
      if (player.ultimateTimer <= 0 && player.onGround) {
        player.anim = PlayerAnim.run;
      }
    }
    if (player.markTimer > 0) {
      player.markTimer -= dt;
      if (player.markTimer <= 0) player.markActive = false;
    }
    if (player.timeFractureTimer > 0) {
      player.timeFractureTimer -= dt;
      if (player.timeFractureTimer <= 0) {
        player.timeFractureActive = false;
        for (final e in enemies) {
          e.slowMul = 1;
        }
      }
    }
    if (player.landTimer > 0) {
      player.landTimer -= dt;
      if (player.landTimer <= 0 &&
          player.onGround &&
          !player.sliding &&
          !player.dodging) {
        player.anim = PlayerAnim.run;
      }
    }
    if (player.comboTimer > 0) {
      player.comboTimer -= dt;
      if (player.comboTimer <= 0) player.comboStep = 0;
    }
    if (player.meleeTimer > 0) player.meleeTimer -= dt;

    if (player.dodging) {
      player.dodgeTimer -= dt;
      final dur = player.abilityTimer > 0 ? 0.4 : RunnerConfig.dodgeDuration;
      final tt = 1 - (player.dodgeTimer / dur).clamp(0.0, 1.0);
      player.xOffset = sin(tt * pi) *
          (player.abilityTimer > 0 ? 56 : RunnerConfig.dodgeAmplitude) *
          player.dodgeDir;
      if (player.dodgeTimer <= 0) {
        player.dodging = false;
        player.xOffset = 0;
        if (player.onGround &&
            player.abilityTimer <= 0 &&
            player.ultimateTimer <= 0) {
          player.anim = PlayerAnim.run;
        }
      }
    }

    if (player.sliding) {
      player.slideTimer -= dt;
      if (player.slideTimer <= 0) {
        player.sliding = false;
        if (player.onGround) player.anim = PlayerAnim.run;
      }
    }

    if (player.rangedCharges < player.rangedMaxCharges &&
        player.rangedCharges == 0 &&
        player.rangedReloadTimer > 0) {
      player.rangedReloadTimer -= dt;
      if (player.rangedReloadTimer <= 0) {
        player.rangedCharges = player.rangedMaxCharges;
        _burst(playerWorldX, player.y + 50, 10, _accentColor);
        _sfx(RunnerSfx.reload);
      }
    }

    // Gravity
    if (!player.onGround) {
      player.vy -= RunnerConfig.gravity * dt;
      player.y += player.vy * dt;
      if (player.vy < 0 &&
          player.anim != PlayerAnim.dead &&
          player.abilityTimer <= 0 &&
          player.ultimateTimer <= 0) {
        player.anim = PlayerAnim.fall;
      }
      if (player.y <= RunnerConfig.groundY) {
        player.y = RunnerConfig.groundY;
        player.vy = 0;
        player.onGround = true;
        if (!player.sliding &&
            !player.dodging &&
            player.meleeTimer <= 0 &&
            player.abilityTimer <= 0 &&
            player.ultimateTimer <= 0) {
          player.anim = PlayerAnim.land;
          player.landTimer = 0.18;
          player.animTime = 0;
        }
        _burst(playerWorldX, player.y + 4, 8, 0x88FFFFFF);
        shake = max(shake, 1.5);
      }
    } else if (!player.sliding &&
        !player.dodging &&
        player.meleeTimer <= 0 &&
        player.landTimer <= 0 &&
        player.abilityTimer <= 0 &&
        player.ultimateTimer <= 0 &&
        player.anim != PlayerAnim.ranged &&
        player.anim != PlayerAnim.dead &&
        player.anim != PlayerAnim.hit) {
      player.anim = PlayerAnim.run;
    }
  }

  double _updateWorld(double dt) {
    final disruptMul = player.disruptTimer > 0 ? 0.7 : 1.0;
    final speed = RunnerConfig.runSpeedBase *
        player.moveSpeedMul *
        disruptMul *
        (1 + run.survived * 0.008);
    final dx = speed * dt;
    scrollX += dx;
    run.distance += dx / 40;
    run.score += (dx / 40 * RunnerConfig.distanceScorePerMeter * run.multiplier)
        .round()
        .clamp(0, 50);

    if (run.comboTimer > 0) {
      run.comboTimer -= dt;
      if (run.comboTimer <= 0) {
        run.combo = 0;
        run.multiplier = 1;
      }
    }

    for (final h in hazards) {
      h.x -= dx;
      h.life -= dt;
    }
    hazards.removeWhere((h) => h.x < -100 || h.life <= 0);

    for (final p in projectiles) {
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      if (p.kind == ProjectileKind.rain) {
        p.vy -= 900 * dt;
      }
      p.life -= dt;
      if (p.life <= 0 || p.x > scrollX + 2000) p.dead = true;
    }
    projectiles.removeWhere((p) => p.dead);
    return dx;
  }

  void _updateEnemies(double dt, double dx) {
    for (final e in enemies) {
      if (e.dead) continue;
      e.animTime += dt;
      e.bobPhase += dt * 4;
      if (e.hitFlash > 0) e.hitFlash -= dt;
      if (e.markTimer > 0) {
        e.markTimer -= dt;
        if (e.markTimer <= 0) e.marked = false;
      }

      final slow = e.slowMul * (player.timeFractureActive ? 0.45 : 1.0);
      final scroll = dx * 0.12 * slow;

      if (e.ai == EnemyAiState.death) {
        e.stateTimer -= dt;
        e.x -= scroll;
        if (e.stateTimer <= 0) {
          e.dead = true;
          _onKill(e);
        }
        continue;
      }

      if (e.ai == EnemyAiState.hit) {
        e.stateTimer -= dt;
        e.x -= scroll;
        if (e.stateTimer <= 0) {
          e.ai = EnemyAiState.approach;
          e.anim = e.flying ? EnemyAnim.fly : EnemyAnim.move;
        }
        continue;
      }

      if (e.ai == EnemyAiState.spawning) {
        e.stateTimer -= dt;
        e.x -= scroll;
        if (e.stateTimer <= 0) {
          e.ai = EnemyAiState.approach;
          e.anim = e.flying ? EnemyAnim.fly : EnemyAnim.move;
        }
        continue;
      }

      if (e.ai == EnemyAiState.special) {
        e.stateTimer -= dt;
        e.x -= scroll;
        if (e.stateTimer <= 0) {
          e.ai = EnemyAiState.approach;
          e.anim = e.flying ? EnemyAnim.fly : EnemyAnim.move;
        }
        continue;
      }

      _updateEnemyShield(e);
      _updateBossPhase(e);

      if (e.flying) {
        e.y = e.def.flyHeight + sin(e.bobPhase) * 10;
        e.anim = EnemyAnim.fly;
      } else {
        e.y = RunnerConfig.groundY;
      }

      final distToPlayer = e.x - playerWorldX;
      _updateEnemyMovement(e, dt, distToPlayer, slow);
      e.x -= scroll;

      if (e.def.canTeleport &&
          e.attackCd <= 0 &&
          distToPlayer > 180 &&
          _rng.nextDouble() < 0.012) {
        e.x = playerWorldX + 70 + _rng.nextDouble() * 80;
        e.attackCd = e.def.attackCooldown;
        e.ai = EnemyAiState.special;
        e.anim = EnemyAnim.special;
        e.stateTimer = 0.35;
        continue;
      }

      if (e.attackCd > 0) {
        e.attackCd -= dt;
      } else {
        _tryEnemyAttack(e, distToPlayer);
      }
    }
    enemies.removeWhere((e) => e.dead || e.x < -120);
  }

  void _updateEnemyShield(RunnerEnemy e) {
    final id = e.def.id;
    if (id == 'guardian' || id == 'shield_maiden' || id == 'apex_sentinel') {
      e.shieldUp = e.def.hasShield && e.shieldHp > 0;
    }
  }

  void _updateBossPhase(RunnerEnemy e) {
    if (!e.isBoss) return;
    final hpPct = e.hp / e.maxHp;
    if (hpPct <= 0.33) {
      e.bossPhase = 3;
    } else if (hpPct <= 0.66) {
      e.bossPhase = 2;
    } else {
      e.bossPhase = 1;
    }
  }

  void _updateEnemyMovement(
    RunnerEnemy e,
    double dt,
    double distToPlayer,
    double slow,
  ) {
    // Always advance toward the player. Ranged foes may hold at preferred
    // range to shoot, but they never back away.
    final holdAt = e.def.keepsDistance
        ? e.def.preferredRange
        : e.def.attackRange.clamp(40.0, 90.0);
    if (distToPlayer.abs() <= holdAt) {
      return;
    }
    final step = e.speed * dt * slow;
    if (distToPlayer > 0) {
      e.x -= step;
    } else {
      e.x += step;
    }
    e.anim = e.flying ? EnemyAnim.fly : EnemyAnim.move;
  }

  void _tryEnemyAttack(RunnerEnemy e, double distToPlayer) {
    if (_isRangedEnemy(e)) {
      if (distToPlayer <= e.def.attackRange && distToPlayer > 36) {
        _enemyRangedAttack(e);
        e.attackCd = _enemyAttackCooldown(e);
        e.ai = EnemyAiState.attack;
      }
      return;
    }
    if (distToPlayer <= e.def.attackRange.clamp(55, 120)) {
      e.anim = EnemyAnim.attack;
      e.ai = EnemyAiState.attack;
      e.attackCd = _enemyAttackCooldown(e);
    }
  }

  bool _isRangedEnemy(RunnerEnemy e) {
    return e.def.role == EnemyRole.ranged ||
        e.def.keepsDistance ||
        e.def.id == 'missile_drone' ||
        e.def.id == 'sniper_drone' ||
        e.def.id == 'bomber_drone' ||
        e.def.id == 'war_machine' ||
        e.def.id == 'fortress' ||
        e.def.id == 'rift_reaper' ||
        e.def.id == 'overseer';
  }

  double _enemyAttackCooldown(RunnerEnemy e) {
    var cd = e.def.attackCooldown;
    if (e.isBoss) cd *= max(0.55, 1.1 - e.bossPhase * 0.15);
    return cd;
  }

  void _enemyRangedAttack(RunnerEnemy e) {
    e.anim = EnemyAnim.ranged;
    final bossMul = e.isBoss ? 0.75 + e.bossPhase * 0.25 : 1.0;
    final dmg = e.damage * bossMul;
    final kind = _projectileKindForEnemy(e.def.id);
    final assetKey = _projectileAssetForEnemy(e.def.id);
    final vx = -(380.0 + (e.isBoss ? 90.0 : 0.0) + e.bossPhase * 20.0);
    projectiles.add(
      RunnerProjectile(
        x: e.x,
        y: e.y + e.height * 0.55,
        vx: vx,
        damage: dmg.toDouble(),
        critical: false,
        kind: kind,
        colorValue: _enemyAccentColor(e.def),
        fromPlayer: false,
        assetKey: assetKey,
      ),
    );
  }

  ProjectileKind _projectileKindForEnemy(String id) => switch (id) {
        'shocker' => ProjectileKind.electric,
        'missile_drone' || 'bomber_drone' => ProjectileKind.missile,
        'sniper_drone' => ProjectileKind.laser,
        'rift_reaper' || 'corrupted_wraith' => ProjectileKind.rift,
        'war_machine' || 'fortress' || 'overseer' => ProjectileKind.bullet,
        _ => ProjectileKind.bullet,
      };

  String _projectileAssetForEnemy(String id) => switch (id) {
        'shocker' => 'electric',
        'missile_drone' || 'bomber_drone' => 'missile',
        'sniper_drone' => 'laser',
        'rift_reaper' || 'corrupted_wraith' => 'rift',
        'war_machine' || 'fortress' || 'overseer' => 'bullet',
        _ => 'bullet',
      };

  int _enemyAccentColor(EnemyDefinition def) {
    final c = def.accent;
    return (0xFF << 24) |
        (((c.r * 255.0).round() & 0xFF) << 16) |
        (((c.g * 255.0).round() & 0xFF) << 8) |
        ((c.b * 255.0).round() & 0xFF);
  }

  void _updateCombat(double dt) {
    final pBox = player.hitbox(playerWorldX);
    final meleeActive = player.meleeTimer > 0;
    final meleeBox = meleeActive ? _meleeHitbox() : null;
    if (meleeBox != null) {
      _deflectEnemyProjectiles(meleeBox);
    }

    for (final p in projectiles) {
      if (p.dead) continue;
      final radius =
          p.kind == ProjectileKind.voidWave ? 28.0 : RunnerConfig.rangedRadius;
      final pb = RunnerRect(
        p.x - radius,
        p.y - radius,
        radius * 2,
        radius * 2,
      );

      if (p.fromPlayer) {
        for (final e in enemies) {
          if (e.dead || e.ai == EnemyAiState.death) continue;
          if (!pb.overlaps(e.hitbox)) continue;
          _damageEnemy(
            e,
            p.damage,
            p.critical,
            knockback: p.kind == ProjectileKind.voidWave ? 180 : 90,
            fromRanged: true,
          );
          if (p.kind != ProjectileKind.voidWave) p.dead = true;
          particles.add(
            RunnerParticle(
              x: e.x,
              y: e.y + e.height * 0.5,
              vx: 0,
              vy: 0,
              life: 0.25,
              colorValue: p.colorValue,
              size: 16,
              vfxKey: character.id == 'hunter'
                  ? 'hunter_impact'
                  : character.id == 'blade'
                      ? 'blade_impact'
                      : 'runner_slash',
            ),
          );
          break;
        }
        continue;
      }

      if (player.health <= 0) continue;
      if (!pb.overlaps(pBox)) continue;
      // Dodge / i-frames let shots pass through instead of waiting to hit later.
      if (player.dodging || player.invulnerable) {
        p.dead = true;
        _burst(p.x, p.y, 8, p.colorValue);
        continue;
      }
      _playerHit(
        max(1, p.damage.round()),
        disrupt: p.kind == ProjectileKind.electric,
      );
      p.dead = true;
    }

    if (player.invulnerable || player.health <= 0) return;

    for (final e in enemies) {
      if (e.dead || e.ai == EnemyAiState.death) continue;
      if (!e.flying && !player.onGround && player.y >= e.height * 0.55) {
        continue;
      }
      if (!pBox.overlaps(e.hitbox)) continue;
      _playerHit(
        e.damage,
        disrupt: e.def.id == 'shocker',
      );
      e.x += 80;
      break;
    }

    for (final h in hazards) {
      h.animTime += dt;
      if (h.telegraph > 0) {
        h.telegraph -= dt;
        if (h.telegraph <= 0) h.active = true;
        continue;
      }
      if (!h.active || h.consumed) continue;
      if (!pBox.overlaps(h.hitbox)) continue;

      switch (h.kind) {
        case HazardKind.spike:
          if (h.requiresJump && !player.onGround) continue;
        case HazardKind.laserBar:
        case HazardKind.laserTurret:
          if (h.requiresSlide && player.sliding) continue;
        case HazardKind.electricFloor:
          if (player.dodging) continue;
        case HazardKind.fallingDebris:
        case HazardKind.explosiveBarrel:
          break;
      }

      _playerHit(h.damage);
      if (h.kind == HazardKind.explosiveBarrel ||
          h.kind == HazardKind.fallingDebris) {
        h.consumed = true;
      }
    }
  }

  void _playerHit(int dmg, {bool disrupt = false}) {
    if (player.invulnerable) return;
    final mitigated = max(1, (dmg / player.armorMul).round());
    final applied =
        character.id == 'blade' && dmg > 1 ? max(1, dmg - 1) : mitigated;
    player.health = (player.health - applied).clamp(0, player.maxHealth);
    player.invulnerable = true;
    player.invulnTimer = RunnerConfig.invulnAfterHit;
    player.anim = PlayerAnim.hit;
    player.animTime = 0;
    if (disrupt) player.disruptTimer = 0.8;
    run.combo = 0;
    run.multiplier = 1;
    run.comboTimer = 0;
    shake = max(shake, 8);
    _burst(playerWorldX, player.y + 40, 12, 0xFFFF3B3B);
    _sfx(RunnerSfx.playerHit);
  }

  void _updateBossSpawn(double dt) {
    if (enemies.length >= 12) return;
    // Dramatic telegraph a few seconds before the boss enters.
    if (!director.bossActive &&
        !_bossWarned &&
        run.survived >= 55 &&
        director.bossTimer <= 3.2 &&
        director.bossTimer > 0) {
      _bossWarned = true;
      _sfx(RunnerSfx.bossWarning);
    }
    final bossDef = director.maybeBoss(run.survived, dt);
    if (bossDef == null) return;
    _id += 1;
    final baseX = playerWorldX + 520 + _rng.nextDouble() * 80;
    enemies.add(
      RunnerEnemy(
        id: 'e$_id',
        def: bossDef,
        x: baseX,
        y: bossDef.flying ? bossDef.flyHeight : RunnerConfig.groundY,
      ),
    );
    _sfx(RunnerSfx.enemySpawn);
  }

  void _spawn(double dt) {
    spawnTimer -= dt;
    if (spawnTimer > 0) return;
    final t = run.survived;
    final interval = (RunnerConfig.spawnIntervalStart - t * 0.04)
        .clamp(RunnerConfig.spawnIntervalMin, RunnerConfig.spawnIntervalStart);
    spawnTimer = interval;

    if (enemies.length >= 12) return;
    if (director.bossActive) return;

    final def = director.pickRegular(t);
    _id += 1;
    final baseX = playerWorldX + 520 + _rng.nextDouble() * 180;
    enemies.add(
      RunnerEnemy(
        id: 'e$_id',
        def: def,
        x: baseX,
        y: def.flying ? def.flyHeight : RunnerConfig.groundY,
      ),
    );
    _sfx(RunnerSfx.enemySpawn);

    if (t > 12 && _rng.nextDouble() < 0.28) {
      _spawnHazard(director.pickHazard(t), baseX + 200);
    }
  }

  void _spawnHazard(HazardKind kind, double x) {
    switch (kind) {
      case HazardKind.spike:
        hazards.add(
          RunnerHazard(
            x: x,
            y: RunnerConfig.groundY,
            width: 54,
            height: 30,
            requiresJump: true,
            kind: kind,
            telegraph: 0.6,
            active: false,
          ),
        );
      case HazardKind.laserBar:
        hazards.add(
          RunnerHazard(
            x: x,
            y: RunnerConfig.groundY + 42,
            width: 78,
            height: 36,
            requiresSlide: true,
            kind: kind,
            telegraph: 0.5,
            active: false,
          ),
        );
      case HazardKind.laserTurret:
        hazards.add(
          RunnerHazard(
            x: x,
            y: RunnerConfig.groundY + 38,
            width: 64,
            height: 40,
            requiresSlide: true,
            kind: kind,
            telegraph: 0.7,
            active: false,
          ),
        );
      case HazardKind.electricFloor:
        hazards.add(
          RunnerHazard(
            x: x,
            y: RunnerConfig.groundY,
            width: 90,
            height: 20,
            kind: kind,
            telegraph: 0.4,
            active: false,
          ),
        );
      case HazardKind.fallingDebris:
        hazards.add(
          RunnerHazard(
            x: x,
            y: RunnerConfig.groundY + 120,
            width: 60,
            height: 50,
            kind: kind,
            telegraph: 0.8,
            active: false,
          ),
        );
      case HazardKind.explosiveBarrel:
        hazards.add(
          RunnerHazard(
            x: x,
            y: RunnerConfig.groundY,
            width: 48,
            height: 56,
            kind: kind,
            telegraph: 0.5,
            active: false,
          ),
        );
    }
  }

  void _updateVfx(double dt) {
    for (final p in particles) {
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.vy -= 400 * dt;
      p.life -= dt;
    }
    particles.removeWhere((p) => p.life <= 0);
    for (final t in floatingTexts) {
      t.y += 40 * dt;
      t.life -= dt;
    }
    floatingTexts.removeWhere((t) => t.life <= 0);
  }

  void _updateVisualOnly(double dt) {
    player.animTime += dt;
    _updateVfx(dt);
    shake = (shake - dt * 8).clamp(0.0, 12.0);
  }

  void _burst(double x, double y, int n, int color) {
    for (var i = 0; i < n; i++) {
      final a = _rng.nextDouble() * pi * 2;
      final s = 40 + _rng.nextDouble() * 120;
      particles.add(
        RunnerParticle(
          x: x,
          y: y,
          vx: cos(a) * s,
          vy: sin(a) * s,
          life: 0.2 + _rng.nextDouble() * 0.35,
          colorValue: color,
          size: 2 + _rng.nextDouble() * 3,
        ),
      );
    }
  }

  void jumpWithPower(double power) {
    if (phase != RunnerPhase.playing) {
      bufferInput(RunnerInput.jump);
      return;
    }
    if (_jump(power: power)) {
      _buffered = null;
    } else {
      bufferInput(RunnerInput.jump);
    }
  }
}
