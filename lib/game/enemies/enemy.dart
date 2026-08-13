import '../player/player.dart';

enum EnemyArchetype {
  normal,
  fast,
  tank,
  shooter,
  chaser,
  exploder,
}

class EnemyDefinition {
  const EnemyDefinition({
    required this.id,
    required this.archetype,
    required this.displayName,
    required this.health,
    required this.speedMultiplier,
    required this.damage,
    required this.coinReward,
    required this.xpReward,
    required this.scoreReward,
    required this.imageAsset,
    this.runAssets = const [],
  });

  final String id;
  final EnemyArchetype archetype;
  final String displayName;
  final int health;
  final double speedMultiplier;
  final int damage;
  final int coinReward;
  final int xpReward;
  final int scoreReward;
  final String imageAsset;
  final List<String> runAssets;
}

class EnemyCatalog {
  EnemyCatalog._();

  static const EnemyDefinition normal = EnemyDefinition(
    id: 'normal',
    archetype: EnemyArchetype.normal,
    displayName: 'Shade',
    health: 1,
    speedMultiplier: 1,
    damage: 1,
    coinReward: 3,
    xpReward: 8,
    scoreReward: 5,
    imageAsset: 'assets/images/enemy.png',
    runAssets: [
      'assets/images/enemy_run1.png',
      'assets/images/enemy_run2.png',
      'assets/images/enemy_run3.png',
      'assets/images/enemy_run4.png',
    ],
  );

  static const EnemyDefinition fast = EnemyDefinition(
    id: 'fast',
    archetype: EnemyArchetype.fast,
    displayName: 'Wisp',
    health: 1,
    speedMultiplier: 1.35,
    damage: 1,
    coinReward: 4,
    xpReward: 10,
    scoreReward: 7,
    imageAsset: 'assets/images/enemy1.png',
  );

  static const EnemyDefinition tank = EnemyDefinition(
    id: 'tank',
    archetype: EnemyArchetype.tank,
    displayName: 'Brute',
    health: 3,
    speedMultiplier: 0.75,
    damage: 1,
    coinReward: 8,
    xpReward: 16,
    scoreReward: 12,
    imageAsset: 'assets/images/enemy.png',
  );

  static List<EnemyDefinition> get all => const [normal, fast, tank];

  static EnemyDefinition byId(String id) {
    return all.firstWhere((e) => e.id == id, orElse: () => normal);
  }
}

class EnemyActor {
  EnemyActor({EnemyDefinition? definition})
      : definition = definition ?? EnemyCatalog.normal,
        status = EnemyStatus.run,
        currentHealth = (definition ?? EnemyCatalog.normal).health;

  EnemyDefinition definition;
  EnemyStatus status;
  int currentHealth;

  String get image => definition.imageAsset;

  void takeDamage(double amount) {
    currentHealth -= amount.ceil();
    if (currentHealth <= 0) {
      currentHealth = 0;
      status = EnemyStatus.die;
    }
  }

  void dieFromHero(HeroStatus heroStatus) {
    if (heroStatus == HeroStatus.attack) {
      status = EnemyStatus.die;
      currentHealth = 0;
    }
  }

  void reset([EnemyDefinition? next]) {
    if (next != null) definition = next;
    currentHealth = definition.health;
    status = EnemyStatus.run;
  }
}
