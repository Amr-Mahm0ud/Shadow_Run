import '../../core/constants/app_constants.dart';
import '../../game/systems/missions.dart';
import '../local/key_value_store.dart';

class MissionProgressState {
  MissionProgressState({
    Map<String, int>? progress,
    Set<String>? claimed,
    this.dailySeed = '',
    this.bestSurviveSeconds = 0,
    this.bestRunCoins = 0,
  })  : progress = progress ?? {},
        claimed = claimed ?? {};

  /// Best progress toward each mission target (lifetime peak for permanent,
  /// current-day peak for daily).
  final Map<String, int> progress;
  final Set<String> claimed;
  String dailySeed;
  int bestSurviveSeconds;
  int bestRunCoins;

  Map<String, dynamic> toJson() => {
        'progress': progress,
        'claimed': claimed.toList(),
        'dailySeed': dailySeed,
        'bestSurviveSeconds': bestSurviveSeconds,
        'bestRunCoins': bestRunCoins,
      };

  factory MissionProgressState.fromJson(Map<String, dynamic> json) {
    return MissionProgressState(
      progress: (json['progress'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, (v as num).toInt()),
          ) ??
          {},
      claimed: (json['claimed'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toSet() ??
          {},
      dailySeed: json['dailySeed'] as String? ?? '',
      bestSurviveSeconds: (json['bestSurviveSeconds'] as num?)?.toInt() ?? 0,
      bestRunCoins: (json['bestRunCoins'] as num?)?.toInt() ?? 0,
    );
  }
}

class MissionRepository {
  MissionRepository(this._storage);

  final KeyValueStore _storage;

  static String daySeed([DateTime? now]) {
    final d = now ?? DateTime.now().toUtc();
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  MissionProgressState read({DateTime? now}) {
    final raw =
        _storage.read<Map<String, dynamic>>(AppConstants.storageMissions);
    final state =
        raw == null ? MissionProgressState() : MissionProgressState.fromJson(raw);
    return _ensureDaily(state, now: now);
  }

  MissionProgressState _ensureDaily(MissionProgressState state, {DateTime? now}) {
    final seed = daySeed(now);
    if (state.dailySeed == seed) return state;
    // New UTC day — clear daily progress + claims only.
    final nextProgress = Map<String, int>.from(state.progress);
    final nextClaimed = Set<String>.from(state.claimed);
    for (final m in MissionCatalog.daily) {
      nextProgress.remove(m.id);
      nextClaimed.remove(m.id);
    }
    final refreshed = MissionProgressState(
      progress: nextProgress,
      claimed: nextClaimed,
      dailySeed: seed,
      bestSurviveSeconds: state.bestSurviveSeconds,
      bestRunCoins: state.bestRunCoins,
    );
    // Persist synchronously via fire-and-forget write.
    _storage.write(AppConstants.storageMissions, refreshed.toJson());
    return refreshed;
  }

  Future<void> save(MissionProgressState state) async {
    await _storage.write(AppConstants.storageMissions, state.toJson());
  }

  int progressFor(MissionDefinition mission, MissionProgressState state) {
    return (state.progress[mission.id] ?? 0).clamp(0, mission.target);
  }

  bool isClaimed(MissionDefinition mission, MissionProgressState state) {
    return state.claimed.contains(mission.id);
  }

  bool isComplete(MissionDefinition mission, MissionProgressState state) {
    return progressFor(mission, state) >= mission.target;
  }

  /// Merge a finished run into mission progress. Does not auto-claim.
  Future<MissionProgressState> recordRun({
    required int runKills,
    required int totalKills,
    required int score,
    required int surviveSeconds,
    required int coinsEarned,
    required int playerLevel,
    DateTime? now,
  }) async {
    final state = read(now: now);
    state.bestSurviveSeconds = surviveSeconds > state.bestSurviveSeconds
        ? surviveSeconds
        : state.bestSurviveSeconds;
    state.bestRunCoins =
        coinsEarned > state.bestRunCoins ? coinsEarned : state.bestRunCoins;

    void setMax(String id, int value, int target) {
      final prev = state.progress[id] ?? 0;
      if (value > prev) state.progress[id] = value.clamp(0, target);
    }

    for (final m in [...MissionCatalog.daily, ...MissionCatalog.permanent]) {
      switch (m.type) {
        case MissionType.killEnemies:
          if (m.resetPolicy == MissionResetPolicy.daily) {
            final prev = state.progress[m.id] ?? 0;
            state.progress[m.id] = (prev + runKills).clamp(0, m.target);
          } else {
            setMax(m.id, totalKills, m.target);
          }
        case MissionType.reachScore:
          setMax(m.id, score, m.target);
        case MissionType.surviveSeconds:
          setMax(m.id, surviveSeconds, m.target);
        case MissionType.collectCoins:
          setMax(m.id, coinsEarned, m.target);
        case MissionType.reachLevel:
          setMax(m.id, playerLevel, m.target);
      }
    }

    await save(state);
    return state;
  }

  /// Claim reward. Returns coins/xp/gems granted, or null if not claimable.
  Future<({int coins, int xp, int gems})?> claim(
    MissionDefinition mission, {
    DateTime? now,
  }) async {
    final state = read(now: now);
    if (isClaimed(mission, state) || !isComplete(mission, state)) return null;
    state.claimed.add(mission.id);
    await save(state);
    final gems = mission.resetPolicy == MissionResetPolicy.daily ? 1 : 3;
    return (coins: mission.rewardCoins, xp: mission.rewardXp, gems: gems);
  }
}
