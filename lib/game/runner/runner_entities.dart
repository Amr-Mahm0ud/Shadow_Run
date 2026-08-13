import '../enemies/enemy_roster.dart';
import 'runner_config.dart';

enum RunnerInput {
  jump,
  slide,
  dodgeLeft,
  dodgeRight,
  melee,
  ranged,
  ability,
  ultimate,
}

/// Audio cues emitted by the simulation (UI plays them).
enum RunnerSfx {
  jump,
  slide,
  dodge,
  footstep,
  meleeMiss,
  meleeHit,
  ranged,
  reload,
  ability,
  ultimate,
  enemyHit,
  enemySpawn,
  enemyKill,
  playerHit,
  block,
  bossWarning,
  pickup,
}

enum RunnerPhase { countdown, playing, paused, levelUp, dead, reward }

enum PlayerAnim {
  idle,
  run,
  jump,
  fall,
  land,
  slide,
  dodge,
  melee1,
  melee2,
  melee3,
  ranged,
  hit,
  dead,
  ability,
  ultimate,
}

/// Legacy kind kept for older tests — prefer [EnemyDefinition.id].
enum EnemyKind { melee, fast, ranged, heavy }

enum EnemyAiState {
  idle,
  spawning,
  approach,
  attack,
  cooldown,
  hit,
  stun,
  special,
  death,
}

enum EnemyAnim {
  idle,
  move,
  attack,
  hit,
  death,
  ranged,
  special,
  fly,
}

enum ProjectileKind {
  standard,
  plasma,
  voidWave,
  rain,
  bullet,
  electric,
  missile,
  laser,
  rift,
  energyWave,
  explosive,
}

enum HazardKind {
  spike,
  laserBar,
  laserTurret,
  electricFloor,
  fallingDebris,
  explosiveBarrel,
}

class RunnerRect {
  RunnerRect(this.x, this.y, this.w, this.h);
  double x;
  double y;
  double w;
  double h;

  bool overlaps(RunnerRect o) {
    return x < o.x + o.w && x + w > o.x && y < o.y + o.h && y + h > o.y;
  }
}

class RunnerPlayer {
  double y = RunnerConfig.groundY;
  double vy = 0;
  double xOffset = 0;
  bool onGround = true;
  bool sliding = false;
  bool dodging = false;
  bool invulnerable = false;
  PlayerAnim anim = PlayerAnim.run;
  int health = RunnerConfig.startingHealth;
  int maxHealth = RunnerConfig.startingHealth;
  int comboStep = 0;
  double meleeTimer = 0;
  double comboTimer = 0;
  double slideTimer = 0;
  double dodgeTimer = 0;
  double dodgeCooldown = 0;
  double invulnTimer = 0;
  int rangedCharges = RunnerConfig.rangedMaxCharges;
  int rangedMaxCharges = RunnerConfig.rangedMaxCharges;
  double rangedReloadTimer = 0;
  double hitStopTimer = 0;
  double meleeDamage = 1;
  double rangedDamage = RunnerConfig.rangedDamage;
  double critChance = 0.08;
  double critMult = 1.6;
  double moveSpeedMul = 1;
  double jumpMul = 1;
  double reloadMul = 1;
  double meleeSpeedMul = 1;
  double coinMultiplier = 1;
  double xpMultiplier = 1;
  int dodgeDir = 1;
  String characterId = 'runner';
  double meleeMul = 1;
  double rangedMul = 1;
  double armorMul = 1;
  double abilityCooldown = 0;
  double abilityCooldownMax = 6;
  double abilityTimer = 0;
  double ultimateCharge = 0;
  double ultimateChargeMax = 8;
  double ultimateTimer = 0;
  bool markActive = false;
  double markTimer = 0;
  bool timeFractureActive = false;
  double timeFractureTimer = 0;
  double landTimer = 0;
  double animTime = 0;
  double disruptTimer = 0; // shocker slows jump/dodge briefly

  double get height =>
      sliding ? RunnerConfig.slideHeight : RunnerConfig.playerHeight;

  bool get abilityReady => abilityCooldown <= 0 && abilityTimer <= 0;
  bool get ultimateReady =>
      ultimateCharge >= ultimateChargeMax && ultimateTimer <= 0;

  RunnerRect hitbox(double worldX) => RunnerRect(
        worldX + xOffset,
        y,
        RunnerConfig.playerWidth,
        height,
      );
}

class RunnerEnemy {
  RunnerEnemy({
    required this.id,
    required this.x,
    required this.y,
    EnemyDefinition? def,
    EnemyKind? kind,
    double? hp,
    double? maxHp,
    double? speed,
    int? damage,
    double? width,
    double? height,
    this.score = 100,
    this.coins = 3,
    this.xp = 8,
  })  : def = def ?? _defFromKind(kind ?? EnemyKind.melee),
        kind = kind ?? _legacyKind(def ?? _defFromKind(EnemyKind.melee)) {
    final d = this.def;
    this.hp = hp ?? d.health;
    this.maxHp = maxHp ?? d.health;
    this.speed = speed ?? d.speed;
    this.damage = damage ?? d.damage;
    this.width = width ?? d.width;
    this.height = height ?? d.height;
    if (score == 100 && def != null) score = d.score;
    if (coins == 3 && def != null) coins = d.coins;
    if (xp == 8 && def != null) xp = d.xp;
    shieldHp = d.hasShield ? this.maxHp * 0.45 : 0;
    maxShieldHp = shieldHp;
  }

  static EnemyDefinition _defFromKind(EnemyKind kind) => switch (kind) {
        EnemyKind.fast => EnemyRoster.raptor,
        EnemyKind.ranged => EnemyRoster.sentinel,
        EnemyKind.heavy => EnemyRoster.steelBrute,
        EnemyKind.melee => EnemyRoster.grunt,
      };

  static EnemyKind _legacyKind(EnemyDefinition d) {
    if (d.role == EnemyRole.fastMelee || d.role == EnemyRole.assassin) {
      return EnemyKind.fast;
    }
    if (d.role == EnemyRole.ranged || d.keepsDistance) return EnemyKind.ranged;
    if (d.tier == EnemyTier.heavy || d.role == EnemyRole.tank) {
      return EnemyKind.heavy;
    }
    return EnemyKind.melee;
  }

  final String id;
  final EnemyDefinition def;
  EnemyKind kind;
  double x;
  double y;
  late double hp;
  late double maxHp;
  late double speed;
  late int damage;
  late double width;
  late double height;
  int score;
  int coins;
  int xp;
  bool dead = false;
  double hitFlash = 0;
  bool marked = false;
  double markTimer = 0;
  double slowMul = 1;

  EnemyAiState ai = EnemyAiState.spawning;
  EnemyAnim anim = EnemyAnim.idle;
  double animTime = 0;
  double stateTimer = 0.35;
  double attackCd = 0;
  double telegraph = 0;
  double shieldHp = 0;
  double maxShieldHp = 0;
  bool shieldUp = false;
  int bossPhase = 1;
  double bobPhase = 0;

  bool get isBoss => def.isBoss;
  bool get flying => def.flying;
  bool get blocksRanged => def.blocksRanged && shieldUp && shieldHp > 0;

  RunnerRect get hitbox => RunnerRect(x, y, width, height);
}

class RunnerProjectile {
  RunnerProjectile({
    required this.x,
    required this.y,
    required this.vx,
    required this.damage,
    required this.critical,
    this.vy = 0,
    this.kind = ProjectileKind.standard,
    this.colorValue = 0xFF00E5FF,
    this.fromPlayer = true,
    this.assetKey,
    this.homing = false,
  });

  double x;
  double y;
  double vx;
  double vy;
  double damage;
  bool critical;
  ProjectileKind kind;
  int colorValue;
  bool fromPlayer;
  String? assetKey;
  bool homing;
  bool dead = false;
  double life = 2.5;
}

class RunnerHazard {
  RunnerHazard({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.requiresSlide = false,
    this.requiresJump = false,
    this.kind = HazardKind.spike,
    this.damage = 1,
    this.telegraph = 0,
    this.active = true,
  });

  double x;
  double y;
  double width;
  double height;
  bool requiresSlide;
  bool requiresJump;
  HazardKind kind;
  int damage;
  double telegraph;
  bool active;
  bool consumed = false;
  double life = 8;
  double animTime = 0;

  String get assetKey => switch (kind) {
        HazardKind.spike => 'spike_trap',
        HazardKind.laserBar => 'laser_turret',
        HazardKind.laserTurret => 'laser_turret',
        HazardKind.electricFloor => 'electric_floor',
        HazardKind.fallingDebris => 'falling_debris',
        HazardKind.explosiveBarrel => 'explosive_barrel',
      };

  RunnerRect get hitbox => RunnerRect(x, y, width, height);
}

class RunnerParticle {
  RunnerParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.life,
    required this.colorValue,
    this.size = 3,
    this.vfxKey,
  });

  double x;
  double y;
  double vx;
  double vy;
  double life;
  int colorValue;
  double size;
  String? vfxKey;
}

class RunnerFloatingText {
  RunnerFloatingText({
    required this.x,
    required this.y,
    required this.text,
    required this.critical,
  });

  double x;
  double y;
  String text;
  bool critical;
  double life = 0.7;
}

class RunnerStats {
  int score = 0;
  int coins = 0;
  int xp = 0;
  int kills = 0;
  int bestCombo = 0;
  int combo = 0;
  double comboTimer = 0;
  double distance = 0;
  double survived = 0;
  double multiplier = 1;
  int bossesDefeated = 0;
}

class ActiveBoss {
  ActiveBoss(this.enemy);
  final RunnerEnemy enemy;
  String get name => enemy.def.displayName;
  double get hpPct => (enemy.hp / enemy.maxHp).clamp(0.0, 1.0);
  int get phase => enemy.bossPhase;
}
