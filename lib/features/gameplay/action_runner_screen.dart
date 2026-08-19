import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../core/branding/brand_logo.dart';
import '../../core/config/feature_flags.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../data/repositories/settings_repository.dart';
import '../../game/characters/character_assets.dart';
import '../../game/enemies/enemy_assets.dart';
import '../../game/player/characters.dart';
import '../../game/player/player.dart';
import '../../game/runner/runner_config.dart';
import '../../game/runner/runner_entities.dart';
import '../../game/runner/runner_simulation.dart';
import '../../game/systems/upgrades.dart';
import '../../services/service_locator.dart';
import '../home/home_screen.dart';
import '../settings/settings_screen.dart';
import 'pause_menu.dart';
import 'runner_button_controls.dart';
import 'runner_gesture_layer.dart';
import 'runner_world_painter.dart';

class ActionRunnerScreen extends StatefulWidget {
  const ActionRunnerScreen({super.key});

  @override
  State<ActionRunnerScreen> createState() => _ActionRunnerScreenState();
}

class _ActionRunnerScreenState extends State<ActionRunnerScreen>
    with SingleTickerProviderStateMixin {
  late final RunnerSimulation _sim;
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
  double _time = 0;
  int _countdown = 3;
  Timer? _countdownTimer;
  bool _rewardsSaved = false;

  PlayerStats _buildRunStats() {
    final progress = AppServices.progress.read();
    final character =
        CharacterCatalog.byId(progress.selectedCharacterId).baseStats;
    var stats = character;
    final levels = progress.upgradeLevels;
    double levelBonus(String id, double perLevel) =>
        (levels[id] ?? 0) * perLevel;

    stats = stats.copyWith(
      damage: stats.damage + levelBonus('damage', 0.08),
      speed: stats.speed + levelBonus('speed', 0.05),
      attackSpeed: stats.attackSpeed + levelBonus('attack_speed', 0.05),
      reloadSpeed: stats.attackSpeed +
          levelBonus('attack_speed', 0.05) +
          levelBonus('ranged_reload', 0.08),
      criticalChance: stats.criticalChance + levelBonus('crit_chance', 0.02),
      criticalDamage: stats.criticalDamage + levelBonus('crit_damage', 0.1),
      coinMultiplier: stats.coinMultiplier + levelBonus('coin_mul', 0.08),
      xpMultiplier: stats.xpMultiplier + levelBonus('xp_mul', 0.08),
      maxHealth: stats.maxHealth + (levels['health'] ?? 0),
      health: stats.maxHealth + (levels['health'] ?? 0),
    );
    assert(UpgradeCatalog.all.isNotEmpty);
    return stats;
  }

  @override
  void initState() {
    super.initState();
    _sim = RunnerSimulation(starterStats: _buildRunStats());
    AppServices.feedback.setCharacterProfile(_sim.character.id);
    _sim.onSfx = (event) {
      AppServices.feedback.playRunnerSfx(
        event,
        characterId: _sim.character.id,
      );
    };
    _ticker = createTicker(_onTick)..start();
    _startCountdown();
    AppServices.analytics.logGameStarted(
      characterId: _buildRunStats().characterId,
    );
    CharacterAssetBundle.ensureLoaded();
    EnemyAssetBundle.ensureLoaded();
    AppServices.feedback.resetRunAudio();
    AppServices.feedback.setGameplayMusic(true);
  }

  void _startCountdown() {
    _countdown = 3;
    _sim.phase = RunnerPhase.countdown;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_countdown <= 1) {
        t.cancel();
        _sim.startPlaying();
        setState(() => _countdown = 0);
        return;
      }
      setState(() => _countdown -= 1);
    });
  }

  void _onTick(Duration elapsed) {
    if (!mounted) return;
    final dt = _lastElapsed == Duration.zero
        ? 0.0
        : (elapsed - _lastElapsed).inMicroseconds / 1e6;
    _lastElapsed = elapsed;
    if (dt <= 0 || dt > 0.1) {
      setState(() {});
      return;
    }
    _time += dt;
    final wasPlaying = _sim.phase == RunnerPhase.playing;
    _sim.tick(dt);
    if (wasPlaying && _sim.phase == RunnerPhase.dead) {
      _onDeath();
    }
    setState(() {});
  }

  Future<void> _onDeath() async {
    if (_rewardsSaved) return;
    _rewardsSaved = true;
    _ticker.stop();
    AppServices.analytics.logPlayerDied(score: _sim.run.score);
    AppServices.analytics.logGameEnded(
      score: _sim.run.score,
      durationMs: (_sim.run.survived * 1000).round(),
      enemies: _sim.run.kills,
    );
    await AppServices.highScores.submitScore(_sim.run.score);
    final progress = await AppServices.progress.applyRunRewards(
      coins: _sim.run.coins,
      xp: _sim.run.xp,
      kills: _sim.run.kills,
      score: _sim.run.score,
    );
    await AppServices.missions.recordRun(
      runKills: _sim.run.kills,
      totalKills: progress.totalKills,
      score: _sim.run.score,
      surviveSeconds: _sim.run.survived.round(),
      coinsEarned: _sim.run.coins,
      playerLevel: progress.level,
    );
    await AppServices.feedback.heavyImpact();
    if (!mounted) return;
    _sim.enterReward();
    setState(() {});
  }

  void _onGesture(RunnerInput input, {double power = 1}) {
    if (_sim.phase == RunnerPhase.countdown) return;
    if (input == RunnerInput.jump) {
      _sim.jumpWithPower(power);
    } else {
      _sim.bufferInput(input);
    }
  }

  void _pauseGame() {
    if (!FeatureFlags.pauseEnabled) return;
    if (_sim.phase != RunnerPhase.playing) return;
    _sim.pause();
    AppServices.feedback.pauseCue();
    setState(() {});
  }

  void _resumeGame() {
    if (_sim.phase != RunnerPhase.paused) return;
    _sim.resume();
    AppServices.feedback.resumeCue();
    setState(() {});
  }

  void _restart() {
    _countdownTimer?.cancel();
    AppServices.feedback.resetRunAudio();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ActionRunnerScreen()),
    );
  }

  void _home() {
    _countdownTimer?.cancel();
    _ticker.stop();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  Future<void> _settings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
    if (mounted) {
      await AppServices.feedback.applyVolumes();
      setState(() {});
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _ticker.dispose();
    AppServices.feedback.setGameplayMusic(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    final playing = _sim.phase == RunnerPhase.playing;
    final paused = _sim.phase == RunnerPhase.paused;
    final useButtons =
        AppServices.settings.read().controlScheme == ControlScheme.buttons;
    _sim.playerWorldX =
        useButtons ? RunnerConfig.playerXButtons : RunnerConfig.playerX;

    final world = Stack(
      fit: StackFit.expand,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final groundY = constraints.maxHeight * 0.72;
            return CustomPaint(
              painter: RunnerWorldPainter(
                sim: _sim,
                groundY: groundY,
                time: _time,
              ),
              size: Size(constraints.maxWidth, constraints.maxHeight),
            );
          },
        ),
        _RunnerHud(
          sim: _sim,
          responsive: responsive,
          onPause: _pauseGame,
        ),
        if (_sim.activeBoss != null)
          _BossBar(boss: _sim.activeBoss!, responsive: responsive),
        if (_sim.phase == RunnerPhase.countdown)
          _CountdownOverlay(value: _countdown),
        if (paused)
          PauseMenu(
            onResume: _resumeGame,
            onRestart: _restart,
            onSettings: _settings,
            onHome: _home,
          ),
        if (_sim.phase == RunnerPhase.reward ||
            _sim.phase == RunnerPhase.dead && _rewardsSaved)
          _RunnerRewardOverlay(
            sim: _sim,
            onRetry: _restart,
            onHome: _home,
          ),
        if (playing && useButtons)
          RunnerButtonControls(
            onInput: _onGesture,
            abilityReady: _sim.player.abilityReady,
            ultimateReady: _sim.player.ultimateReady,
            dodgeReady: _sim.player.dodgeCooldown <= 0,
            rangedCharges: _sim.player.rangedCharges,
          ),
        if (playing && !useButtons && _sim.run.survived < 5)
          Positioned(
            left: 16,
            right: 16,
            bottom: 12,
            child: IgnorePointer(
              child: Text(
                AppLocalizations.of(context).hintControls,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.mist.withValues(alpha: 0.8),
                  fontSize: responsive.sp(12),
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
      ],
    );

    return Scaffold(
      backgroundColor: AppColors.voidBlack,
      body: useButtons
          ? world
          : RunnerGestureLayer(
              enabled: playing && !paused,
              ultimateReady: _sim.player.ultimateReady,
              abilityReady: _sim.player.abilityReady,
              onGesture: _onGesture,
              child: world,
            ),
    );
  }
}

class _RunnerHud extends StatelessWidget {
  const _RunnerHud({
    required this.sim,
    required this.responsive,
    required this.onPause,
  });

  final RunnerSimulation sim;
  final Responsive responsive;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    final p = sim.player;
    final s = sim.run;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: responsive.scale(12),
          vertical: responsive.scale(8),
        ),
        child: Column(
          children: [
            Row(
              children: [
                _HealthPips(health: p.health, max: p.maxHealth),
                const Spacer(),
                Text(
                  _formatScore(s.score),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: responsive.sp(22),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    shadows: const [
                      Shadow(blurRadius: 8, color: Colors.black87),
                    ],
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: onPause,
                  icon: const Icon(Icons.pause_circle_filled_rounded),
                  color: AppColors.neonCyan,
                  iconSize: responsive.scale(34).clamp(28.0, 40.0),
                ),
              ],
            ),
            SizedBox(height: responsive.scale(6)),
            Row(
              children: [
                _ComboBadge(combo: s.combo, mult: s.multiplier),
                const Spacer(),
                _AbilityMeters(player: p),
                const SizedBox(width: 10),
                _RangedMeter(
                  charges: p.rangedCharges,
                  maxCharges: p.rangedMaxCharges,
                  reloadTimer: p.rangedReloadTimer,
                  reloadTotal: RunnerConfig.rangedReload * p.reloadMul,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatScore(int score) {
    if (score >= 10000) return '${(score / 1000).toStringAsFixed(1)}k';
    return '$score';
  }
}

class _AbilityMeters extends StatelessWidget {
  const _AbilityMeters({required this.player});
  final RunnerPlayer player;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final abilityPct = player.abilityReady
        ? 1.0
        : 1 -
            (player.abilityCooldown / player.abilityCooldownMax)
                .clamp(0.0, 1.0);
    final ultPct =
        (player.ultimateCharge / player.ultimateChargeMax).clamp(0.0, 1.0);
    return Row(
      children: [
        _miniMeter(
            l10n.ability, abilityPct, AppColors.neonCyan, player.abilityReady),
        const SizedBox(width: 8),
        _miniMeter(l10n.ult, ultPct, AppColors.gold, player.ultimateReady),
      ],
    );
  }

  Widget _miniMeter(String label, double value, Color color, bool ready) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ready ? '$label!' : label,
          style: TextStyle(
            color: ready ? color : AppColors.mist,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(
          width: 48,
          height: 4,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: Colors.white12,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _BossBar extends StatelessWidget {
  const _BossBar({required this.boss, required this.responsive});
  final ActiveBoss boss;
  final Responsive responsive;

  @override
  Widget build(BuildContext context) {
    final accent = boss.enemy.def.accent;
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: EdgeInsets.only(top: responsive.scale(52)),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: responsive.scale(420)),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: accent.withValues(alpha: 0.6)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          boss.name,
                          style: TextStyle(
                            color: accent,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.4,
                            fontSize: responsive.sp(13),
                          ),
                        ),
                      ),
                      Text(
                        'PHASE ${boss.phase}',
                        style: TextStyle(
                          color: AppColors.mist,
                          fontSize: responsive.sp(11),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: boss.hpPct,
                      minHeight: 8,
                      backgroundColor: Colors.white12,
                      color: accent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HealthPips extends StatelessWidget {
  const _HealthPips({required this.health, required this.max});
  final int health;
  final int max;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < max; i++)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Icon(
              Icons.favorite,
              size: 18,
              color: i < health
                  ? AppColors.danger
                  : AppColors.mist.withValues(alpha: 0.25),
            ),
          ),
      ],
    );
  }
}

class _ComboBadge extends StatelessWidget {
  const _ComboBadge({required this.combo, required this.mult});
  final int combo;
  final double mult;

  @override
  Widget build(BuildContext context) {
    if (combo <= 1) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.panel.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.neonMagenta.withValues(alpha: 0.5)),
      ),
      child: Text(
        'COMBO x$combo  ·  ${mult.toStringAsFixed(1)}x',
        style: const TextStyle(
          color: AppColors.neonMagenta,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _RangedMeter extends StatelessWidget {
  const _RangedMeter({
    required this.charges,
    required this.maxCharges,
    required this.reloadTimer,
    required this.reloadTotal,
  });

  final int charges;
  final int maxCharges;
  final double reloadTimer;
  final double reloadTotal;

  @override
  Widget build(BuildContext context) {
    final reloading = charges == 0 && reloadTimer > 0;
    final progress =
        reloading ? 1 - (reloadTimer / reloadTotal).clamp(0.0, 1.0) : 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          children: [
            for (var i = 0; i < maxCharges; i++)
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(left: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < charges
                      ? AppColors.neonCyan
                      : AppColors.mist.withValues(alpha: 0.2),
                  boxShadow: i < charges
                      ? [
                          BoxShadow(
                            color: AppColors.neonCyan.withValues(alpha: 0.5),
                            blurRadius: 6,
                          ),
                        ]
                      : null,
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 72,
          height: 4,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: reloading ? progress : (charges / maxCharges),
              backgroundColor: Colors.white12,
              color: reloading ? AppColors.gold : AppColors.neonCyan,
            ),
          ),
        ),
      ],
    );
  }
}

class _CountdownOverlay extends StatelessWidget {
  const _CountdownOverlay({required this.value});
  final int value;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black45,
      child: Center(
        child: Text(
          value == 0 ? 'RUN' : '$value',
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
            color: AppColors.neonCyan,
            shadows: [
              Shadow(
                color: AppColors.neonMagenta.withValues(alpha: 0.6),
                blurRadius: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RunnerRewardOverlay extends StatelessWidget {
  const _RunnerRewardOverlay({
    required this.sim,
    required this.onRetry,
    required this.onHome,
  });

  final RunnerSimulation sim;
  final VoidCallback onRetry;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final responsive = Responsive.of(context);
    final s = sim.run;
    final scores = AppServices.highScores.readTopScores();
    final best = scores.isNotEmpty ? scores.first : 0;
    final isBest = s.score >= best && s.score > 0;

    final buttonStyle = ElevatedButton.styleFrom(
      minimumSize: Size(0, responsive.scale(48).clamp(44.0, 56.0)),
      padding: EdgeInsets.symmetric(
        horizontal: responsive.scale(16),
        vertical: responsive.scale(14).clamp(12.0, 18.0),
      ),
      tapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
    );

    return Material(
      color: Colors.black54,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final margin = responsive.scale(12).clamp(8.0, 16.0);
            final maxPanelHeight = (constraints.maxHeight - margin * 2)
                .clamp(120.0, double.infinity);
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: responsive.scale(420).clamp(260.0, 520.0),
                  maxHeight: maxPanelHeight,
                ),
                child: Container(
                  margin: EdgeInsets.all(margin),
                  padding: EdgeInsets.fromLTRB(
                    responsive.scale(18),
                    responsive.scale(16),
                    responsive.scale(18),
                    responsive.scale(14),
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.panel,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.neonMagenta.withValues(alpha: 0.45),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.neonCyan.withValues(alpha: 0.15),
                        blurRadius: 24,
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.zero,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            BrandLogo(
                              variant: BrandLogoVariant.symbol,
                              height: 36,
                              alignment: Alignment.center,
                            ),
                            SizedBox(width: responsive.scale(10)),
                            Text(
                              l10n.gameOver,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(color: AppColors.neonCyan),
                            ),
                          ],
                        ),
                        if (isBest) ...[
                          SizedBox(height: responsive.scale(4)),
                          Text(
                            l10n.newHighScore,
                            style: const TextStyle(
                              color: AppColors.gold,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                        SizedBox(height: responsive.scale(8)),
                        Row(
                          children: [
                            Expanded(child: _stat(l10n.score, '${s.score}')),
                            SizedBox(width: responsive.scale(12)),
                            Expanded(
                              child: _stat(
                                l10n.distance,
                                '${s.distance.toStringAsFixed(0)}m',
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(child: _stat(l10n.enemies, '${s.kills}')),
                            SizedBox(width: responsive.scale(12)),
                            Expanded(
                              child: _stat(l10n.bestCombo, '${s.bestCombo}'),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(child: _stat(l10n.coins, '+${s.coins}')),
                            SizedBox(width: responsive.scale(12)),
                            Expanded(child: _stat('XP', '+${s.xp}')),
                          ],
                        ),
                        SizedBox(height: responsive.scale(8)),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: onHome,
                                style: buttonStyle.copyWith(
                                  backgroundColor: const WidgetStatePropertyAll(
                                    AppColors.deepNavy,
                                  ),
                                  foregroundColor: const WidgetStatePropertyAll(
                                    Colors.white,
                                  ),
                                ),
                                child: Text(
                                  l10n.menu,
                                  overflow: TextOverflow.visible,
                                  softWrap: false,
                                ),
                              ),
                            ),
                            SizedBox(width: responsive.scale(10)),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: onRetry,
                                style: buttonStyle,
                                child: Text(
                                  l10n.retry,
                                  overflow: TextOverflow.visible,
                                  softWrap: false,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.mist)),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
