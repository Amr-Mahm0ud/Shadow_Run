# Shadow Run — 3D Engine Decision

**Date:** 2026-08-11  
**Status:** Decision recorded (implementation not started)  
**Inputs:** Production Transform Master Plan + 3D Action Survival Transform Master Plan  
**Repo audited:** https://github.com/Amr-Mahm0ud/Shadow_Run (local workspace)

---

## 1. Current architecture (fact)

| Area | Reality today |
|------|----------------|
| Stack | Flutter **3.32.5** / Dart **3.8.1** |
| Game engine | **None** (no Flame, no custom game engine) |
| Rendering | Widget tree + `Image.asset` sprites |
| Game loop | `AnimationController` + `SlideTransition` for one enemy path |
| Collision | X-offset windows (`hitMinX` / `hitMaxX`), not physics bodies |
| Input | Large permanent **ATTACK** button + no free movement |
| Physics | None |
| Lighting / fog / shadows | None (flat `Colors.amber` sky) |
| 3D meshes / skeletal anim | None |
| Flame / flame_3d | Not present |
| Dependencies | `flutter`, `cupertino_icons`, `get_storage`, `google_fonts` |

Gameplay is a **2D landscape arcade prototype**: one hero sprite, one sliding enemy, score/lives, choose-3 power-ups every 5 kills, repository-backed meta progress.

Relevant structure:

```
lib/
  features/gameplay/gameplay_screen.dart   # UI + timers + sprites (~800 LOC)
  game/engine/game_engine.dart             # UI-free rules (phases, collision, rewards)
  game/player|enemies|powerups|systems/    # Data-driven catalogs
  data/repositories/                       # High scores, progress, settings
  services/                                # Analytics/crash facades (dev adapters)
```

**Verdict on current stack:** It cannot deliver the 3D plan’s required rendering, physics, animation, lighting, camera, or mobile performance profile. Forcing 3D into widgets/`CustomPainter` (or experimental Flutter GPU paths) would produce a fragile tech demo, not a commercial game.

---

## 2. Product requirements that drive the decision

Must support on Android + iOS at commercial quality:

1. Stylized dark-fantasy **3D** environments (Shadow Forest first)
2. Third-person / isometric **camera** with smoothing, framing, configurable shake
3. **Physics** used for gameplay (knockback, projectiles, explosives, hazards)
4. **Skeletal animation** for characters/enemies (idle/run/attack/dodge/hit/death)
5. Hitbox/hurtbox combat, dodge i-frames, telegraphs, boss phases
6. Particles / lighting / fog / readable VFX at **~60 FPS** on capable devices
7. Quality tiers (LOW / MEDIUM / HIGH)
8. Object pooling, spawn budgets, long-session stability
9. Maintainable data-driven content (weapons, enemies, builds, economy)
10. Offline-first runs + later ads/IAP/leaderboards

Non-goals for engine choice: multiplayer, open world MMO, photorealism.

---

## 3. Options evaluated

### Option A — Keep current Flutter widget architecture

| | |
|--|--|
| **Pros** | Zero migration; preserves existing Dart code; tiny binary |
| **Cons** | No real 3D, physics, skeletal anim, lighting pipeline |
| **Migration cost** | N/A (but product goal fails) |
| **Fit** | Rejected for the 3D product vision |

### Option B — Flutter + Flame (2D) / flame_3d

| | |
|--|--|
| **Pros** | Stays in Dart/Flutter; Flame is excellent for **2D**; team continuity |
| **Cons** | Flame is 2D-first. `flame_3d` is **explicitly experimental**, depends on experimental Flutter GPU/Impeller, warns **do not use for production**, unstable APIs, incomplete tooling for commercial combat/physics/VFX pipelines |
| **Migration cost** | Medium to rewrite gameplay in Flame 2D; **High + high risk** if pursuing flame_3d |
| **Fit** | Acceptable only if product were reframed as polished **2D**. **Rejected** for the stated 3D action-survival target |

### Option C — Godot 4

| | |
|--|--|
| **Pros** | Real 3D renderer; animation; lighting; physics; free/MIT; strong indie workflow; competitive mobile exports; GDScript productivity; smaller typical binaries than Unity |
| **Cons** | Smaller Asset Store / middleware ecosystem than Unity; mobile tooling and ads/IAP plugins less turnkey; team must leave Dart for gameplay |
| **Migration cost** | High (full client rewrite) but clean architecture possible |
| **Fit** | **Strong** — viable production engine for stylized 3D mobile |

### Option D — Unity (URP)

| | |
|--|--|
| **Pros** | Mature mobile 3D pipeline; Animator + Mecanim; PhysX; URP lighting/shadows/fog; particle systems; proven action-survival genre examples; Asset Store for vertical-slice speed; mature ads/IAP/analytics SDKs; profiler + quality settings |
| **Cons** | Larger APK/IPA risk if unmanaged; C# learning curve; licensing/runtime fee awareness required; editor/project weight |
| **Migration cost** | High (full client rewrite) |
| **Fit** | **Best commercial match** for the ambition in the 3D master plan |

### Option E — Unreal Engine

| | |
|--|--|
| **Pros** | Top-tier graphics |
| **Cons** | Mobile package size and workflow overkill for stylized low/mid poly action roguelite |
| **Fit** | Rejected |

### Option F — Hybrid Flutter hub + embedded Unity/Godot view

| | |
|--|--|
| **Pros** | Reuses Flutter menus/progress UI |
| **Cons** | Complex native embedding, dual lifecycles, dual build pipelines, higher crash surface; delays fun vertical slice |
| **Fit** | Rejected for v1 (reconsider only after core 3D loop is fun) |

---

## 4. Comparison matrix

| Criterion | Flutter widgets | Flame / flame_3d | Godot 4 | Unity URP |
|-----------|-----------------|------------------|---------|-----------|
| Mobile 3D rendering | Poor | Experimental | Good | Excellent |
| Physics gameplay | None | Limited / DIY | Good | Excellent |
| Skeletal animation | None | Immature in 3D | Good | Excellent |
| Lighting / fog / shadows | None | Immature | Good | Excellent |
| Asset pipeline | Sprites only | Weak for 3D prod | Good | Excellent |
| Dev productivity (3D games) | Poor | Poor (3D) | High | High |
| APK/IPA size control | Best | Good | Better | Needs discipline |
| Ads/IAP/analytics ecosystem | Flutter plugins | Flutter plugins | Adequate | Excellent |
| Long-term scalability for this genre | No | No (3D) | Yes | Yes |
| Risk to ship date | Product miss | High | Medium | Medium |

---

## 5. Final recommendation

### Primary engine: **Unity 6 / Unity LTS with Universal Render Pipeline (URP)**

Build the **entire game client** (gameplay + hub UI) in Unity.

### Secondary / fallback: **Godot 4**

Choose Godot instead only if the team explicitly prioritizes MIT licensing, lighter tooling, and is willing to accept a smaller middleware/ecosystem for ads/IAP/assets.

### Do **not** use

- Current Flutter widget gameplay stack for the 3D product
- `flame_3d` for production
- Flutter↔Unity hybrid embedding for the first vertical slice

---

## 6. Why Unity (reason for decision)

1. The 3D plan requires production-grade mesh rendering, lighting, skeletal animation, physics interactions, particles, camera systems, and mobile quality tiers — all mature in Unity URP.
2. `flame_3d`’s own documentation forbids production use; that alone disqualifies “stay on Flutter” for true 3D.
3. Genre execution speed (enemies, VFX, controllers, pooling) is faster with Unity’s existing tooling and Asset Store placeholders while art is finalized.
4. Commercial mobile concerns (ads, IAP, crash SDKs, device profiling) have battle-tested Unity paths.
5. Stylized (not photoreal) art keeps package size manageable with URP + LODs + quality tiers.

Godot remains a legitimate peer; Unity wins on **commercial delivery risk** for this specific scope.

---

## 7. What to preserve from the Flutter project

Preserve as **product/design assets and portable specs**, not as the runtime renderer:

| Keep / port | Why |
|-------------|-----|
| Brand: Shadow Run | Product identity |
| Characters: Shadow / Ninja / Demon (stats + fantasy) | Matches 3D plan |
| Power-up catalog ideas | Seed for roguelite builds |
| Upgrade economy model + `GameConfig` numbers | Centralized balancing |
| Missions / high scores / settings concepts | Retention |
| `GamePhase` reward flow philosophy | Loop clarity |
| Feature-flag / monetization order | Fun before ads |
| Analytics event naming intent | Measurement |
| Repository-style save boundaries | Architecture hygiene |
| Docs + tests as historical reference | Continuity |

| Replace | Why |
|---------|-----|
| `GameplayScreen` sprite loop | Not 3D / not free-move combat |
| Permanent ATTACK button as primary combat | Explicitly banned by 3D plan |
| X-offset collision | Not a combat physics model |
| Prototype PNGs as final character art | Replace with 3D + anim |
| 12MB `background.gif` | Wrong medium; size liability |

---

## 8. Migration cost (honest)

| Workstream | Estimate |
|------------|----------|
| Unity project bootstrap + URP + input + quality settings | Small |
| 3D vertical slice (player, ground, camera, 1 enemy, lighting) | Medium |
| Combat + dodge + weapons + AI + director | Large |
| Roguelite builds + meta progression port | Medium |
| Full biomes / bosses / polish / store | Large |
| Dual-maintaining Flutter gameplay long-term | **Avoid** |

**Strategy:** Treat the Flutter app as the **living product prototype + design source of truth** until the Unity vertical slice passes the Fun Test. Then freeze Flutter gameplay and ship from Unity. Keep this git history; do not delete useful Flutter meta/UI code until equivalents exist.

---

## 9. Decision lock

| Field | Value |
|-------|-------|
| Decision | **Migrate 3D gameplay client to Unity (URP)** |
| Alternative | Godot 4 if licensing/tooling preference overrides |
| Flutter role after migration | Reference prototype + portable design/economy specs |
| Next document | `docs/3D_MIGRATION_PLAN.md` |
| Coding of full game | **Blocked** until migration plan + status tracker updated |

This decision may be revisited only with new evidence (e.g. flame_3d becoming production-stable with physics/animation parity). Until then, do not invest in Flutter 3D prototypes as the shipping path.
