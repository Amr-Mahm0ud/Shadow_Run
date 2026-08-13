enum HeroStatus { run, attack, die }

enum EnemyStatus { run, die }

class PlayerStats {
  const PlayerStats({
    required this.id,
    required this.characterId,
    required this.health,
    required this.maxHealth,
    required this.damage,
    required this.speed,
    required this.attackSpeed,
    required this.criticalChance,
    required this.criticalDamage,
    required this.armor,
    required this.coinMultiplier,
    required this.xpMultiplier,
    this.reloadSpeed,
  });

  final String id;
  final String characterId;
  final int health;
  final int maxHealth;
  final double damage;
  final double speed;
  final double attackSpeed;
  final double criticalChance;
  final double criticalDamage;
  final double armor;
  final double coinMultiplier;
  final double xpMultiplier;
  /// Defaults to [attackSpeed] when null.
  final double? reloadSpeed;

  double get effectiveReloadSpeed => reloadSpeed ?? attackSpeed;

  PlayerStats copyWith({
    String? id,
    String? characterId,
    int? health,
    int? maxHealth,
    double? damage,
    double? speed,
    double? attackSpeed,
    double? criticalChance,
    double? criticalDamage,
    double? armor,
    double? coinMultiplier,
    double? xpMultiplier,
    double? reloadSpeed,
  }) {
    return PlayerStats(
      id: id ?? this.id,
      characterId: characterId ?? this.characterId,
      health: health ?? this.health,
      maxHealth: maxHealth ?? this.maxHealth,
      damage: damage ?? this.damage,
      speed: speed ?? this.speed,
      attackSpeed: attackSpeed ?? this.attackSpeed,
      criticalChance: criticalChance ?? this.criticalChance,
      criticalDamage: criticalDamage ?? this.criticalDamage,
      armor: armor ?? this.armor,
      coinMultiplier: coinMultiplier ?? this.coinMultiplier,
      xpMultiplier: xpMultiplier ?? this.xpMultiplier,
      reloadSpeed: reloadSpeed ?? this.reloadSpeed,
    );
  }

  static PlayerStats starterShadow() => starterRunner();

  static PlayerStats starterRunner() {
    return const PlayerStats(
      id: 'player_local',
      characterId: 'runner',
      health: 3,
      maxHealth: 3,
      damage: 1,
      speed: 1,
      attackSpeed: 1,
      criticalChance: 0.08,
      criticalDamage: 1.55,
      armor: 0,
      coinMultiplier: 1,
      xpMultiplier: 1,
    );
  }
}

class PlayerActor {
  PlayerActor({PlayerStats? stats})
      : stats = stats ?? PlayerStats.starterShadow(),
        status = HeroStatus.run;

  PlayerStats stats;
  HeroStatus status;

  int get lives => stats.health;

  final List<String> runImages = const [
    'assets/images/run1.png',
    'assets/images/run4.png',
    'assets/images/run2.png',
    'assets/images/run3.png',
  ];
  final String jumpImage = 'assets/images/jump.png';
  final String attackImage = 'assets/images/attack.png';
  final List<String> dieImages = const [
    'assets/images/die1.png',
    'assets/images/die2.png',
    'assets/images/die3.png',
  ];

  void attack() => status = HeroStatus.attack;

  void run() => status = HeroStatus.run;

  /// Returns true if the player died (no lives left).
  bool takeHit() {
    if (status == HeroStatus.attack) return false;
    final next = (stats.health - 1).clamp(0, stats.maxHealth);
    stats = stats.copyWith(health: next);
    status = HeroStatus.die;
    return next == 0;
  }
}
