import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

import '../../data/repositories/settings_repository.dart';
import '../../game/runner/runner_entities.dart';
import '../service_locator.dart';

/// Centralized audio + haptics for SHADOW//RUN.
///
/// Categories: MASTER / MUSIC / SFX / UI with pooling and concurrency limits.
class FeedbackService {
  FeedbackService();

  static const _musicAsset = 'shadow_run_main_theme.mp3';
  static const _poolSize = 6;

  final List<AudioPlayer> _sfxPool = [];
  final Map<String, int> _activeByAsset = {};
  AudioPlayer? _music;
  int _poolIndex = 0;
  bool _musicStarted = false;
  bool _musicPaused = false;
  bool _audioUnavailable = false;
  bool _inGameplay = false;
  String? _characterId;

  /// Menu/app music is full setting volume; gameplay ducks under combat SFX.
  static const double gameplayMusicScale = 0.55;

  AppSettings get _settings => AppServices.settings.read();

  bool get musicEnabled => !_settings.muteAll && _settings.musicVolume > 0.001;
  bool get sfxEnabled => !_settings.muteAll && _settings.sfxVolume > 0.001;
  bool get uiEnabled => !_settings.muteAll && _settings.uiVolume > 0.001;
  bool get vibrationEnabled => _settings.vibrationEnabled;

  double get _master => _settings.muteAll ? 0 : _settings.masterVolume.clamp(0, 1);
  double get _musicVol {
    final base = _master * _settings.musicVolume.clamp(0, 1);
    return _inGameplay ? base * gameplayMusicScale : base;
  }
  double get _sfxVol => (_master * _settings.sfxVolume.clamp(0, 1));
  double get _uiVol => (_master * _settings.uiVolume.clamp(0, 1));

  void setCharacterProfile(String? characterId) => _characterId = characterId;

  Future<void> _ensureSfxPool() async {
    if (_audioUnavailable || _sfxPool.isNotEmpty) return;
    try {
      for (var i = 0; i < _poolSize; i++) {
        final p = AudioPlayer();
        await p.setPlayerMode(PlayerMode.lowLatency);
        _sfxPool.add(p);
      }
    } catch (_) {
      _audioUnavailable = true;
    }
  }

  Future<AudioPlayer?> _musicPlayer() async {
    if (_audioUnavailable) return null;
    if (_music != null) return _music;
    try {
      final player = AudioPlayer();
      await player.setReleaseMode(ReleaseMode.loop);
      await player.setVolume(_musicVol);
      _music = player;
      return player;
    } catch (_) {
      _audioUnavailable = true;
      return null;
    }
  }

  /// Character pitch/volume flavor without duplicate asset packs.
  ({double rate, double gain}) _characterFlavor(RunnerSfx event) {
    final id = _characterId ?? 'runner';
    var rate = 1.0;
    var gain = 1.0;
    switch (id) {
      case 'hunter':
        rate = 1.06;
        if (event == RunnerSfx.ranged || event == RunnerSfx.reload) gain = 1.08;
      case 'blade':
        rate = 0.92;
        if (event == RunnerSfx.meleeHit || event == RunnerSfx.meleeMiss) {
          gain = 1.15;
        }
      case 'phantom':
        rate = 1.12;
        if (event == RunnerSfx.ability || event == RunnerSfx.dodge) gain = 0.95;
      default: // runner
        rate = 1.03;
    }
    return (rate: rate, gain: gain);
  }

  double _eventGain(RunnerSfx event) {
    return switch (event) {
      RunnerSfx.ultimate => 1.2,
      RunnerSfx.bossWarning => 1.15,
      RunnerSfx.meleeHit => 1.05,
      RunnerSfx.playerHit => 1.05,
      RunnerSfx.enemyKill => 0.95,
      RunnerSfx.footstep => 0.35,
      RunnerSfx.enemySpawn => 0.55,
      RunnerSfx.enemyHit => 0.7,
      RunnerSfx.pickup => 0.75,
      RunnerSfx.meleeMiss => 0.85,
      _ => 1.0,
    };
  }

  int _maxConcurrent(String asset) {
    if (asset.contains('footstep')) return 1;
    if (asset.contains('enemy_hit') || asset.contains('melee_hit')) return 2;
    if (asset.contains('ranged') || asset.contains('spawn')) return 2;
    return 3;
  }

  Future<void> _playAsset(
    String asset, {
    required double categoryVolume,
    double gain = 1,
    double rate = 1,
  }) async {
    if (categoryVolume <= 0.001) return;
    await _ensureSfxPool();
    if (_sfxPool.isEmpty) return;

    final file = asset.startsWith('audio/') ? asset.substring(6) : asset;
    final active = _activeByAsset[file] ?? 0;
    if (active >= _maxConcurrent(file)) return;

    try {
      final player = _sfxPool[_poolIndex % _sfxPool.length];
      _poolIndex++;
      _activeByAsset[file] = active + 1;
      await player.stop();
      await player.setVolume((categoryVolume * gain).clamp(0.0, 1.0));
      try {
        await player.setPlaybackRate(rate.clamp(0.7, 1.35));
      } catch (_) {}
      await player.play(AssetSource('audio/$file'));
      Future<void>.delayed(const Duration(milliseconds: 180), () {
        final n = (_activeByAsset[file] ?? 1) - 1;
        if (n <= 0) {
          _activeByAsset.remove(file);
        } else {
          _activeByAsset[file] = n;
        }
      });
    } catch (_) {
      final n = (_activeByAsset[file] ?? 1) - 1;
      if (n <= 0) {
        _activeByAsset.remove(file);
      } else {
        _activeByAsset[file] = n;
      }
    }
  }

  Future<void> _playSfxFile(
    String file, {
    double gain = 1,
    double rate = 1,
  }) async {
    if (!sfxEnabled) return;
    await _playAsset(file, categoryVolume: _sfxVol, gain: gain, rate: rate);
  }

  Future<void> playRunnerSfx(
    RunnerSfx event, {
    String? characterId,
  }) async {
    if (characterId != null) _characterId = characterId;
    final file = switch (event) {
      RunnerSfx.jump => 'jump.wav',
      RunnerSfx.slide => 'slide.wav',
      RunnerSfx.dodge => 'dodge.wav',
      RunnerSfx.footstep => 'footstep.wav',
      RunnerSfx.meleeMiss => 'melee_swing_air.wav',
      RunnerSfx.meleeHit => 'melee_hit_enemy.wav',
      RunnerSfx.ranged => 'ranged_fire.wav',
      RunnerSfx.reload => 'reload.wav',
      RunnerSfx.ability => 'special_ability.wav',
      RunnerSfx.ultimate => 'ultimate.wav',
      RunnerSfx.enemyHit => 'melee_hit_enemy.wav',
      RunnerSfx.enemySpawn => 'enemy_spawn.wav',
      RunnerSfx.enemyKill => 'enemy_death.wav',
      RunnerSfx.playerHit => 'player_damaged.wav',
      RunnerSfx.block => 'block.wav',
      RunnerSfx.bossWarning => 'boss_warning.wav',
      RunnerSfx.pickup => 'pickup_reward.wav',
    };
    final flavor = _characterFlavor(event);
    final gain = _eventGain(event) * flavor.gain;
    await _playSfxFile(file, gain: gain, rate: flavor.rate);

    if (!vibrationEnabled) return;
    switch (event) {
      case RunnerSfx.enemyHit:
      case RunnerSfx.meleeHit:
      case RunnerSfx.block:
        await HapticFeedback.lightImpact();
      case RunnerSfx.enemyKill:
      case RunnerSfx.ability:
        await HapticFeedback.mediumImpact();
      case RunnerSfx.playerHit:
      case RunnerSfx.ultimate:
      case RunnerSfx.bossWarning:
        await HapticFeedback.heavyImpact();
      default:
        break;
    }
  }

  Future<void> applyVolumes() async {
    try {
      await _music?.setVolume(_musicVol);
    } catch (_) {}
  }

  /// Keep BGM looping app-wide; duck while a run is active.
  Future<void> setGameplayMusic(bool active) async {
    _inGameplay = active;
    await applyVolumes();
    if (musicEnabled) {
      await startMusic();
    }
  }

  Future<void> syncMusic() async {
    await applyVolumes();
    if (musicEnabled) {
      if (_musicPaused) {
        await resumeMusic();
      } else {
        await startMusic();
      }
    } else {
      await stopMusic();
    }
  }

  Future<void> startMusic() async {
    if (!musicEnabled) return;
    final player = await _musicPlayer();
    if (player == null) return;
    try {
      await player.setVolume(_musicVol);
      if (_musicStarted && player.state == PlayerState.playing) return;
      if (_musicStarted && _musicPaused) {
        await player.resume();
        _musicPaused = false;
        return;
      }
      await player.setReleaseMode(ReleaseMode.loop);
      await player.stop();
      await player.play(AssetSource('audio/$_musicAsset'));
      _musicStarted = true;
      _musicPaused = false;
    } catch (_) {
      _musicStarted = false;
    }
  }

  Future<void> pauseMusic() async {
    try {
      if (_music != null && _music!.state == PlayerState.playing) {
        await _music!.pause();
        _musicPaused = true;
      }
    } catch (_) {}
  }

  Future<void> resumeMusic() async {
    if (!musicEnabled) return;
    try {
      final player = await _musicPlayer();
      if (player == null) return;
      await player.setVolume(_musicVol);
      if (_musicStarted && _musicPaused) {
        await player.resume();
        _musicPaused = false;
        return;
      }
      await startMusic();
    } catch (_) {}
  }

  Future<void> stopMusic() async {
    try {
      await _music?.stop();
    } catch (_) {}
    _musicStarted = false;
    _musicPaused = false;
  }

  Future<void> uiTap() async {
    if (!uiEnabled) return;
    await _playAsset('ui_click.wav', categoryVolume: _uiVol, gain: 0.9);
    if (vibrationEnabled) {
      await HapticFeedback.selectionClick();
    }
  }

  Future<void> pauseCue() async {
    if (!uiEnabled) return;
    await _playAsset('pause.wav', categoryVolume: _uiVol, gain: 1.0);
    // Keep BGM playing during pause — music stays app-wide.
  }

  Future<void> resumeCue() async {
    if (!uiEnabled) return;
    await _playAsset('resume.wav', categoryVolume: _uiVol, gain: 1.0);
    await startMusic();
  }

  Future<void> lightImpact() async {
    if (vibrationEnabled) await HapticFeedback.lightImpact();
  }

  Future<void> mediumImpact() async {
    await _playSfxFile('melee_hit_enemy.wav', gain: 0.7);
    if (vibrationEnabled) await HapticFeedback.mediumImpact();
  }

  Future<void> heavyImpact() async {
    await _playSfxFile('player_damaged.wav', gain: 0.85);
    if (vibrationEnabled) await HapticFeedback.heavyImpact();
  }

  Future<void> success() async {
    await _playSfxFile('pickup_reward.wav', gain: 1.0);
    if (vibrationEnabled) await HapticFeedback.mediumImpact();
  }

  /// Stop overlapping SFX when restarting a run.
  Future<void> resetRunAudio() async {
    _activeByAsset.clear();
    for (final p in _sfxPool) {
      try {
        await p.stop();
      } catch (_) {}
    }
  }

  Future<void> dispose() async {
    await stopMusic();
    for (final p in _sfxPool) {
      await p.dispose();
    }
    _sfxPool.clear();
    await _music?.dispose();
    _music = null;
  }
}
