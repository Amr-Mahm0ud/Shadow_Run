enum MissionType {
  killEnemies,
  surviveSeconds,
  reachScore,
  collectCoins,
  reachLevel,
}

enum MissionResetPolicy { never, daily }

class MissionDefinition {
  const MissionDefinition({
    required this.id,
    required this.title,
    required this.type,
    required this.target,
    required this.rewardCoins,
    required this.rewardXp,
    required this.resetPolicy,
  });

  final String id;
  final String title;
  final MissionType type;
  final int target;
  final int rewardCoins;
  final int rewardXp;
  final MissionResetPolicy resetPolicy;
}

class MissionCatalog {
  MissionCatalog._();

  static const List<MissionDefinition> daily = [
    MissionDefinition(
      id: 'daily_kill_50',
      title: 'Defeat 50 enemies',
      type: MissionType.killEnemies,
      target: 50,
      rewardCoins: 40,
      rewardXp: 30,
      resetPolicy: MissionResetPolicy.daily,
    ),
    MissionDefinition(
      id: 'daily_score_1000',
      title: 'Reach score 1,000',
      type: MissionType.reachScore,
      target: 1000,
      rewardCoins: 50,
      rewardXp: 40,
      resetPolicy: MissionResetPolicy.daily,
    ),
    MissionDefinition(
      id: 'daily_survive_90',
      title: 'Survive 90 seconds',
      type: MissionType.surviveSeconds,
      target: 90,
      rewardCoins: 45,
      rewardXp: 35,
      resetPolicy: MissionResetPolicy.daily,
    ),
    MissionDefinition(
      id: 'daily_coins_80',
      title: 'Collect 80 coins in a run',
      type: MissionType.collectCoins,
      target: 80,
      rewardCoins: 35,
      rewardXp: 25,
      resetPolicy: MissionResetPolicy.daily,
    ),
  ];

  static const List<MissionDefinition> permanent = [
    MissionDefinition(
      id: 'perm_kill_1000',
      title: 'Defeat 1,000 enemies',
      type: MissionType.killEnemies,
      target: 1000,
      rewardCoins: 300,
      rewardXp: 200,
      resetPolicy: MissionResetPolicy.never,
    ),
    MissionDefinition(
      id: 'perm_level_10',
      title: 'Reach player level 10',
      type: MissionType.reachLevel,
      target: 10,
      rewardCoins: 200,
      rewardXp: 150,
      resetPolicy: MissionResetPolicy.never,
    ),
  ];
}
