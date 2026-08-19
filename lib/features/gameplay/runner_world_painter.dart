import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../game/characters/character_assets.dart';
import '../../game/enemies/enemy_assets.dart';
import '../../game/player/characters.dart';
import '../../game/runner/runner_config.dart';
import '../../game/runner/runner_entities.dart';
import '../../game/runner/runner_simulation.dart';

/// Cyberpunk 2.5D world painter with character sprite sheets + VFX.
class RunnerWorldPainter extends CustomPainter {
  RunnerWorldPainter({
    required this.sim,
    required this.groundY,
    required this.time,
  });

  final RunnerSimulation sim;
  final double groundY;
  final double time;

  @override
  void paint(Canvas canvas, Size size) {
    final shake = sim.shake;
    if (shake > 0) {
      canvas.translate(
        math.sin(time * 40) * shake,
        math.cos(time * 35) * shake * 0.6,
      );
    }

    _paintSky(canvas, size);
    _paintParallaxCity(canvas, size);
    _paintFog(canvas, size);
    _paintGround(canvas, size);
    _paintHazards(canvas, size);
    _paintEnemies(canvas, size);
    _paintProjectiles(canvas, size);
    _paintPlayer(canvas, size);
    _paintParticles(canvas, size);
    _paintFloatingText(canvas, size);
    _paintVignette(canvas, size);
  }

  CharacterDefinition get _char => sim.character;

  void _paintSky(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final sky = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, 0),
        Offset(0, size.height),
        const [
          Color(0xFF050510),
          Color(0xFF0B1028),
          Color(0xFF1A0B2E),
          Color(0xFF12081F),
        ],
        const [0, 0.35, 0.7, 1],
      );
    canvas.drawRect(rect, sky);

    final accent = _char.accent;
    final haze = Paint()
      ..shader = ui.Gradient.radial(
        Offset(size.width * 0.75, size.height * 0.35),
        size.width * 0.55,
        [
          accent.withValues(alpha: 0.14),
          Colors.transparent,
        ],
      );
    canvas.drawRect(rect, haze);

    final haze2 = Paint()
      ..shader = ui.Gradient.radial(
        Offset(size.width * 0.2, size.height * 0.25),
        size.width * 0.4,
        [
          AppColors.neonCyan.withValues(alpha: 0.1),
          Colors.transparent,
        ],
      );
    canvas.drawRect(rect, haze2);
  }

  void _paintParallaxCity(Canvas canvas, Size size) {
    final scroll = sim.scrollX;
    _drawBuildingLayer(
      canvas,
      size,
      scroll * 0.15,
      size.height * 0.22,
      0.55,
      const Color(0xFF101628),
      neon: false,
    );
    _drawBuildingLayer(
      canvas,
      size,
      scroll * 0.35,
      size.height * 0.32,
      0.72,
      const Color(0xFF141C33),
      neon: true,
    );
    _drawBuildingLayer(
      canvas,
      size,
      scroll * 0.55,
      size.height * 0.42,
      0.85,
      const Color(0xFF1A223F),
      neon: true,
      dense: true,
    );
  }

  void _drawBuildingLayer(
    Canvas canvas,
    Size size,
    double scroll,
    double baseHeight,
    double alpha,
    Color color, {
    required bool neon,
    bool dense = false,
  }) {
    final paint = Paint()..color = color.withValues(alpha: alpha);
    final neonPaint = Paint()
      ..color = _char.accent.withValues(alpha: 0.35)
      ..strokeWidth = 1.5;
    final magPaint = Paint()
      ..color = AppColors.neonMagenta.withValues(alpha: 0.4)
      ..strokeWidth = 2;

    final spacing = dense ? 70.0 : 96.0;
    final start = -((scroll) % spacing);
    for (var x = start - spacing; x < size.width + spacing; x += spacing) {
      final seed = ((x + scroll) / spacing).floor();
      final h = baseHeight + (seed % 5) * 18.0 + (seed % 3) * 10;
      final w = dense ? 48.0 + (seed % 4) * 8 : 56.0 + (seed % 3) * 12;
      final top = groundY - h;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, top, w, h),
        const Radius.circular(2),
      );
      canvas.drawRRect(rect, paint);

      if (neon) {
        final windows = 3 + seed % 4;
        for (var i = 0; i < windows; i++) {
          final wy = top + 10 + i * (h / (windows + 1));
          canvas.drawLine(
            Offset(x + 8, wy),
            Offset(x + w - 8, wy),
            (seed + i) % 3 == 0 ? magPaint : neonPaint,
          );
        }
      }
    }
  }

  void _paintFog(Canvas canvas, Size size) {
    final fog = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, groundY - 80),
        Offset(0, groundY + 40),
        [
          Colors.transparent,
          Colors.black.withValues(alpha: 0.35),
        ],
      );
    canvas.drawRect(Offset.zero & size, fog);
  }

  void _paintGround(Canvas canvas, Size size) {
    final ground = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, groundY),
        Offset(0, size.height),
        const [
          Color(0xFF0A0E1A),
          Color(0xFF05070F),
        ],
      );
    canvas.drawRect(
      Rect.fromLTRB(0, groundY, size.width, size.height),
      ground,
    );

    final glow = Paint()
      ..color = _char.accent.withValues(alpha: 0.55)
      ..strokeWidth = 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawLine(Offset(0, groundY), Offset(size.width, groundY), glow);
    canvas.drawLine(
      Offset(0, groundY),
      Offset(size.width, groundY),
      Paint()
        ..color = _char.accent
        ..strokeWidth = 1.2,
    );

    final dashPaint = Paint()
      ..color = AppColors.neonMagenta.withValues(alpha: 0.35)
      ..strokeWidth = 3;
    final scroll = sim.scrollX * 0.9;
    for (var x = -((scroll) % 64); x < size.width; x += 64) {
      canvas.drawLine(
        Offset(x, groundY + 18),
        Offset(x + 28, groundY + 18),
        dashPaint,
      );
    }
  }

  double _sy(double simY) => groundY - simY - 4;

  String _animName(PlayerAnim anim) {
    return switch (anim) {
      PlayerAnim.idle => 'idle',
      PlayerAnim.run => 'run',
      PlayerAnim.jump => 'jump',
      PlayerAnim.fall => 'fall',
      PlayerAnim.land => 'land',
      PlayerAnim.slide => 'slide',
      PlayerAnim.dodge => 'dodge',
      PlayerAnim.melee1 || PlayerAnim.melee2 || PlayerAnim.melee3 => 'melee',
      PlayerAnim.ranged => 'ranged',
      PlayerAnim.hit => 'hit',
      PlayerAnim.dead => 'death',
      PlayerAnim.ability => 'ability',
      PlayerAnim.ultimate => 'ultimate',
    };
  }

  void _paintPlayer(Canvas canvas, Size size) {
    final p = sim.player;
    final x = sim.playerWorldX + p.xOffset;
    final y = _sy(p.y + p.height);
    final w = RunnerConfig.playerWidth * (_char.id == 'blade' ? 1.15 : 1);
    final h = p.height * (_char.id == 'blade' ? 1.08 : 1);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(x + w / 2, groundY + 6),
        width: w * 0.9,
        height: 12,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.45),
    );

    final sheet = CharacterAssetBundle.image(_char.spritesheet);
    final anim = _animName(p.anim);
    final frame = (p.animTime * (p.anim == PlayerAnim.run ? 10 : 8))
        .floor()
        .remainder(CharacterSpriteAtlas.cols);

    if (p.dodging || p.abilityTimer > 0) {
      for (var i = 1; i <= 3; i++) {
        final alpha = 0.22 / i;
        _drawSprite(
          canvas,
          sheet,
          anim,
          frame,
          Rect.fromLTWH(x - p.dodgeDir * i * 14.0, y, w, h),
          alpha: alpha,
          tint: _char.accent.withValues(alpha: alpha),
        );
      }
    }

    final invulnFlash = p.invulnerable && (time * 20).floor().isEven;
    _drawSprite(
      canvas,
      sheet,
      anim,
      frame,
      Rect.fromLTWH(x - 8, y - 8, w + 16, h + 16),
      alpha: invulnFlash ? 0.55 : 1,
    );

    if (p.meleeTimer > 0) {
      final progress = 1 - (p.meleeTimer / RunnerConfig.meleeDuration);
      final slash = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _char.id == 'blade' ? 6 : 4
        ..strokeCap = StrokeCap.round
        ..color = _char.accent.withValues(alpha: 0.85)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      final rect = Rect.fromCircle(
        center: Offset(x + w, y + h * 0.45),
        radius: 30 + p.comboStep * 8,
      );
      canvas.drawArc(rect, -0.8 + progress, 1.6, false, slash);
    }

    if (p.markActive) {
      final mark = CharacterAssetBundle.image('assets/vfx/hunter_mark.png');
      if (mark != null) {
        final dst = Rect.fromCenter(
          center: Offset(x + w / 2, y - 12),
          width: 28,
          height: 28,
        );
        paintImage(canvas: canvas, rect: dst, image: mark, fit: BoxFit.contain);
      }
    }
  }

  void _drawSprite(
    Canvas canvas,
    ui.Image? sheet,
    String anim,
    int frame,
    Rect dst, {
    double alpha = 1,
    Color? tint,
  }) {
    if (sheet != null) {
      final src = CharacterSpriteAtlas.srcRect(anim, frame);
      final paint = Paint()
        ..color = Color.fromRGBO(255, 255, 255, alpha)
        ..filterQuality = FilterQuality.medium;
      canvas.saveLayer(dst, paint);
      canvas.drawImageRect(sheet, src, dst, Paint());
      if (tint != null) {
        canvas.drawRect(
            dst,
            Paint()
              ..color = tint
              ..blendMode = BlendMode.srcATop);
      }
      canvas.restore();
      return;
    }

    // Vector fallback matching concept identity if sheet not loaded yet.
    final body = RRect.fromRectAndRadius(dst, const Radius.circular(10));
    canvas.drawRRect(
      body,
      Paint()
        ..shader = ui.Gradient.linear(
          dst.topCenter,
          dst.bottomCenter,
          [
            _char.accent.withValues(alpha: 0.95 * alpha),
            const Color(0xFF1A1030).withValues(alpha: alpha),
          ],
        ),
    );
    canvas.drawRRect(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = _char.accent.withValues(alpha: 0.9 * alpha),
    );
    canvas.drawRect(
      Rect.fromLTWH(dst.left + 10, dst.top + 14, dst.width - 20, 10),
      Paint()..color = _char.accent.withValues(alpha: 0.9 * alpha),
    );
  }

  void _paintEnemies(Canvas canvas, Size size) {
    for (final e in sim.enemies) {
      if (e.dead && e.ai != EnemyAiState.death) continue;
      final y = _sy(e.y + e.height);
      final dst = Rect.fromLTWH(e.x - 8, y - 10, e.width + 16, e.height + 16);
      final sheet = EnemyAssetBundle.enemySheet(e.def.id);
      final animLike = switch (e.anim) {
        EnemyAnim.idle => EnemyAnimLike.idle,
        EnemyAnim.move => EnemyAnimLike.move,
        EnemyAnim.attack => EnemyAnimLike.attack,
        EnemyAnim.hit => EnemyAnimLike.hit,
        EnemyAnim.death => EnemyAnimLike.death,
        EnemyAnim.ranged => EnemyAnimLike.ranged,
        EnemyAnim.special => EnemyAnimLike.special,
        EnemyAnim.fly => EnemyAnimLike.fly,
      };
      final frame = (e.animTime * 8).floor() % EnemySpriteAtlas.cols;
      final flash = e.hitFlash > 0;

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(e.x + e.width / 2, groundY + 5),
          width: e.width * 0.85,
          height: 10,
        ),
        Paint()..color = Colors.black.withValues(alpha: 0.4),
      );

      if (e.telegraph > 0) {
        canvas.drawCircle(
          Offset(e.x + e.width / 2, y + e.height * 0.3),
          18 + (1 - e.telegraph) * 10,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = e.def.accent.withValues(alpha: 0.7),
        );
      }

      if (sheet != null) {
        final src = EnemySpriteAtlas.srcRect(animLike, frame);
        final paint = Paint()..filterQuality = FilterQuality.medium;
        if (flash) {
          paint.colorFilter =
              const ColorFilter.mode(Colors.white, BlendMode.srcATop);
        }
        // Sprites face right; enemies approach from the right so face the player (left).
        final cx = dst.center.dx;
        canvas.save();
        canvas.translate(cx, 0);
        canvas.scale(-1, 1);
        canvas.translate(-cx, 0);
        canvas.drawImageRect(sheet, src, dst, paint);
        canvas.restore();
      } else {
        // Distinct left-facing silhouette fallback.
        final path = Path()
          ..moveTo(e.x + e.width * 0.5, y)
          ..lineTo(e.x, y + e.height * 0.35)
          ..lineTo(e.x + e.width * 0.15, y + e.height)
          ..lineTo(e.x + e.width * 0.85, y + e.height)
          ..lineTo(e.x + e.width, y + e.height * 0.35)
          ..close();
        canvas.drawPath(
          path,
          Paint()
            ..color =
                flash ? Colors.white : e.def.accent.withValues(alpha: 0.9),
        );
      }

      if (e.shieldUp && e.shieldHp > 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(dst.inflate(4), const Radius.circular(8)),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5
            ..color = e.def.accent.withValues(alpha: 0.75)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
      }

      if (e.marked) {
        canvas.drawCircle(
          Offset(e.x + e.width / 2, y - 10),
          6,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = CharacterCatalog.hunterOrange,
        );
      }

      if (e.maxHp > 1 && !e.isBoss) {
        final pct = (e.hp / e.maxHp).clamp(0.0, 1.0);
        canvas.drawRect(
          Rect.fromLTWH(e.x, y - 8, e.width, 4),
          Paint()..color = Colors.black54,
        );
        canvas.drawRect(
          Rect.fromLTWH(e.x, y - 8, e.width * pct, 4),
          Paint()..color = e.def.accent,
        );
      }
    }
  }

  void _paintHazards(Canvas canvas, Size size) {
    for (final h in sim.hazards) {
      if (h.consumed) continue;
      final y = _sy(h.y + h.height);
      final key = h.active ? h.assetKey : '${h.assetKey}_idle';
      final img =
          EnemyAssetBundle.hazard(key) ?? EnemyAssetBundle.hazard(h.assetKey);
      final dst = Rect.fromLTWH(h.x, y, h.width, h.height);
      if (h.telegraph > 0 && !h.active) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(dst, const Radius.circular(4)),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = AppColors.gold.withValues(alpha: 0.8),
        );
      }
      if (img != null) {
        paintImage(
          canvas: canvas,
          rect: dst.inflate(4),
          image: img,
          fit: BoxFit.contain,
          opacity: h.active ? 1 : 0.55,
        );
      } else {
        final paint = Paint()
          ..color = (h.requiresJump ? AppColors.ember : AppColors.neonCyan)
              .withValues(alpha: 0.85);
        if (h.kind == HazardKind.spike || h.requiresJump) {
          final path = Path()
            ..moveTo(h.x, y + h.height)
            ..lineTo(h.x + h.width / 2, y)
            ..lineTo(h.x + h.width, y + h.height)
            ..close();
          canvas.drawPath(path, paint);
        } else {
          canvas.drawRRect(
            RRect.fromRectAndRadius(dst, const Radius.circular(4)),
            paint,
          );
        }
      }
    }
  }

  void _paintProjectiles(Canvas canvas, Size size) {
    for (final p in sim.projectiles) {
      if (p.dead) continue;
      final y = _sy(p.y);
      final color = Color(p.colorValue);
      final key = p.assetKey ??
          switch (p.kind) {
            ProjectileKind.voidWave ||
            ProjectileKind.energyWave =>
              'energy_wave',
            ProjectileKind.plasma || ProjectileKind.rain => 'plasma',
            ProjectileKind.missile => 'missile',
            ProjectileKind.laser => 'laser',
            ProjectileKind.rift => 'rift',
            ProjectileKind.electric => 'electric',
            ProjectileKind.explosive => 'explosive',
            ProjectileKind.bullet || ProjectileKind.standard => 'bullet',
          };
      final img = EnemyAssetBundle.projectile(key) ??
          CharacterAssetBundle.image('assets/vfx/hunter_projectile.png');
      final w = p.kind == ProjectileKind.voidWave ||
              p.kind == ProjectileKind.energyWave
          ? 64.0
          : p.kind == ProjectileKind.missile
              ? 40.0
              : 28.0;
      final h = w * 0.55;
      final dst = Rect.fromCenter(center: Offset(p.x, y), width: w, height: h);
      if (img != null) {
        canvas.save();
        if (!p.fromPlayer) {
          canvas.translate(p.x, y);
          canvas.scale(-1, 1);
          canvas.translate(-p.x, -y);
        }
        paintImage(canvas: canvas, rect: dst, image: img, fit: BoxFit.contain);
        canvas.restore();
      } else {
        canvas.drawCircle(
          Offset(p.x, y),
          RunnerConfig.rangedRadius,
          Paint()
            ..color = color
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
      }
      canvas.drawLine(
        Offset(p.x + (p.fromPlayer ? -22 : 22), y),
        Offset(p.x, y),
        Paint()
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..color = color.withValues(alpha: 0.45),
      );
    }
  }

  void _paintParticles(Canvas canvas, Size size) {
    for (final p in sim.particles) {
      final y = _sy(p.y);
      final key = p.vfxKey;
      if (key != null) {
        final img = CharacterAssetBundle.image('assets/vfx/$key.png');
        if (img != null) {
          final s = p.size * 2.2;
          paintImage(
            canvas: canvas,
            rect: Rect.fromCenter(center: Offset(p.x, y), width: s, height: s),
            image: img,
            fit: BoxFit.contain,
            opacity: (p.life * 2).clamp(0, 1),
          );
          continue;
        }
      }
      canvas.drawCircle(
        Offset(p.x, y),
        p.size,
        Paint()
          ..color =
              Color(p.colorValue).withValues(alpha: (p.life * 2).clamp(0, 1)),
      );
    }
  }

  void _paintFloatingText(Canvas canvas, Size size) {
    for (final t in sim.floatingTexts) {
      final y = _sy(t.y);
      final tp = TextPainter(
        text: TextSpan(
          text: t.text,
          style: TextStyle(
            color: t.critical ? AppColors.gold : Colors.white,
            fontSize: t.critical ? 16 : 14,
            fontWeight: FontWeight.w800,
            shadows: const [Shadow(blurRadius: 6, color: Colors.black)],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(t.x - tp.width / 2, y));
    }
  }

  void _paintVignette(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(size.width / 2, size.height / 2),
        size.width * 0.75,
        [
          Colors.transparent,
          Colors.black.withValues(alpha: 0.55),
        ],
      );
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant RunnerWorldPainter oldDelegate) => true;
}
