import 'package:flutter/material.dart';

enum EnemyFaction { omnicorp, malfunction, riftWalkers }

enum EnemyTier { basic, elite, flying, heavy, special, boss }

enum EnemyRole {
  melee,
  fastMelee,
  ranged,
  electric,
  tank,
  flyer,
  eliteShield,
  eliteMelee,
  assassin,
  support,
  caster,
  summoner,
  boss,
}

/// Data-driven enemy identity for the action runner.
class EnemyDefinition {
  const EnemyDefinition({
    required this.id,
    required this.displayName,
    required this.faction,
    required this.tier,
    required this.role,
    required this.health,
    required this.speed,
    required this.damage,
    required this.width,
    required this.height,
    required this.score,
    required this.coins,
    required this.xp,
    required this.accent,
    this.flying = false,
    this.flyHeight = 0,
    this.keepsDistance = false,
    this.preferredRange = 180,
    this.hasShield = false,
    this.blocksRanged = false,
    this.canTeleport = false,
    this.telegraphs = true,
    this.attackCooldown = 1.2,
    this.attackRange = 70,
    this.isBoss = false,
    this.bossPhases = 1,
  });

  final String id;
  final String displayName;
  final EnemyFaction faction;
  final EnemyTier tier;
  final EnemyRole role;
  final double health;
  final double speed;
  final int damage;
  final double width;
  final double height;
  final int score;
  final int coins;
  final int xp;
  final Color accent;
  final bool flying;
  final double flyHeight;
  final bool keepsDistance;
  final double preferredRange;
  final bool hasShield;
  final bool blocksRanged;
  final bool canTeleport;
  final bool telegraphs;
  final double attackCooldown;
  final double attackRange;
  final bool isBoss;
  final int bossPhases;

  String get spritesheet => 'assets/enemies/$id/spritesheet.png';
  String get idle => 'assets/enemies/$id/idle.png';
  String get portrait => 'assets/enemies/$id/portrait.png';
}

class EnemyRoster {
  EnemyRoster._();

  static const Color omnicorp = Color(0xFFFF3B3B);
  static const Color malfunction = Color(0xFF7B2CFF);
  static const Color rift = Color(0xFF00E5FF);

  // —— BASIC ——
  static const grunt = EnemyDefinition(
    id: 'grunt',
    displayName: 'GRUNT',
    faction: EnemyFaction.omnicorp,
    tier: EnemyTier.basic,
    role: EnemyRole.melee,
    health: 2,
    speed: 52,
    damage: 1,
    width: 44,
    height: 66,
    score: 100,
    coins: 3,
    xp: 8,
    accent: omnicorp,
    attackCooldown: 1.1,
  );

  static const raptor = EnemyDefinition(
    id: 'raptor',
    displayName: 'RAPTOR',
    faction: EnemyFaction.omnicorp,
    tier: EnemyTier.basic,
    role: EnemyRole.fastMelee,
    health: 1,
    speed: 110,
    damage: 1,
    width: 40,
    height: 56,
    score: 130,
    coins: 4,
    xp: 10,
    accent: omnicorp,
    attackCooldown: 0.7,
    attackRange: 60,
  );

  static const sentinel = EnemyDefinition(
    id: 'sentinel',
    displayName: 'SENTINEL',
    faction: EnemyFaction.omnicorp,
    tier: EnemyTier.basic,
    role: EnemyRole.ranged,
    health: 2,
    speed: 38,
    damage: 1,
    width: 44,
    height: 64,
    score: 150,
    coins: 5,
    xp: 12,
    accent: omnicorp,
    keepsDistance: true,
    preferredRange: 260,
    attackCooldown: 1.6,
    attackRange: 320,
  );

  static const shocker = EnemyDefinition(
    id: 'shocker',
    displayName: 'SHOCKER',
    faction: EnemyFaction.omnicorp,
    tier: EnemyTier.basic,
    role: EnemyRole.electric,
    health: 2,
    speed: 70,
    damage: 1,
    width: 42,
    height: 62,
    score: 160,
    coins: 5,
    xp: 12,
    accent: Color(0xFF2EE6D6),
    attackCooldown: 1.4,
    attackRange: 90,
  );

  static const guardian = EnemyDefinition(
    id: 'guardian',
    displayName: 'GUARDIAN',
    faction: EnemyFaction.omnicorp,
    tier: EnemyTier.basic,
    role: EnemyRole.tank,
    health: 5,
    speed: 28,
    damage: 1,
    width: 56,
    height: 74,
    score: 200,
    coins: 6,
    xp: 14,
    accent: omnicorp,
    hasShield: true,
    blocksRanged: true,
    attackCooldown: 1.5,
  );

  static const droneSwarmer = EnemyDefinition(
    id: 'drone_swarmer',
    displayName: 'DRONE SWARMER',
    faction: EnemyFaction.omnicorp,
    tier: EnemyTier.basic,
    role: EnemyRole.flyer,
    health: 1,
    speed: 95,
    damage: 1,
    width: 36,
    height: 40,
    score: 140,
    coins: 4,
    xp: 11,
    accent: omnicorp,
    flying: true,
    flyHeight: 70,
    attackCooldown: 1.0,
    attackRange: 55,
  );

  // —— ELITE ——
  static const shieldMaiden = EnemyDefinition(
    id: 'shield_maiden',
    displayName: 'SHIELD MAIDEN',
    faction: EnemyFaction.malfunction,
    tier: EnemyTier.elite,
    role: EnemyRole.eliteShield,
    health: 6,
    speed: 45,
    damage: 1,
    width: 50,
    height: 72,
    score: 280,
    coins: 8,
    xp: 18,
    accent: malfunction,
    hasShield: true,
    blocksRanged: true,
    attackCooldown: 1.3,
  );

  static const executioner = EnemyDefinition(
    id: 'executioner',
    displayName: 'EXECUTIONER',
    faction: EnemyFaction.malfunction,
    tier: EnemyTier.elite,
    role: EnemyRole.eliteMelee,
    health: 7,
    speed: 32,
    damage: 2,
    width: 60,
    height: 84,
    score: 320,
    coins: 10,
    xp: 22,
    accent: malfunction,
    telegraphs: true,
    attackCooldown: 1.8,
    attackRange: 100,
  );

  static const voidStalker = EnemyDefinition(
    id: 'void_stalker',
    displayName: 'VOID STALKER',
    faction: EnemyFaction.malfunction,
    tier: EnemyTier.elite,
    role: EnemyRole.assassin,
    health: 3,
    speed: 100,
    damage: 2,
    width: 42,
    height: 64,
    score: 300,
    coins: 9,
    xp: 20,
    accent: malfunction,
    canTeleport: true,
    attackCooldown: 0.9,
  );

  // —— FLYING ——
  static const scoutDrone = EnemyDefinition(
    id: 'scout_drone',
    displayName: 'SCOUT DRONE',
    faction: EnemyFaction.omnicorp,
    tier: EnemyTier.flying,
    role: EnemyRole.flyer,
    health: 1,
    speed: 120,
    damage: 1,
    width: 40,
    height: 34,
    score: 120,
    coins: 4,
    xp: 10,
    accent: omnicorp,
    flying: true,
    flyHeight: 90,
    attackCooldown: 1.0,
    attackRange: 50,
  );

  static const missileDrone = EnemyDefinition(
    id: 'missile_drone',
    displayName: 'MISSILE DRONE',
    faction: EnemyFaction.omnicorp,
    tier: EnemyTier.flying,
    role: EnemyRole.ranged,
    health: 2,
    speed: 70,
    damage: 1,
    width: 48,
    height: 40,
    score: 180,
    coins: 6,
    xp: 14,
    accent: omnicorp,
    flying: true,
    flyHeight: 110,
    keepsDistance: true,
    preferredRange: 280,
    attackCooldown: 2.0,
    attackRange: 360,
  );

  static const bomberDrone = EnemyDefinition(
    id: 'bomber_drone',
    displayName: 'BOMBER DRONE',
    faction: EnemyFaction.omnicorp,
    tier: EnemyTier.flying,
    role: EnemyRole.ranged,
    health: 3,
    speed: 55,
    damage: 2,
    width: 52,
    height: 44,
    score: 220,
    coins: 7,
    xp: 16,
    accent: Color(0xFFFF8C00),
    flying: true,
    flyHeight: 130,
    attackCooldown: 2.4,
    attackRange: 80,
  );

  static const sniperDrone = EnemyDefinition(
    id: 'sniper_drone',
    displayName: 'SNIPER DRONE',
    faction: EnemyFaction.omnicorp,
    tier: EnemyTier.flying,
    role: EnemyRole.ranged,
    health: 2,
    speed: 50,
    damage: 2,
    width: 46,
    height: 36,
    score: 240,
    coins: 8,
    xp: 16,
    accent: omnicorp,
    flying: true,
    flyHeight: 120,
    keepsDistance: true,
    preferredRange: 360,
    telegraphs: true,
    attackCooldown: 2.8,
    attackRange: 420,
  );

  // —— HEAVY ——
  static const steelBrute = EnemyDefinition(
    id: 'steel_brute',
    displayName: 'STEEL BRUTE',
    faction: EnemyFaction.omnicorp,
    tier: EnemyTier.heavy,
    role: EnemyRole.tank,
    health: 10,
    speed: 24,
    damage: 2,
    width: 72,
    height: 92,
    score: 400,
    coins: 12,
    xp: 28,
    accent: omnicorp,
    telegraphs: true,
    attackCooldown: 1.9,
    attackRange: 110,
  );

  static const warMachine = EnemyDefinition(
    id: 'war_machine',
    displayName: 'WAR MACHINE',
    faction: EnemyFaction.omnicorp,
    tier: EnemyTier.heavy,
    role: EnemyRole.ranged,
    health: 9,
    speed: 30,
    damage: 2,
    width: 80,
    height: 70,
    score: 420,
    coins: 14,
    xp: 30,
    accent: omnicorp,
    keepsDistance: true,
    preferredRange: 240,
    attackCooldown: 1.7,
    attackRange: 300,
  );

  static const fortress = EnemyDefinition(
    id: 'fortress',
    displayName: 'FORTRESS',
    faction: EnemyFaction.omnicorp,
    tier: EnemyTier.heavy,
    role: EnemyRole.tank,
    health: 14,
    speed: 16,
    damage: 2,
    width: 96,
    height: 64,
    score: 500,
    coins: 16,
    xp: 34,
    accent: Color(0xFFFF8C00),
    keepsDistance: true,
    preferredRange: 220,
    attackCooldown: 2.2,
    attackRange: 280,
  );

  // —— SPECIAL ——
  static const chaosEngineer = EnemyDefinition(
    id: 'chaos_engineer',
    displayName: 'CHAOS ENGINEER',
    faction: EnemyFaction.riftWalkers,
    tier: EnemyTier.special,
    role: EnemyRole.support,
    health: 4,
    speed: 48,
    damage: 1,
    width: 48,
    height: 68,
    score: 260,
    coins: 9,
    xp: 18,
    accent: rift,
    keepsDistance: true,
    preferredRange: 300,
    attackCooldown: 2.5,
    attackRange: 200,
  );

  static const riftReaper = EnemyDefinition(
    id: 'rift_reaper',
    displayName: 'RIFT REAPER',
    faction: EnemyFaction.riftWalkers,
    tier: EnemyTier.special,
    role: EnemyRole.caster,
    health: 5,
    speed: 42,
    damage: 2,
    width: 50,
    height: 78,
    score: 340,
    coins: 11,
    xp: 24,
    accent: rift,
    keepsDistance: true,
    preferredRange: 250,
    attackCooldown: 1.8,
    attackRange: 280,
  );

  static const corruptedWraith = EnemyDefinition(
    id: 'corrupted_wraith',
    displayName: 'CORRUPTED WRAITH',
    faction: EnemyFaction.riftWalkers,
    tier: EnemyTier.special,
    role: EnemyRole.summoner,
    health: 4,
    speed: 60,
    damage: 1,
    width: 48,
    height: 70,
    score: 360,
    coins: 12,
    xp: 26,
    accent: rift,
    flying: true,
    flyHeight: 50,
    canTeleport: true,
    attackCooldown: 2.0,
  );

  // —— BOSSES ——
  static const juggernaut = EnemyDefinition(
    id: 'juggernaut',
    displayName: 'THE JUGGERNAUT',
    faction: EnemyFaction.omnicorp,
    tier: EnemyTier.boss,
    role: EnemyRole.boss,
    health: 40,
    speed: 36,
    damage: 2,
    width: 110,
    height: 120,
    score: 2500,
    coins: 80,
    xp: 120,
    accent: omnicorp,
    isBoss: true,
    bossPhases: 3,
    telegraphs: true,
    attackCooldown: 1.4,
    attackRange: 130,
  );

  static const overseer = EnemyDefinition(
    id: 'overseer',
    displayName: 'OVERSEER',
    faction: EnemyFaction.omnicorp,
    tier: EnemyTier.boss,
    role: EnemyRole.boss,
    health: 36,
    speed: 40,
    damage: 2,
    width: 90,
    height: 110,
    score: 2400,
    coins: 75,
    xp: 110,
    accent: omnicorp,
    isBoss: true,
    bossPhases: 3,
    keepsDistance: true,
    preferredRange: 280,
    attackCooldown: 1.2,
    attackRange: 360,
  );

  static const warpBehemoth = EnemyDefinition(
    id: 'warp_behemoth',
    displayName: 'WARP BEHEMOTH',
    faction: EnemyFaction.malfunction,
    tier: EnemyTier.boss,
    role: EnemyRole.boss,
    health: 48,
    speed: 28,
    damage: 2,
    width: 140,
    height: 100,
    score: 2800,
    coins: 90,
    xp: 140,
    accent: malfunction,
    isBoss: true,
    bossPhases: 3,
    attackCooldown: 1.5,
    attackRange: 150,
  );

  static const apexSentinel = EnemyDefinition(
    id: 'apex_sentinel',
    displayName: 'APEX SENTINEL',
    faction: EnemyFaction.omnicorp,
    tier: EnemyTier.boss,
    role: EnemyRole.boss,
    health: 45,
    speed: 34,
    damage: 2,
    width: 120,
    height: 130,
    score: 3000,
    coins: 100,
    xp: 150,
    accent: omnicorp,
    isBoss: true,
    bossPhases: 3,
    hasShield: true,
    blocksRanged: true,
    attackCooldown: 1.3,
    attackRange: 160,
  );

  static List<EnemyDefinition> get all => const [
        grunt,
        raptor,
        sentinel,
        shocker,
        guardian,
        droneSwarmer,
        shieldMaiden,
        executioner,
        voidStalker,
        scoutDrone,
        missileDrone,
        bomberDrone,
        sniperDrone,
        steelBrute,
        warMachine,
        fortress,
        chaosEngineer,
        riftReaper,
        corruptedWraith,
        juggernaut,
        overseer,
        warpBehemoth,
        apexSentinel,
      ];

  static EnemyDefinition byId(String id) =>
      all.firstWhere((e) => e.id == id, orElse: () => grunt);

  static List<EnemyDefinition> get bosses =>
      all.where((e) => e.isBoss).toList();
}
