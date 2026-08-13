import 'dart:ui' as ui;

import 'package:flutter/services.dart';

import '../player/characters.dart';

/// Loads character sprite sheets + VFX images once for painters.
class CharacterAssetBundle {
  CharacterAssetBundle._();

  static final Map<String, ui.Image> _images = {};
  static bool _loading = false;
  static Future<void>? _ready;

  static Future<void> ensureLoaded() {
    return _ready ??= _loadAll();
  }

  static ui.Image? image(String path) => _images[path];

  static Future<void> _loadAll() async {
    if (_loading) return;
    _loading = true;
    final paths = <String>{
      'assets/branding/shadow_run_logo.png',
      'assets/branding/shadow_run_wordmark.png',
      'assets/branding/shadow_run_symbol.png',
      'assets/branding/shadow_run_app_icon.png',
      'assets/branding/logo_wordmark.png',
      'assets/branding/symbol.png',
      'assets/branding/logo_transparent.png',
      'assets/branding/app_icon.png',
    };
    for (final c in CharacterCatalog.all) {
      paths.add(c.spritesheet);
      paths.add(c.portrait);
      paths.add(c.portraitArt);
      paths.add(c.weapon);
      paths.add(c.weaponArt);
      for (final anim in CharacterSpriteAtlas.anims) {
        paths.add(c.animFrame(anim));
      }
    }
    const vfx = [
      'runner_slash',
      'runner_dash',
      'runner_afterimage',
      'hunter_muzzle',
      'hunter_projectile',
      'hunter_mark',
      'hunter_impact',
      'blade_slash',
      'blade_wave',
      'blade_impact',
      'phantom_phase',
      'phantom_particles',
      'phantom_fracture',
    ];
    for (final v in vfx) {
      paths.add('assets/vfx/$v.png');
    }

    await Future.wait(paths.map(_loadOne));
  }

  static Future<void> _loadOne(String path) async {
    try {
      final data = await rootBundle.load(path);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      _images[path] = frame.image;
    } catch (_) {
      // Missing optional art variants are fine (portrait_art / logo_transparent).
    }
  }
}

/// Sprite-sheet layout produced by tool/generate_game_assets.py
class CharacterSpriteAtlas {
  CharacterSpriteAtlas._();

  static const int frameW = 96;
  static const int frameH = 128;
  static const int cols = 6;

  static const List<String> anims = [
    'idle',
    'run',
    'jump',
    'fall',
    'land',
    'slide',
    'dodge',
    'melee',
    'ranged',
    'hit',
    'death',
    'ability',
    'ultimate',
  ];

  static int rowFor(String anim) {
    final i = anims.indexOf(anim);
    return i < 0 ? 1 : i;
  }

  static ui.Rect srcRect(String anim, int frame) {
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
