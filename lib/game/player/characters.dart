import 'package:flutter/material.dart';

import '../player/player.dart';

enum CharacterAbilityId {
  shadowDash,
  markTarget,
  heavySlash,
  phase,
}

enum CharacterUltimateId {
  phantomStrike,
  rainOfLight,
  voidCleave,
  timeFracture,
}

/// Full playable character definition — stats, kits, and asset paths.
class CharacterDefinition {
  const CharacterDefinition({
    required this.id,
    required this.name,
    required this.codename,
    required this.tagline,
    required this.role,
    required this.unlockCostCoins,
    required this.baseStats,
    required this.accent,
    required this.accentSecondary,
    required this.abilityId,
    required this.abilityName,
    required this.abilityDescription,
    required this.ultimateId,
    required this.ultimateName,
    required this.ultimateDescription,
    required this.meleeMul,
    required this.rangedMul,
    required this.abilityCooldown,
    required this.ultimateChargeKills,
    this.armorMul = 1,
  });

  final String id;
  final String name;
  final String codename;
  final String tagline;
  final String role;
  final int unlockCostCoins;
  final PlayerStats baseStats;
  final Color accent;
  final Color accentSecondary;
  final CharacterAbilityId abilityId;
  final String abilityName;
  final String abilityDescription;
  final CharacterUltimateId ultimateId;
  final String ultimateName;
  final String ultimateDescription;
  final double meleeMul;
  final double rangedMul;
  final double abilityCooldown;
  final int ultimateChargeKills;
  final double armorMul;

  String get spritesheet => 'assets/characters/$id/spritesheet.png';
  String get portrait => 'assets/characters/$id/portrait.png';
  String get portraitArt => 'assets/characters/$id/portrait_art.png';
  String get weapon => 'assets/weapons/${id}_weapon.png';
  String get weaponArt => 'assets/weapons/${id}_weapon_art.png';

  String animFrame(String anim) => 'assets/characters/$id/$anim.png';
}

class CharacterCatalog {
  CharacterCatalog._();

  static const Color runnerCyan = Color(0xFF00E5FF);
  static const Color hunterOrange = Color(0xFFFFB703);
  static const Color bladeRed = Color(0xFFFF3B3B);
  static const Color phantomPurple = Color(0xFF7B2CFF);
  static const Color brandMetal = Color(0xFFA7B0C0);
  static const Color brandBg = Color(0xFF0A0E17);

  static final CharacterDefinition runner = CharacterDefinition(
    id: 'runner',
    name: 'The Runner',
    codename: 'RUNNER',
    tagline: 'Balanced starter',
    role: 'Balanced',
    unlockCostCoins: 0,
    accent: runnerCyan,
    accentSecondary: const Color(0xFF2EE6D6),
    abilityId: CharacterAbilityId.shadowDash,
    abilityName: 'SHADOW DASH',
    abilityDescription: 'Dash through foes with i-frames and slash damage.',
    ultimateId: CharacterUltimateId.phantomStrike,
    ultimateName: 'PHANTOM STRIKE',
    ultimateDescription: 'A multi-hit phantom dash that shreds a lane.',
    meleeMul: 1.0,
    rangedMul: 1.0,
    abilityCooldown: 6,
    ultimateChargeKills: 8,
    baseStats: const PlayerStats(
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
    ),
  );

  static final CharacterDefinition hunter = CharacterDefinition(
    id: 'hunter',
    name: 'The Hunter',
    codename: 'HUNTER',
    tagline: 'Ranged specialist',
    role: 'Ranged',
    unlockCostCoins: 300,
    accent: hunterOrange,
    accentSecondary: const Color(0xFFFF8C00),
    abilityId: CharacterAbilityId.markTarget,
    abilityName: 'MARK TARGET',
    abilityDescription: 'Mark foes — marked targets take bonus ranged damage.',
    ultimateId: CharacterUltimateId.rainOfLight,
    ultimateName: 'RAIN OF LIGHT',
    ultimateDescription: 'Call down a barrage of plasma bolts ahead.',
    meleeMul: 0.7,
    rangedMul: 1.55,
    abilityCooldown: 7,
    ultimateChargeKills: 9,
    baseStats: const PlayerStats(
      id: 'player_local',
      characterId: 'hunter',
      health: 2,
      maxHealth: 2,
      damage: 0.95,
      speed: 1.12,
      attackSpeed: 1.2,
      criticalChance: 0.12,
      criticalDamage: 1.7,
      armor: 0,
      coinMultiplier: 1,
      xpMultiplier: 1,
    ),
  );

  static final CharacterDefinition blade = CharacterDefinition(
    id: 'blade',
    name: 'The Blade',
    codename: 'BLADE',
    tagline: 'Heavy melee specialist',
    role: 'Melee',
    unlockCostCoins: 450,
    accent: bladeRed,
    accentSecondary: const Color(0xFFC81E28),
    abilityId: CharacterAbilityId.heavySlash,
    abilityName: 'HEAVY SLASH',
    abilityDescription: 'A crushing wide slash with massive knockback.',
    ultimateId: CharacterUltimateId.voidCleave,
    ultimateName: 'VOID CLEAVE',
    ultimateDescription: 'Unleash a void energy wave that cleaves the street.',
    meleeMul: 1.65,
    rangedMul: 0.55,
    abilityCooldown: 7.5,
    ultimateChargeKills: 7,
    armorMul: 1.25,
    baseStats: const PlayerStats(
      id: 'player_local',
      characterId: 'blade',
      health: 5,
      maxHealth: 5,
      damage: 1.35,
      speed: 0.78,
      attackSpeed: 0.85,
      criticalChance: 0.06,
      criticalDamage: 1.8,
      armor: 0.15,
      coinMultiplier: 1,
      xpMultiplier: 1,
    ),
  );

  static final CharacterDefinition phantom = CharacterDefinition(
    id: 'phantom',
    name: 'The Phantom',
    codename: 'PHANTOM',
    tagline: 'Fast assassin — high skill',
    role: 'Assassin',
    unlockCostCoins: 600,
    accent: phantomPurple,
    accentSecondary: const Color(0xFFB45AFF),
    abilityId: CharacterAbilityId.phase,
    abilityName: 'PHASE',
    abilityDescription: 'Phase out — brief invulnerability and speed surge.',
    ultimateId: CharacterUltimateId.timeFracture,
    ultimateName: 'TIME FRACTURE',
    ultimateDescription:
        'Fracture time — slow enemies and amplify all your damage.',
    meleeMul: 1.35,
    rangedMul: 0.9,
    abilityCooldown: 5.5,
    ultimateChargeKills: 10,
    baseStats: const PlayerStats(
      id: 'player_local',
      characterId: 'phantom',
      health: 2,
      maxHealth: 2,
      damage: 1.15,
      speed: 1.42,
      attackSpeed: 1.25,
      criticalChance: 0.14,
      criticalDamage: 1.9,
      armor: 0,
      coinMultiplier: 1.05,
      xpMultiplier: 1.05,
    ),
  );

  static List<CharacterDefinition> get all => [runner, hunter, blade, phantom];

  static CharacterDefinition byId(String id) {
    final normalized = _migrateId(id);
    return all.firstWhere((c) => c.id == normalized, orElse: () => runner);
  }

  /// Map legacy character ids from older builds.
  static String _migrateId(String id) {
    return switch (id) {
      'shadow' || 'ninja' => 'runner',
      'demon' => 'blade',
      _ => id,
    };
  }

  static String migrateSelectedId(String id) => _migrateId(id);
}
