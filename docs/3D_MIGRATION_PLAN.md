# Shadow Run — 3D Migration Plan

**Date:** 2026-08-11  
**Depends on:** `docs/3D_ENGINE_DECISION.md` (Unity URP primary)  
**Product targets:** Production Transform Master Plan + 3D Action Survival Transform Master Plan

---

## 1. Goal

Move Shadow Run from a Flutter 2D arcade prototype to a **stylized 3D mobile action-survival roguelite** without throwing away useful product design, economy, or progression ideas.

**Shipping client:** Unity (URP)  
**Flutter repo role:** Design reference + temporary playable prototype until vertical slice replaces it

---

## 2. Non-negotiable rules

1. Do not build all systems at once.
2. Do not fake implementation.
3. Do not enable ads/IAP before the Fun Test passes.
4. One vertical slice must feel like a real game before content expansion.
5. Prefer small commits / milestones.
6. Preserve offline-first runs.
7. Keep economy and content data-driven.

---

## 3. What migrates vs what dies

### Port (concept → Unity data/systems)

- Character trio: Shadow / Ninja / Demon
- Coins, gems, XP, level curve, upgrade costs
- Power-up identities (expand into rarity + synergies later)
- Missions / high-score / settings preferences
- Analytics event vocabulary
- Feature-flag philosophy and monetization order
- Reward-on-death philosophy

### Rewrite (must be new)

- Rendering, camera, lighting, animation
- Movement (virtual joystick)
- Combat (no permanent ATTACK button)
- Physics, hitboxes, dodge
- Enemy AI / wave director / bosses
- Environments (Shadow Forest first)
- Audio / VFX pipelines

### Defer

- 3D hub world
- Seasons, live ops backend
- Multiplayer / clans / chat
- Full five biomes
- Large inventory / dozens of characters

---

## 4. Repository strategy

### Phase A — Docs + freeze expectations (current)

- Keep Flutter project as-is for reference playable build.
- All new 3D work tracked in docs first, then Unity project.

### Phase B — Add Unity project

Recommended layout (same GitHub repo, monorepo):

```
/
  docs/                 # already exists — source of truth for plans
  flutter_legacy/       # optional rename of current Flutter app later
  unity/ShadowRun/      # Unity project (URP)
  README.md             # points to active client
```

Until Unity exists, keep current `lib/` paths; rename only when it reduces confusion.

### Phase C — Cut over

1. Unity vertical slice playable on device.
2. Fun Test checklist passes.
3. Meta progression parity for MVP fields.
4. Store identifiers finalized.
5. Flutter gameplay marked archived in README.

Do **not** maintain two live gameplay clients after cutover.

---

## 5. Vertical slice definition (gate)

Must include before expanding content:

- [ ] One 3D biome chunk: **Shadow Forest**
- [ ] One playable character: **Shadow**
- [ ] One weapon: **Shadow Blade**
- [ ] Three enemy types (e.g. Shade / Wisp / Brute behaviors)
- [ ] One elite modifier
- [ ] One mini-boss
- [ ] Gravity + collision + knockback basics
- [ ] Dodge with cooldown + i-frames
- [ ] XP + level-up + **3 power-up choices**
- [ ] Basic VFX + SFX
- [ ] Game over + rewards + restart
- [ ] 30+ FPS min on mid device; path to 60 on high

If this is not fun → stop content; fix feel.

---

## 6. Phased delivery (mapped to 3D plan)

| Phase | Name | Exit criteria |
|------:|------|----------------|
| 0 | Repo audit | `INITIAL_AUDIT` updated for 3D |
| 1 | Engine decision | `3D_ENGINE_DECISION.md` accepted |
| 2 | Architecture foundation | Unity project + folders + configs + CI smoke |
| 3 | 3D rendering prototype | Player capsule/mesh, ground, light, camera, 1 enemy |
| 4 | Player controller | Joystick move, rotate, accel/decel, collision |
| 5 | Physics / collision | Layers, casts, no tunneling at normal speeds |
| 6 | Combat foundation | Hitbox/hurtbox, damage, feedback |
| 7 | Enemy AI | 3 behavior types, readable telegraphs |
| 8 | Weapons | Shadow Blade complete; data hooks for more |
| 9 | Dodge / mobility | Cooldown dodge, i-frames, juice |
| 10 | Wave director | Budgeted spawns, intensity curve |
| 11–12 | Power-ups + builds | Choose-3, rarity seed, basic synergies later |
| 13–14 | Elites + boss | Elite mods + 1 mini-boss + 1 major boss path |
| 15 | Semi-procedural runs | Node map + encounter types |
| 16–17 | Loot + meta | Coins/XP/materials; permanent upgrades |
| 18–20 | Characters / mastery / missions | 3 characters; mastery hooks; dailies |
| 21–25 | Biome art / VFX / audio / UI / perf | Shadow Forest polished; quality tiers |
| 26–29 | Analytics / cloud / shop / leaderboard | Behind flags; after fun |
| 30–32 | QA / soft launch / balance | Data-driven tuning |

**Immediate next implementation phase after docs:** Phase 2 → Phase 3 only.

---

## 7. Unity architecture sketch

```
unity/ShadowRun/
  Assets/
    _Game/
      Art/            # characters, env, vfx
      Audio/
      Data/           # ScriptableObjects: enemies, weapons, economy
      Prefabs/
      Scenes/         # Boot, Hub, Run, Bootstraps
      Scripts/
        Core/         # service locator, events, save
        Gameplay/     # player, combat, AI, director
        UI/
        Meta/         # progression, missions
        Services/     # analytics, ads (stubs first)
```

### Core patterns to carry from Flutter

| Flutter idea | Unity equivalent |
|--------------|------------------|
| `GameEngine` UI-free rules | Pure C# simulation / systems where practical |
| `GameConfig` | ScriptableObject + config assets |
| `FeatureFlags` | ScriptableObject / remote config later |
| Repositories | `ISaveService` + local JSON/PlayerPrefs wrapper |
| `AppServices` | Thin service locator or Installer |
| Catalogs (enemy/character/powerup) | ScriptableObject databases |

UI must not own persistence or economy math.

---

## 8. Control scheme (target)

| Side | Action |
|------|--------|
| Left | Virtual joystick movement |
| Right | Contextual attack (tap/hold/swipe by weapon) |
| Right / button | Dodge |
| Optional | Ability button(s) |

Remove permanent full-screen ATTACK CTA as primary combat.

Camera default evaluation order during prototype:

1. **Isometric / high third-person hybrid** (readability first)
2. Classic behind-back third-person if combat framing wins in playtests

Avoid constant yaw rotation that causes motion sickness.

---

## 9. Risk register

| Risk | Mitigation |
|------|------------|
| Scope explosion | Vertical slice gate; content freeze until Fun Test |
| Package size bloat | URP, texture budgets, LODs, addressables later |
| Physics chaos | Dedicated collision layers; gameplay impulses over full ragdoll early |
| Dual-client confusion | Single README “active client”; archive Flutter after cutover |
| Art bottleneck | Capsule/prototype meshes first; replace without rewriting systems |
| Premature monetization | Flags off until retention metrics exist |

---

## 10. Testing strategy (Unity)

- Edit-mode tests: damage formulas, XP curve, upgrade costs, synergy rules
- PlayMode tests: dodge i-frames, spawn budgets, save/load
- Device farm smoke: mid + low Android, one recent iPhone
- Long-run soak: 30–60 min for leaks / FPS decay
- Physics QA checklist from 3D plan §73

---

## 11. Documentation set (create as systems land)

Already required / started:

- [x] `docs/3D_ENGINE_DECISION.md`
- [x] `docs/3D_MIGRATION_PLAN.md` (this file)
- [x] `docs/INITIAL_AUDIT.md` (updated for 3D)
- [x] `docs/IMPLEMENTATION_STATUS.md` (3D phase tracker)

Create when implementing:

- `docs/3D_ARCHITECTURE.md`
- `docs/COMBAT_DESIGN.md`
- `docs/PHYSICS_DESIGN.md`
- `docs/LEVEL_DESIGN.md`
- `docs/BUILD_SYSTEM.md`
- `docs/ART_DIRECTION.md`
- `docs/PERFORMANCE.md`

Keep status file synchronized every milestone.

---

## 12. First implementation tasks (after this doc)

1. Confirm Unity version (LTS) + URP template decision in status file.
2. Create `unity/ShadowRun` project in repo.
3. Boot scene + input system + quality settings stubs.
4. Prototype: ground, directional light, follow camera, player move, one chaser enemy.
5. Measure FPS on a real device before adding VFX.

**Do not** start weapons mastery, seasons, shop, or multi-biome work before the prototype proves movement + camera + basic fight feel.
