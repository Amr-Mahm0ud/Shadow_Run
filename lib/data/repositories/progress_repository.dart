import '../../core/config/game_config.dart';
import '../../core/constants/app_constants.dart';
import '../local/key_value_store.dart';

class PlayerProgress {
  PlayerProgress({
    this.coins = 0,
    this.gems = 0,
    this.xp = 0,
    this.level = 1,
    this.selectedCharacterId = 'runner',
    this.totalKills = 0,
    this.totalRuns = 0,
    this.bestScore = 0,
    this.unlockedCharacterIds = const ['runner'],
    this.upgradeLevels = const {},
  });

  int coins;
  int gems;
  int xp;
  int level;
  String selectedCharacterId;
  int totalKills;
  int totalRuns;
  int bestScore;
  List<String> unlockedCharacterIds;
  Map<String, int> upgradeLevels;

  Map<String, dynamic> toJson() => {
        'coins': coins,
        'gems': gems,
        'xp': xp,
        'level': level,
        'selectedCharacterId': selectedCharacterId,
        'totalKills': totalKills,
        'totalRuns': totalRuns,
        'bestScore': bestScore,
        'unlockedCharacterIds': unlockedCharacterIds,
        'upgradeLevels': upgradeLevels,
      };

  factory PlayerProgress.fromJson(Map<String, dynamic> json) {
    String migrate(String id) {
      return switch (id) {
        'shadow' || 'ninja' => 'runner',
        'demon' => 'blade',
        _ => id,
      };
    }

    final selected = migrate(
      json['selectedCharacterId'] as String? ?? 'runner',
    );
    final unlocked = (json['unlockedCharacterIds'] as List<dynamic>?)
            ?.map((e) => migrate(e.toString()))
            .toSet()
            .toList() ??
        const ['runner'];
    if (!unlocked.contains('runner')) {
      unlocked.insert(0, 'runner');
    }

    return PlayerProgress(
      coins: (json['coins'] as num?)?.toInt() ?? 0,
      gems: (json['gems'] as num?)?.toInt() ?? 0,
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      level: (json['level'] as num?)?.toInt() ?? 1,
      selectedCharacterId: selected,
      totalKills: (json['totalKills'] as num?)?.toInt() ?? 0,
      totalRuns: (json['totalRuns'] as num?)?.toInt() ?? 0,
      bestScore: (json['bestScore'] as num?)?.toInt() ?? 0,
      unlockedCharacterIds: unlocked,
      upgradeLevels: (json['upgradeLevels'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, (v as num).toInt()),
          ) ??
          const {},
    );
  }
}

class ProgressRepository {
  ProgressRepository(this._storage);

  final KeyValueStore _storage;

  PlayerProgress read() {
    final raw = _storage.read<Map<String, dynamic>>(AppConstants.storageProgress);
    if (raw == null) return PlayerProgress();
    return PlayerProgress.fromJson(raw);
  }

  Future<void> save(PlayerProgress progress) async {
    await _storage.write(AppConstants.storageProgress, progress.toJson());
  }

  Future<PlayerProgress> applyRunRewards({
    required int score,
    required int coins,
    required int xp,
    required int kills,
  }) async {
    final progress = read();
    progress.coins += coins;
    progress.xp += xp;
    progress.totalKills += kills;
    progress.totalRuns += 1;
    if (score > progress.bestScore) progress.bestScore = score;

    while (progress.xp >= GameConfig.xpForLevel(progress.level)) {
      progress.xp -= GameConfig.xpForLevel(progress.level);
      progress.level += 1;
    }

    await save(progress);
    return progress;
  }
}
