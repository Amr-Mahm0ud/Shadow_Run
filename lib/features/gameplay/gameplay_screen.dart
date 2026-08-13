import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/config/feature_flags.dart';
import '../../core/config/game_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../game/engine/game_engine.dart';
import '../../game/engine/game_phase.dart';
import '../../game/player/characters.dart';
import '../../game/player/player.dart';
import '../../game/powerups/powerup.dart';
import '../../game/systems/upgrades.dart';
import '../../services/service_locator.dart';
import '../home/home_screen.dart';
import '../settings/settings_screen.dart';
import 'pause_menu.dart';

class GameplayScreen extends StatefulWidget {
  const GameplayScreen({super.key});

  @override
  State<GameplayScreen> createState() => _GameplayScreenState();
}

class _GameplayScreenState extends State<GameplayScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _animation;
  late final GameEngine _engine;

  final ValueNotifier<int> _score = ValueNotifier<int>(0);
  final ValueNotifier<int> _lives = ValueNotifier<int>(GameConfig.startingLives);
  final ValueNotifier<int> _runIndex = ValueNotifier<int>(0);
  final ValueNotifier<HeroStatus> _heroStatus =
      ValueNotifier<HeroStatus>(HeroStatus.run);
  final ValueNotifier<bool> _enemyVisible = ValueNotifier<bool>(true);
  final ValueNotifier<GamePhase> _phase =
      ValueNotifier<GamePhase>(GamePhase.countdown);
  final ValueNotifier<Color> _skyColor =
      ValueNotifier<Color>(Colors.amber);
  final ValueNotifier<Color> _sunColor =
      ValueNotifier<Color>(Colors.deepOrange);

  Timer? _spriteTimer;
  Timer? _statusResetTimer;
  Timer? _countdownTimer;
  Timer? _runTimer;
  bool _imagesPrecached = false;
  bool _rewardsSaved = false;
  int _countdown = 3;
  List<PowerUpDefinition> _powerChoices = const [];

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
    // Silence unused catalog reference for tree-shaking clarity in tests.
    assert(UpgradeCatalog.all.isNotEmpty);
    return stats;
  }

  @override
  void initState() {
    super.initState();
    _engine = GameEngine(starterStats: _buildRunStats());
    _lives.value = _engine.player.lives;
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _engine.enemyDurationMs),
    );
    _animation = Tween<Offset>(
      begin: const Offset(3.2, 3.15),
      end: const Offset(-3.5, 3.15),
    ).animate(_controller);

    _controller.addListener(_onTick);
    _startSpriteLoop();
    _startCountdown();
    AppServices.analytics.logGameStarted(
      characterId: _engine.player.stats.characterId,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_imagesPrecached) return;
    _imagesPrecached = true;
    _precacheGameImages();
  }

  Future<void> _precacheGameImages() async {
    final paths = <String>{
      ..._engine.player.runImages,
      _engine.player.attackImage,
      ..._engine.player.dieImages,
      _engine.enemy.image,
    };
    await Future.wait(
      paths.map((path) => precacheImage(AssetImage(path), context)),
    );
  }

  void _startCountdown() {
    _phase.value = GamePhase.countdown;
    _countdown = 3;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_countdown <= 1) {
        t.cancel();
        _engine.startPlaying();
        _phase.value = GamePhase.playing;
        _runTimer?.cancel();
        _runTimer = Timer.periodic(const Duration(seconds: 1), (_) {
          if (!mounted || !_phase.value.isInteractive) return;
          _engine.run.survived += const Duration(seconds: 1);
        });
        _controller.forward();
        setState(() {});
        return;
      }
      setState(() => _countdown -= 1);
    });
  }

  void _startSpriteLoop() {
    _spriteTimer?.cancel();
    _spriteTimer = Timer.periodic(
      const Duration(milliseconds: GameConfig.spriteFrameMs),
      (_) {
        if (!mounted || !_phase.value.isInteractive) return;
        if (_heroStatus.value != HeroStatus.run) return;
        _runIndex.value =
            (_runIndex.value + 1) % _engine.player.runImages.length;
      },
    );
  }

  void _onTick() {
    if (!mounted || !_phase.value.isInteractive) return;

    final dx = _animation.value.dx;
    final outcome = _engine.evaluateCollisionAt(dx);
    switch (outcome) {
      case CollisionOutcome.playerHit:
        _heroStatus.value = _engine.player.status;
        _lives.value = _engine.player.lives;
        if (_engine.phase == GamePhase.gameOver) {
          _endGame();
          return;
        }
        _scheduleStatusReset();
      case CollisionOutcome.enemyKilled:
        _enemyVisible.value = false;
        _score.value = _engine.run.score;
        if (_engine.maybeFlipTheme()) {
          _skyColor.value = _engine.skyAmber
              ? Colors.amber
              : Colors.white.withValues(alpha: 0.9);
          _sunColor.value =
              _engine.skyAmber ? Colors.deepOrange : Colors.yellow;
        }
        if (FeatureFlags.powerUpsEnabled && _engine.shouldOfferLevelUp) {
          _offerPowerUp();
          return;
        }
      case CollisionOutcome.none:
        break;
    }

    if (_engine.shouldResetWave(dx)) {
      _resetEnemyWave();
    }
  }

  void _offerPowerUp() {
    _controller.stop();
    _engine.enterLevelUp();
    _phase.value = GamePhase.levelUp;
    _powerChoices = PowerUpCatalog.randomChoices(3);
    setState(() {});
  }

  void _selectPowerUp(PowerUpDefinition powerUp) {
    _engine.applyPowerUp(powerUp);
    AppServices.analytics.logPowerUpSelected(powerUpId: powerUp.id.name);
    _engine.finishLevelUp();
    _phase.value = GamePhase.playing;
    _resetEnemyWave();
  }

  void _scheduleStatusReset() {
    _statusResetTimer?.cancel();
    _statusResetTimer = Timer(
      Duration(
        milliseconds:
            (_engine.enemyDurationMs / GameConfig.attackWindowDivisor).floor(),
      ),
      () {
        if (!mounted || _engine.phase == GamePhase.gameOver) return;
        _engine.endAttackWindow();
        _heroStatus.value = _engine.player.status;
      },
    );
  }

  void _resetEnemyWave() {
    _controller.stop();
    final durationMs = _engine.advanceWaveDifficulty();
    _enemyVisible.value = true;
    _controller.duration = Duration(milliseconds: durationMs);
    _controller.reset();
    if (_phase.value == GamePhase.playing || _phase.value == GamePhase.boss) {
      _controller.forward();
    }
    setState(() {});
  }

  void _endGame() {
    _phase.value = GamePhase.gameOver;
    _controller.stop();
    _spriteTimer?.cancel();
    _statusResetTimer?.cancel();
    _runTimer?.cancel();
    AppServices.analytics.logPlayerDied(score: _engine.run.score);
    _saveRewards();
  }

  Future<void> _saveRewards() async {
    if (_rewardsSaved) return;
    _rewardsSaved = true;
    await AppServices.highScores.submitScore(_engine.run.score);
    final progress = await AppServices.progress.applyRunRewards(
      score: _engine.run.score,
      coins: _engine.run.coinsEarned,
      xp: _engine.run.xpEarned,
      kills: _engine.run.enemiesDefeated,
    );
    await AppServices.analytics.logGameEnded(
      score: _engine.run.score,
      durationMs: _engine.run.survived.inMilliseconds,
      enemies: _engine.run.enemiesDefeated,
    );
    if (progress.level > 1) {
      await AppServices.analytics.logLevelUp(level: progress.level);
    }
    if (mounted) {
      _engine.enterReward();
      _phase.value = GamePhase.reward;
      setState(() {});
    }
  }

  void _onAttack() {
    if (!_phase.value.allowsAttack) return;
    _engine.beginAttack();
    _heroStatus.value = _engine.player.status;
    _scheduleStatusReset();
  }

  void _togglePause() {
    if (!FeatureFlags.pauseEnabled) return;
    if (_phase.value == GamePhase.playing || _phase.value == GamePhase.boss) {
      _pauseGame();
    } else if (_phase.value == GamePhase.paused) {
      _resumeGame();
    }
  }

  void _pauseGame() {
    if (!FeatureFlags.pauseEnabled) return;
    if (_phase.value != GamePhase.playing && _phase.value != GamePhase.boss) {
      return;
    }
    _statusResetTimer?.cancel();
    _engine.pause();
    _phase.value = GamePhase.paused;
    _controller.stop();
    setState(() {});
  }

  void _resumeGame() {
    if (_phase.value != GamePhase.paused) return;
    _engine.resume();
    _phase.value = GamePhase.playing;
    if (!_controller.isCompleted) {
      _controller.forward();
    }
    setState(() {});
  }

  void _restartFromPause() {
    _statusResetTimer?.cancel();
    _runTimer?.cancel();
    _countdownTimer?.cancel();
    _go(const GameplayScreen());
  }

  void _homeFromPause() {
    _statusResetTimer?.cancel();
    _runTimer?.cancel();
    _countdownTimer?.cancel();
    _go(const HomeScreen());
  }

  Future<void> _openSettingsFromPause() async {
    if (_phase.value != GamePhase.paused) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
    // Remain paused until the player explicitly resumes.
    if (mounted && _phase.value == GamePhase.paused) {
      setState(() {});
    }
  }

  void _go(Widget page) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_onTick);
    _controller.dispose();
    _spriteTimer?.cancel();
    _statusResetTimer?.cancel();
    _countdownTimer?.cancel();
    _runTimer?.cancel();
    _score.dispose();
    _lives.dispose();
    _runIndex.dispose();
    _heroStatus.dispose();
    _enemyVisible.dispose();
    _phase.dispose();
    _skyColor.dispose();
    _sunColor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    final size = responsive.size;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final heroH = (size.height * (responsive.isTablet ? 0.28 : 0.25))
        .clamp(72.0, 220.0);
    final enemyH = (size.height * (responsive.isTablet ? 0.22 : 0.2))
        .clamp(56.0, 180.0);
    final heroW = (size.width * 0.28).clamp(96.0, 280.0);
    final enemyW = (size.width * 0.28).clamp(96.0, 280.0);
    final heroCacheH = (heroH * dpr).round();
    final enemyCacheH = (enemyH * dpr).round();
    final attackPadH = responsive.scale(28).clamp(18.0, 40.0);
    final attackPadV = responsive.scale(36).clamp(24.0, 52.0);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          RepaintBoundary(
            child: ValueListenableBuilder<Color>(
              valueListenable: _skyColor,
              builder: (_, color, __) => Align(
                alignment: Alignment.topCenter,
                child: ColoredBox(
                  color: color,
                  child: SizedBox(width: size.width, height: size.height * 0.8),
                ),
              ),
            ),
          ),
          const RepaintBoundary(child: _StarsLayer()),
          Align(
            alignment: const Alignment(0, 0.65),
            child: SlideTransition(
              position: _animation,
              child: ColoredBox(
                color: Colors.white54,
                child: SizedBox(
                  width: size.width * 0.55,
                  height: responsive.scale(10).clamp(6.0, 14.0),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Stack(
              children: [
                Align(
                  alignment: const Alignment(0.05, -1),
                  child: Padding(
                    padding: EdgeInsets.only(top: responsive.scale(4)),
                    child: ValueListenableBuilder<int>(
                      valueListenable: _score,
                      builder: (_, score, __) => Text(
                        'Score: $score',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppColors.voidBlack,
                              fontWeight: FontWeight.w800,
                              fontSize: responsive.sp(22),
                            ),
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: responsive.scale(2),
                      right: responsive.scale(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ValueListenableBuilder<int>(
                          valueListenable: _lives,
                          builder: (_, lives, __) => Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (var i = 0; i < 3; i++)
                                Icon(
                                  Icons.favorite,
                                  size: responsive.scale(26).clamp(18.0, 34.0),
                                  color: lives > i
                                      ? AppColors.danger
                                      : Colors.white54,
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _togglePause,
                          icon: ValueListenableBuilder<GamePhase>(
                            valueListenable: _phase,
                            builder: (_, phase, __) => Icon(
                              phase == GamePhase.paused
                                  ? Icons.play_arrow
                                  : Icons.pause,
                              color: AppColors.voidBlack,
                              size: responsive.scale(28).clamp(22.0, 36.0),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: const Alignment(-0.9, -0.9),
            child: ValueListenableBuilder<Color>(
              valueListenable: _sunColor,
              builder: (_, color, __) {
                final sun = (size.shortestSide * 0.22).clamp(56.0, 140.0);
                return Container(
                  width: sun,
                  height: sun,
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle),
                );
              },
            ),
          ),
          Align(
            alignment: const Alignment(-0.9, 0.5),
            child: RepaintBoundary(
              child: SizedBox(
                height: heroH,
                width: heroW,
                child: AnimatedBuilder(
                  animation: Listenable.merge([_heroStatus, _runIndex]),
                  builder: (_, __) {
                    final path = switch (_heroStatus.value) {
                      HeroStatus.run =>
                        _engine.player.runImages[_runIndex.value],
                      HeroStatus.attack => _engine.player.attackImage,
                      HeroStatus.die => _engine.player.dieImages[2],
                    };
                    return Image.asset(
                      path,
                      fit: BoxFit.contain,
                      alignment: Alignment.bottomCenter,
                      cacheHeight: heroCacheH,
                      filterQuality: FilterQuality.low,
                      gaplessPlayback: true,
                    );
                  },
                ),
              ),
            ),
          ),
          SlideTransition(
            position: _animation,
            child: RepaintBoundary(
              child: SizedBox(
                height: enemyH,
                width: enemyW,
                child: ValueListenableBuilder<bool>(
                  valueListenable: _enemyVisible,
                  builder: (_, visible, child) => AnimatedOpacity(
                    opacity: visible ? 1 : 0,
                    duration: Duration(
                      milliseconds: (_engine.enemyDurationMs / 20).floor(),
                    ),
                    child: child,
                  ),
                  child: Image.asset(
                    _engine.enemy.image,
                    fit: BoxFit.contain,
                    alignment: Alignment.bottomCenter,
                    cacheHeight: enemyCacheH,
                    filterQuality: FilterQuality.low,
                    gaplessPlayback: true,
                    key: ValueKey(_engine.enemy.definition.id),
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: const Alignment(0.9, 0.35),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.only(right: responsive.scale(8)),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(size.height),
                    ),
                    backgroundColor: Colors.black54,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: attackPadH,
                      vertical: attackPadV,
                    ),
                    elevation: 0,
                    minimumSize: Size(
                      responsive.scale(96).clamp(72.0, 140.0),
                      responsive.scale(96).clamp(72.0, 140.0),
                    ),
                  ),
                  onPressed: _onAttack,
                  child: Text(
                    'ATTACK',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontSize: responsive.sp(20),
                        ),
                  ),
                ),
              ),
            ),
          ),
          if (_phase.value == GamePhase.countdown)
            _CountdownOverlay(value: _countdown),
          if (_phase.value == GamePhase.levelUp)
            _PowerUpOverlay(
              choices: _powerChoices,
              onSelected: _selectPowerUp,
            ),
          ValueListenableBuilder<GamePhase>(
            valueListenable: _phase,
            builder: (_, phase, __) {
              if (phase == GamePhase.paused) {
                return PauseMenu(
                  onResume: _resumeGame,
                  onRestart: _restartFromPause,
                  onSettings: _openSettingsFromPause,
                  onHome: _homeFromPause,
                );
              }
              if (phase != GamePhase.gameOver && phase != GamePhase.reward) {
                return const SizedBox.shrink();
              }
              return _RewardOverlay(
                engine: _engine,
                ready: phase == GamePhase.reward,
                onMainMenu: () => _go(const HomeScreen()),
                onPlayAgain: () => _go(const GameplayScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StarsLayer extends StatelessWidget {
  const _StarsLayer();

  static const List<(double size, double x, double y)> _stars = [
    (10, 0.0, 0.0),
    (5, 0.5, 0.3),
    (20, -0.6, 0.2),
    (15, 0.35, -0.5),
    (30, -0.3, -0.5),
    (7, -1.0, -0.3),
    (12, 0.7, -0.2),
    (17, 1.0, -0.7),
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        for (final star in _stars)
          Align(
            alignment: Alignment(star.$2, star.$3),
            child: Icon(Icons.star_sharp, size: star.$1),
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
          value == 0 ? 'GO' : '$value',
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                color: AppColors.neonCyan,
              ),
        ),
      ),
    );
  }
}

class _PowerUpOverlay extends StatelessWidget {
  const _PowerUpOverlay({
    required this.choices,
    required this.onSelected,
  });

  final List<PowerUpDefinition> choices;
  final ValueChanged<PowerUpDefinition> onSelected;

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    return ColoredBox(
      color: Colors.black87,
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: responsive.scale(640).clamp(320.0, 720.0),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: responsive.scale(12)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'CHOOSE ONE',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppColors.neonCyan,
                          fontSize: responsive.sp(28),
                        ),
                  ),
                  SizedBox(height: responsive.scale(16)),
                  Row(
                    children: [
                      for (final choice in choices)
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.all(responsive.scale(6)),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.panel,
                                foregroundColor: Colors.white,
                                minimumSize: Size.fromHeight(
                                  responsive.scale(100).clamp(80.0, 130.0),
                                ),
                              ),
                              onPressed: () => onSelected(choice),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  FittedBox(
                                    child: Text(
                                      choice.title,
                                      style: TextStyle(
                                        fontSize: responsive.sp(16),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: responsive.scale(6)),
                                  Text(
                                    choice.description,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: AppColors.mist,
                                      fontSize: responsive.sp(13),
                                    ),
                                  ),
                                ],
                              ),
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
      ),
    );
  }
}

class _RewardOverlay extends StatelessWidget {
  const _RewardOverlay({
    required this.engine,
    required this.ready,
    required this.onMainMenu,
    required this.onPlayAgain,
  });

  final GameEngine engine;
  final bool ready;
  final VoidCallback onMainMenu;
  final VoidCallback onPlayAgain;

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    final size = responsive.size;
    final run = engine.run;
    return ColoredBox(
      color: Colors.black54,
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: (size.width * 0.7).clamp(280.0, 560.0),
              maxHeight: (size.height * 0.85).clamp(260.0, 520.0),
            ),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(responsive.scale(20)),
              decoration: BoxDecoration(
                color: AppColors.panel,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.neonMagenta.withValues(alpha: 0.5),
                ),
              ),
              child: ready
                  ? SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Text(
                            'YOU DIED',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  color: AppColors.danger,
                                  fontSize: responsive.sp(28),
                                ),
                          ),
                          SizedBox(height: responsive.scale(10)),
                          Text('Score: ${run.score}'),
                          Text('Coins: +${run.coinsEarned}'),
                          Text('XP: +${run.xpEarned}'),
                          Text('Enemies: ${run.enemiesDefeated}'),
                          Text('Time: ${run.survived.inSeconds}s'),
                          SizedBox(height: responsive.scale(16)),
                          Wrap(
                            spacing: responsive.scale(12),
                            runSpacing: responsive.scale(8),
                            alignment: WrapAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: onMainMenu,
                                child: const Text('HOME'),
                              ),
                              ElevatedButton(
                                onPressed: onPlayAgain,
                                child: const Text('PLAY AGAIN'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  : const Center(child: CircularProgressIndicator()),
            ),
          ),
        ),
      ),
    );
  }
}
