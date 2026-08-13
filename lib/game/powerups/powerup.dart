enum PowerUpId {
  damage,
  attackSpeed,
  moveSpeed,
  maxHp,
  shield,
  criticalHit,
  coinMagnet,
  xpBoost,
  lifeSteal,
  slowMotion,
}

class PowerUpDefinition {
  const PowerUpDefinition({
    required this.id,
    required this.title,
    required this.description,
  });

  final PowerUpId id;
  final String title;
  final String description;
}

class PowerUpCatalog {
  PowerUpCatalog._();

  static const List<PowerUpDefinition> all = [
    PowerUpDefinition(
      id: PowerUpId.damage,
      title: 'Shadow Edge',
      description: '+25% damage',
    ),
    PowerUpDefinition(
      id: PowerUpId.attackSpeed,
      title: 'Quick Strike',
      description: '+15% attack speed',
    ),
    PowerUpDefinition(
      id: PowerUpId.moveSpeed,
      title: 'Shadow Step',
      description: '+15% move speed',
    ),
    PowerUpDefinition(
      id: PowerUpId.maxHp,
      title: 'Iron Will',
      description: '+1 max HP',
    ),
    PowerUpDefinition(
      id: PowerUpId.shield,
      title: 'Night Veil',
      description: 'Block one hit',
    ),
    PowerUpDefinition(
      id: PowerUpId.criticalHit,
      title: 'Fatal Focus',
      description: '+8% crit chance',
    ),
    PowerUpDefinition(
      id: PowerUpId.coinMagnet,
      title: 'Gilded Shadow',
      description: '+25% coins',
    ),
    PowerUpDefinition(
      id: PowerUpId.xpBoost,
      title: 'Ancient Lore',
      description: '+25% XP',
    ),
    PowerUpDefinition(
      id: PowerUpId.lifeSteal,
      title: 'Vampiric Cut',
      description: 'Chance to restore HP',
    ),
    PowerUpDefinition(
      id: PowerUpId.slowMotion,
      title: 'Time Fracture',
      description: 'Slow enemies briefly',
    ),
  ];

  static List<PowerUpDefinition> randomChoices(int count, {int? seed}) {
    final pool = List<PowerUpDefinition>.from(all)..shuffle();
    return pool.take(count).toList();
  }
}
