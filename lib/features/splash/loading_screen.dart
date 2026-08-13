import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/branding/brand_logo.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../game/characters/character_assets.dart';
import '../../game/enemies/enemy_assets.dart';
import '../home/home_screen.dart';

/// Boot splash: symbol + wordmark with a calm cyan energy sweep.
class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<double> _sweep;
  late final Animation<double> _glow;
  var _ready = false;
  var _minTimeElapsed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..forward();
    _fade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
    );
    _sweep = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.25, 0.85, curve: Curves.easeInOut),
    );
    _glow = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.15, end: 0.45), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.45, end: 0.22), weight: 1),
    ]).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.2, 1.0, curve: Curves.easeInOut),
      ),
    );

    unawaited(_bootstrap());
    Future<void>.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      _minTimeElapsed = true;
      _maybeEnter();
    });
  }

  Future<void> _bootstrap() async {
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    await Future.wait([
      CharacterAssetBundle.ensureLoaded(),
      EnemyAssetBundle.ensureLoaded(),
    ]);
    if (!mounted) return;
    _ready = true;
    _maybeEnter();
  }

  void _maybeEnter() {
    if (!_ready || !_minTimeElapsed || !mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 480),
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionsBuilder: (_, anim, __, child) {
          return FadeTransition(opacity: anim, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final responsive = Responsive.of(context);
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.voidBlack,
              AppColors.deepNavy,
              Color(0xFF16102A),
            ],
          ),
        ),
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) {
            return Stack(
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity: _glow.value,
                  child: Container(
                    width: responsive.scale(280),
                    height: responsive.scale(280),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.neonCyan.withValues(alpha: 0.22),
                          AppColors.neonMagenta.withValues(alpha: 0.05),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                FadeTransition(
                  opacity: _fade,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      BrandLogo(
                        variant: BrandLogoVariant.symbol,
                        height: responsive.scale(88).clamp(64.0, 112.0),
                      ),
                      SizedBox(height: responsive.scale(18)),
                      SizedBox(
                        width: responsive.scale(420).clamp(260.0, 520.0),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            const BrandLogo(
                              variant: BrandLogoVariant.wordmark,
                              height: 52,
                              alignment: Alignment.center,
                            ),
                            Positioned.fill(
                              child: IgnorePointer(
                                child: FractionallySizedBox(
                                  widthFactor: 0.35,
                                  alignment: Alignment(
                                    -1.2 + (_sweep.value * 2.4),
                                    0,
                                  ),
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.transparent,
                                          AppColors.neonCyan
                                              .withValues(alpha: 0.35),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: responsive.scale(16)),
                      Text(
                        l10n.taglineSecondary,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.mist,
                              letterSpacing: 1.2,
                              fontSize: responsive.sp(14),
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
