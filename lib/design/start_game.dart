import 'dart:async';

import 'package:flutter/material.dart';
import 'package:multi_media_game/logic/controller.dart';
import 'package:multi_media_game/logic/models/enemy.dart';
import 'package:multi_media_game/logic/models/hero.dart';

import 'home.dart';

class StartGame extends StatefulWidget {
  const StartGame({Key? key}) : super(key: key);

  @override
  State<StartGame> createState() => _GameState();
}

class _GameState extends State<StartGame> with SingleTickerProviderStateMixin {
  static const int _minTimerMs = 1500;
  static const int _timerStepMs = 200;
  static const int _initialTimerMs = 6000;
  static const double _hitMinX = -0.2;
  static const double _hitMaxX = 0.5;
  static const double _resetX = -1.5;

  late final AnimationController _controller;
  late final Animation<Offset> _animation;

  final HeroCharacter _hero = HeroCharacter();
  final Enemy _enemy = Enemy();

  final ValueNotifier<int> _score = ValueNotifier<int>(0);
  final ValueNotifier<int> _lives = ValueNotifier<int>(3);
  final ValueNotifier<int> _runIndex = ValueNotifier<int>(0);
  final ValueNotifier<String> _heroStatus = ValueNotifier<String>('run');
  final ValueNotifier<String> _enemyStatus = ValueNotifier<String>('run');
  final ValueNotifier<bool> _gameOver = ValueNotifier<bool>(false);
  final ValueNotifier<Color> _skyColor = ValueNotifier<Color>(Colors.amber);
  final ValueNotifier<Color> _sunColor =
      ValueNotifier<Color>(Colors.deepOrange);

  Timer? _spriteTimer;
  Timer? _statusResetTimer;
  bool _hitHandled = false;
  bool _waveHandled = false;
  bool _imagesPrecached = false;
  int _timerMs = _initialTimerMs;
  int _lastThemeScore = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _timerMs),
    );
    _animation = Tween<Offset>(
      begin: const Offset(3.2, 3.15),
      end: const Offset(-3.5, 3.15),
    ).animate(_controller);

    _controller.addListener(_onTick);
    _startSpriteLoop();
    _controller.forward();
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
      ..._hero.runImages,
      _hero.attackImage,
      ..._hero.dieImages,
      _enemy.image,
    };
    await Future.wait(
      paths.map((path) => precacheImage(AssetImage(path), context)),
    );
  }

  void _startSpriteLoop() {
    _spriteTimer?.cancel();
    _spriteTimer = Timer.periodic(const Duration(milliseconds: 120), (_) {
      if (!mounted || _gameOver.value) return;
      if (_heroStatus.value != 'run') return;
      _runIndex.value = (_runIndex.value + 1) % _hero.runImages.length;
    });
  }

  void _onTick() {
    if (!mounted || _gameOver.value) return;

    final dx = _animation.value.dx;

    if (dx < _hitMaxX && dx > _hitMinX) {
      if (!_hitHandled) {
        _hitHandled = true;
        _handleCollision();
      }
    } else if (dx >= _hitMaxX) {
      _hitHandled = false;
    }

    if (dx < _resetX && !_waveHandled) {
      _waveHandled = true;
      _resetEnemyWave();
    }
  }

  void _handleCollision() {
    if (_enemyStatus.value == 'run' && _heroStatus.value == 'run') {
      _hero.die();
      _heroStatus.value = _hero.status;
      _lives.value = _hero.lives;
      if (_hero.lives == 0) {
        _endGame();
        return;
      }
      _statusResetTimer?.cancel();
      _statusResetTimer = Timer(
        Duration(milliseconds: (_timerMs / 8).floor()),
        () {
          if (!mounted || _gameOver.value) return;
          _hero.run();
          _heroStatus.value = _hero.status;
        },
      );
    } else if (_heroStatus.value == 'attack' && _enemyStatus.value == 'run') {
      _enemy.die(_hero.status);
      _enemyStatus.value = _enemy.status;
      _score.value += 5;
      _maybeUpdateTheme();
    }
  }

  void _resetEnemyWave() {
    _controller.stop();
    _enemy.run();
    _enemyStatus.value = _enemy.status;
    _hitHandled = false;

    if (_timerMs > _minTimerMs) {
      _timerMs -= _timerStepMs;
      if (_timerMs < _minTimerMs) _timerMs = _minTimerMs;
    }

    _controller.duration = Duration(milliseconds: _timerMs);
    _controller.reset();
    _waveHandled = false;
    _controller.forward();
  }

  void _maybeUpdateTheme() {
    final score = _score.value;
    if (score <= 0 || score % 50 != 0 || score == _lastThemeScore) return;
    _lastThemeScore = score;
    final isAmber = _skyColor.value == Colors.amber;
    _skyColor.value =
        isAmber ? Colors.white.withValues(alpha: 0.9) : Colors.amber;
    _sunColor.value = isAmber ? Colors.yellow : Colors.deepOrange;
  }

  void _endGame() {
    _gameOver.value = true;
    _controller.stop();
    _spriteTimer?.cancel();
    _statusResetTimer?.cancel();
  }

  void _onAttack() {
    if (_gameOver.value || _heroStatus.value == 'die') return;
    _hero.attack();
    _heroStatus.value = _hero.status;
    _statusResetTimer?.cancel();
    _statusResetTimer = Timer(
      Duration(milliseconds: (_timerMs / 8).floor()),
      () {
        if (!mounted || _gameOver.value) return;
        _hero.run();
        _heroStatus.value = _hero.status;
      },
    );
  }

  void _saveAndGo(Widget page) {
    HighScore().updateScore(_score.value);
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
    _score.dispose();
    _lives.dispose();
    _runIndex.dispose();
    _heroStatus.dispose();
    _enemyStatus.dispose();
    _gameOver.dispose();
    _skyColor.dispose();
    _sunColor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final heroCacheH = (size.height * 0.25 * MediaQuery.of(context).devicePixelRatio).round();
    final enemyCacheH = (size.height * 0.2 * MediaQuery.of(context).devicePixelRatio).round();

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
                child: SizedBox(width: size.width * 0.55, height: 10),
              ),
            ),
          ),
          Align(
            alignment: const Alignment(0.15, -0.8),
            child: SizedBox(
              width: size.width * 0.2,
              child: ValueListenableBuilder<int>(
                valueListenable: _score,
                builder: (_, score, __) => Text(
                  'Score: $score',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
          ),
          Align(
            alignment: const Alignment(0.9, -0.9),
            child: SizedBox(
              width: size.width * 0.1,
              child: ValueListenableBuilder<int>(
                valueListenable: _lives,
                builder: (_, lives, __) => Row(
                  children: [
                    Icon(Icons.favorite,
                        color: lives > 0 ? Colors.red : Colors.white),
                    Icon(Icons.favorite,
                        color: lives > 1 ? Colors.red : Colors.white),
                    Icon(Icons.favorite,
                        color: lives > 2 ? Colors.red : Colors.white),
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: const Alignment(-0.9, -0.9),
            child: ValueListenableBuilder<Color>(
              valueListenable: _sunColor,
              builder: (_, color, __) => Container(
                width: size.height * 0.25,
                height: size.height * 0.25,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ),
          ),
          Align(
            alignment: const Alignment(-0.9, 0.5),
            child: RepaintBoundary(
              child: SizedBox(
                height: size.height * 0.25,
                width: size.width * 0.3,
                child: AnimatedBuilder(
                  animation: Listenable.merge([_heroStatus, _runIndex]),
                  builder: (_, __) {
                    final path = _heroStatus.value == 'run'
                        ? _hero.runImages[_runIndex.value]
                        : _heroStatus.value == 'attack'
                            ? _hero.attackImage
                            : _hero.dieImages[2];
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
                height: size.height * 0.2,
                width: size.width * 0.3,
                child: ValueListenableBuilder<String>(
                  valueListenable: _enemyStatus,
                  builder: (_, status, child) => AnimatedOpacity(
                    opacity: status == 'die' ? 0 : 1,
                    duration: Duration(milliseconds: (_timerMs / 20).floor()),
                    child: child,
                  ),
                  child: Image.asset(
                    _enemy.image,
                    fit: BoxFit.contain,
                    alignment: Alignment.bottomCenter,
                    cacheHeight: enemyCacheH,
                    filterQuality: FilterQuality.low,
                    gaplessPlayback: true,
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: const Alignment(0.9, 0.35),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(size.height),
                ),
                backgroundColor: Colors.black54,
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 45),
                elevation: 0,
              ),
              onPressed: _onAttack,
              child: Text(
                'attack',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(color: Colors.white),
              ),
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: _gameOver,
            builder: (_, over, __) {
              if (!over) return const SizedBox.shrink();
              return ColoredBox(
                color: Colors.black54,
                child: SizedBox(
                  width: size.width,
                  height: size.height,
                  child: _RetryOverlay(
                    scoreListenable: _score,
                    onMainMenu: () => _saveAndGo(const Home()),
                    onPlayAgain: () => _saveAndGo(const StartGame()),
                  ),
                ),
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

class _RetryOverlay extends StatelessWidget {
  const _RetryOverlay({
    required this.scoreListenable,
    required this.onMainMenu,
    required this.onPlayAgain,
  });

  final ValueNotifier<int> scoreListenable;
  final VoidCallback onMainMenu;
  final VoidCallback onPlayAgain;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Center(
      child: Container(
        height: size.height * 0.6,
        width: size.width * 0.5,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text(
              'Game Over!',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(color: Colors.black),
            ),
            const Divider(),
            ValueListenableBuilder<int>(
              valueListenable: scoreListenable,
              builder: (_, score, __) => Text(
                'Score: $score',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: onMainMenu,
                  child: const Text('Main Menu'),
                ),
                ElevatedButton(
                  onPressed: onPlayAgain,
                  child: const Text('Play again'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
