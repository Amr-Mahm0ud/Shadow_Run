import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

import '../../data/repositories/settings_repository.dart';
import '../../game/runner/runner_entities.dart';
import '../service_locator.dart';

/// Centralized audio + haptics for SHADOW//RUN.
///
/// Categories: MASTER / MUSIC / SFX / UI with pooling and concurrency limits.
/// BGM is a single looping player for the whole app; gameplay only ducks volume.
class FeedbackService {
  FeedbackService();

  static const _musicAsset = 'shadow_run_main_theme.mp3';
  static const _poolSize = 6;

  /// Menu uses the settings music volume; a run ducks to ~10% of that.
  static const double gameplayMusicScale = 0.10;

  final List<AudioPlayer> _sfxPool = [];
  final Map<String, int> _activeByAsset = {};
  AudioPlayer? _music;
  StreamSubscription<void>? _musicCompleteSub;
  Future<void> _musicOp = Future<void>.value();
  int _poolIndex = 0;
  int _gameplayRef = 0;
  bool _musicPaused = false;
  bool _sfxUnavailable = false;
  bool _musicUnavailable = false;
  bool _audioContextReady = false;
  bool _inGameplay = false;
  String? _characterId;

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

  /// SFX must mix with BGM — default audio focus (`gain`) pauses the music player.
  AudioContext _mixContext({required bool music}) {
    return AudioContext(
      android: AudioContextAndroid(
        contentType: music
            ? AndroidContentType.music
            : AndroidContentType.sonification,
        usageType: AndroidUsageType.game,
        audioFocus: AndroidAudioFocus.none,
      ),
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.playback,
        options: const {AVAudioSessionOptions.mixWithOthers},
      ),
    );
  }

  void setCharacterProfile(String? characterId) => _characterId = characterId;

  Future<void> _runMusic(Future<void> Function() op) {
    final run = _musicOp.then((_) => op());
    _musicOp = run.catchError((_) {});
    return run;
  }

  Future<void> _ensureAudioContext() async {
    if (_audioContextReady) return;
    try {
      await AudioPlayer.global.setAudioContext(_mixContext(music: true));
      _audioContextReady = true;
    } catch (_) {}
  }

  Future<void> _ensureSfxPool() async {
    if (_sfxUnavailable || _sfxPool.isNotEmpty) return;
    try {
      await _ensureAudioContext();
      for (var i = 0; i < _poolSize; i++) {
        final p = AudioPlayer();
        await p.setPlayerMode(PlayerMode.lowLatency);
        try {
          await p.setAudioContext(_mixContext(music: false));
        } catch (_) {}
        _sfxPool.add(p);
      }
    } catch (_) {
      _sfxUnavailable = true;
    }
  }

  Future<AudioPlayer?> _musicPlayer() async {
    if (_musicUnavailable) return null;
    if (_music != null) return _music;
    try {
      await _ensureAudioContext();
      final player = AudioPlayer();
      try {
        await player.setAudioContext(_mixContext(music: true));
      } catch (_) {}
      await player.setReleaseMode(ReleaseMode.loop);
      await player.setVolume(_musicVol);
      _musicCompleteSub?.cancel();
      _musicCompleteSub = player.onPlayerComplete.listen((_) {
        if (musicEnabled && !_musicPaused) {
          unawaited(startMusic());
        }
      });
      _music = player;
      return player;
    } catch (_) {
      _musicUnavailable = true;
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

  Future<void> applyVolumes() {
    return _runMusic(() async {
      try {
        await _music?.setVolume(_musicVol);
      } catch (_) {}
    });
  }

  /// Duck BGM while a run screen is alive; restore menu volume when the last
  /// run screen is gone. Never restarts the track — volume only.
  Future<void> setGameplayMusic(bool active) async {
    if (active) {
      _gameplayRef++;
    } else if (_gameplayRef > 0) {
      _gameplayRef--;
    }
    _inGameplay = _gameplayRef > 0;
    await applyVolumes();
    if (musicEnabled) {
      await startMusic();
    }
  }

  Future<void> syncMusic() async {
    await applyVolumes();
    if (musicEnabled) {
      await startMusic();
    } else {
      await stopMusic();
    }
  }

  Future<void> startMusic() {
    return _runMusic(_startMusicUnlocked);
  }

  Future<void> _startMusicUnlocked() async {
    if (!musicEnabled) return;
    var player = await _musicPlayer();
    if (player == null) return;
    try {
      if (player.state == PlayerState.disposed) {
        await _musicCompleteSub?.cancel();
        _musicCompleteSub = null;
        _music = null;
        player = await _musicPlayer();
        if (player == null) return;
      }
      await player.setVolume(_musicVol);
      switch (player.state) {
        case PlayerState.playing:
          _musicPaused = false;
          return;
        case PlayerState.paused:
          await player.resume();
          _musicPaused = false;
          return;
        case PlayerState.stopped:
        case PlayerState.completed:
        case PlayerState.disposed:
          break;
      }
      await player.setReleaseMode(ReleaseMode.loop);
      await player.play(AssetSource('audio/$_musicAsset'));
      _musicPaused = false;
    } catch (_) {}
  }

  Future<void> pauseMusic() {
    return _runMusic(() async {
      try {
        if (_music != null && _music!.state == PlayerState.playing) {
          await _music!.pause();
          _musicPaused = true;
        }
      } catch (_) {}
    });
  }

  Future<void> resumeMusic() async {
    if (!musicEnabled) return;
    await startMusic();
  }

  Future<void> stopMusic() {
    return _runMusic(() async {
      try {
        await _music?.stop();
      } catch (_) {}
      _musicPaused = false;
    });
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
  }

  Future<void> resumeCue() async {
    if (!uiEnabled) return;
    await _playAsset('resume.wav', categoryVolume: _uiVol, gain: 1.0);
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
    await _musicCompleteSub?.cancel();
    _musicCompleteSub = null;
    await stopMusic();
    for (final p in _sfxPool) {
      await p.dispose();
    }
    _sfxPool.clear();
    await _music?.dispose();
    _music = null;
  }
}
