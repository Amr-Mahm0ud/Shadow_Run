class UpgradeDefinition {
  const UpgradeDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.maxLevel,
    required this.baseCost,
    required this.costGrowth,
  });

  final String id;
  final String name;
  final String description;
  final int maxLevel;
  final int baseCost;
  final double costGrowth;

  int costForLevel(int currentLevel) {
    return (baseCost * (costGrowth * (currentLevel + 1))).round();
  }
}

class UpgradeCatalog {
  UpgradeCatalog._();

  static const List<UpgradeDefinition> all = [
    UpgradeDefinition(
      id: 'damage',
      name: 'Damage',
      description: '+8% melee & ranged damage per level',
      maxLevel: 10,
      baseCost: 40,
      costGrowth: 1.35,
    ),
    UpgradeDefinition(
      id: 'health',
      name: 'Health',
      description: '+1 max HP per level',
      maxLevel: 5,
      baseCost: 60,
      costGrowth: 1.5,
    ),
    UpgradeDefinition(
      id: 'speed',
      name: 'Speed',
      description: '+5% move speed & jump per level',
      maxLevel: 10,
      baseCost: 45,
      costGrowth: 1.3,
    ),
    UpgradeDefinition(
      id: 'attack_speed',
      name: 'Attack Speed',
      description: '+5% melee swing speed per level',
      maxLevel: 10,
      baseCost: 50,
      costGrowth: 1.35,
    ),
    UpgradeDefinition(
      id: 'crit_chance',
      name: 'Critical Chance',
      description: '+2% crit chance per level',
      maxLevel: 10,
      baseCost: 55,
      costGrowth: 1.4,
    ),
    UpgradeDefinition(
      id: 'crit_damage',
      name: 'Critical Damage',
      description: '+10% crit multiplier per level',
      maxLevel: 10,
      baseCost: 55,
      costGrowth: 1.4,
    ),
    UpgradeDefinition(
      id: 'coin_mul',
      name: 'Coin Multiplier',
      description: '+8% coins from kills per level',
      maxLevel: 10,
      baseCost: 70,
      costGrowth: 1.45,
    ),
    UpgradeDefinition(
      id: 'ranged_reload',
      name: 'Ranged Reload',
      description: '+8% plasma reload speed per level',
      maxLevel: 5,
      baseCost: 65,
      costGrowth: 1.4,
    ),
    UpgradeDefinition(
      id: 'xp_mul',
      name: 'XP Multiplier',
      description: '+8% XP from kills per level',
      maxLevel: 10,
      baseCost: 70,
      costGrowth: 1.45,
    ),
  ];
}
