import 'dart:ui' as ui;

import 'package:flutter/services.dart';

import '../enemies/enemy_roster.dart';

/// Loads enemy / projectile / hazard images once for painters.
class EnemyAssetBundle {
  EnemyAssetBundle._();

  static final Map<String, ui.Image> _images = {};
  static Future<void>? _ready;

  static Future<void> ensureLoaded() => _ready ??= _loadAll();

  static ui.Image? image(String path) => _images[path];

  static ui.Image? enemySheet(String id) =>
      _images['assets/enemies/$id/spritesheet.png'];

  static ui.Image? projectile(String key) =>
      _images['assets/projectiles/$key.png'];

  static ui.Image? hazard(String key) => _images['assets/hazards/$key.png'];

  static Future<void> _loadAll() async {
    final paths = <String>{};
    for (final e in EnemyRoster.all) {
      paths.add(e.spritesheet);
      paths.add(e.idle);
      paths.add(e.portrait);
    }
    const projectiles = [
      'bullet',
      'plasma',
      'electric',
      'missile',
      'laser',
      'rift',
      'energy_wave',
      'explosive',
    ];
    for (final p in projectiles) {
      paths.add('assets/projectiles/$p.png');
    }
    const hazards = [
      'laser_turret',
      'laser_turret_idle',
      'spike_trap',
      'spike_trap_idle',
      'electric_floor',
      'electric_floor_idle',
      'falling_debris',
      'falling_debris_idle',
      'explosive_barrel',
      'explosive_barrel_idle',
    ];
    for (final h in hazards) {
      paths.add('assets/hazards/$h.png');
    }
    await Future.wait(paths.map(_loadOne));
  }

  static Future<void> _loadOne(String path) async {
    try {
      final data = await rootBundle.load(path);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      _images[path] = frame.image;
    } catch (_) {}
  }
}

class EnemySpriteAtlas {
  EnemySpriteAtlas._();

  static const int frameW = 96;
  static const int frameH = 128;
  static const int cols = 4;

  static const List<String> anims = [
    'idle',
    'move',
    'attack',
    'hit',
    'death',
    'ranged',
    'special',
    'fly',
  ];

  static int rowFor(EnemyAnimLike anim) {
    return switch (anim) {
      EnemyAnimLike.idle => 0,
      EnemyAnimLike.move => 1,
      EnemyAnimLike.attack => 2,
      EnemyAnimLike.hit => 3,
      EnemyAnimLike.death => 4,
      EnemyAnimLike.ranged => 5,
      EnemyAnimLike.special => 6,
      EnemyAnimLike.fly => 7,
    };
  }

  static ui.Rect srcRect(EnemyAnimLike anim, int frame) {
    final col = frame.clamp(0, cols - 1);
    final row = rowFor(anim);
    return ui.Rect.fromLTWH(
      col * frameW.toDouble(),
      row * frameH.toDouble(),
      frameW.toDouble(),
      frameH.toDouble(),
    );
  }
}

enum EnemyAnimLike { idle, move, attack, hit, death, ranged, special, fly }
