/// Typed analytics facade. No PII. Real backend wired in Phase 14.
class AnalyticsService {
  Future<void> logAppOpen() => _log('APP_OPEN');
  Future<void> logGameStarted({required String characterId}) =>
      _log('GAME_STARTED', {'character_id': characterId});
  Future<void> logGameEnded({
    required int score,
    required int durationMs,
    required int enemies,
  }) =>
      _log('GAME_ENDED', {
        'score': score,
        'run_duration': durationMs,
        'enemy_type_count': enemies,
      });
  Future<void> logPlayerDied({required int score}) =>
      _log('PLAYER_DIED', {'score': score});
  Future<void> logPowerUpSelected({required String powerUpId}) =>
      _log('POWERUP_SELECTED', {'powerup_id': powerUpId});
  Future<void> logLevelUp({required int level}) =>
      _log('LEVEL_UP', {'player_level': level});

  Future<void> _log(String name, [Map<String, Object>? params]) async {
    // Development adapter: no-op sink. Replace with Firebase/etc. when configured.
    assert(() {
      // ignore: avoid_print
      print('[analytics] $name ${params ?? {}}');
      return true;
    }());
  }
}
