# Shadow Run — Phase 2 Current State Audit

**Date:** 2026-08-11  
**Repo:** https://github.com/Amr-Mahm0ud/Shadow_Run  
**Purpose:** Phase 2 first task — inventory what exists before any 3D transformation  
**Rule:** Do not begin 3D implementation until this audit + engine decision are complete

---

## Executive summary

Shadow Run today is a **Flutter 2D landscape arcade prototype**: widget sprites, one sliding enemy, large permanent ATTACK button, flat amber sky. Meta systems (XP, coins, characters, upgrades, power-up choose-3, repositories) exist and should be **preserved as portable design/data**, not rewritten blindly.

There is **no** Flame, **no** physics engine, **no** 3D, **no** free movement, **no** camera system. Pause is **broken** (soft-lock). Prior docs already recommend **Unity URP** for the shipping 3D client (`docs/3D_ENGINE_DECISION.md`).

**Visual baseline:** flat yellow/amber background, 2D hero + enemy sprites, flat “road,” giant ATTACK button, basic HUD — this is the quality floor to leave behind.

---

## Technology snapshot

| Area | Current reality |
|------|-----------------|
| Framework | Flutter 3.32.5 / Dart 3.8.1 |
| Game engine | None (no Flame) |
| Rendering | Widget `Stack` + `Image.asset` |
| Game loop | `AnimationController` + `Timer`s in `gameplay_screen.dart` |
| Rules | `GameEngine` (UI-free) in `lib/game/engine/` |
| Collision | X-offset windows only |
| Physics | None |
| Camera | None (fixed Align positions) |
| Input | ATTACK button + pause icon |
| Audio | None (settings toggles only) |
| 3D support | None |

---

## Already working

| System | Where | Notes |
|--------|-------|-------|
| App bootstrap | `lib/main.dart` | Landscape lock, GetStorage, `AppServices`, theme |
| Home hub | `lib/features/home/home_screen.dart` | PLAY + menu tiles, progression chips |
| Game phases (core) | `lib/game/engine/game_phase.dart` | countdown → playing → gameOver → reward |
| Run rules engine | `lib/game/engine/game_engine.dart` | pause/resume API, kill rewards, difficulty step |
| Countdown overlay | `gameplay_screen.dart` | 3-2-1 then play |
| Attack → kill / miss → life loss | engine + screen | Prototype feel, but loop works |
| Score / lives HUD | gameplay screen | ValueNotifiers |
| Power-up choose-3 UI | every 5 kills | Several upgrades mutate run stats |
| Characters unlock/select | `characters.dart` + screen | Shadow / Ninja / Demon stats applied at run start |
| Permanent upgrades | `upgrades.dart` + screen | Coin sink; applied in `_buildRunStats` |
| Coins + XP + level persist | `ProgressRepository` | `applyRunRewards` after run |
| High scores top-3 | `HighScoreRepository` | Legacy key migration |
| Settings prefs | `SettingsRepository` | music/sfx/vibration/locale stored |
| Feature flags | `feature_flags.dart` | ads/shop/boss/etc off by default |
| Analytics/crash facades | `lib/services/` | Wired events; **dev print adapters** |
| Central config | `game_config.dart` | Economy / timing / XP curve |
| Unit/widget tests | `test/` | Engine, repos, home smoke |
| Branding | README / theme / home | “Shadow Run” user-facing |

---

## Partially working

| System | Gap |
|--------|-----|
| Player | Stats exist; no free movement; shared sprites for all characters; jump asset unused |
| Enemy catalog | normal/fast/tank data exists; AI is a tween; shooter/chaser/exploder enum unused |
| Tank HP | Def has `health: 3` but `dieFromHero` one-shots |
| Enemy run sprites | Listed in catalog; UI uses static image |
| Power-ups | shield / lifeSteal / slowMotion largely stubbed; many stats barely change feel |
| GamePhase.boss / restarting | Defined; never entered / unused |
| Missions | UI + catalog; no claim, no persistence (`storageMissions` unused); some progress hard-coded 0 |
| Gems | Persist + display; never earned or spent |
| Pause API | `GameEngine.pause/resume` works; **UI soft-locks** (see Broken) |
| Difficulty / waves | Enemy duration shortens; not a 3D wave director |
| Character selection | Affects stats only, not visuals |
| Settings audio toggles | Saved; no audio playback |

---

## Broken

| Issue | Detail | Severity |
|-------|--------|----------|
| **Pause soft-lock** | ~~Full-screen overlay blocked resume~~ **Fixed 2026-08-11**: `PauseMenu` with RESUME / RESTART / SETTINGS / HOME; attack timer cancelled on pause. | Was blocker |
| Pause incomplete | ~~No RESUME / RESTART / SETTINGS / HOME~~ **Fixed** via `lib/features/gameplay/pause_menu.dart` | Was blocker |
| Attack timer while paused | ~~Could expire mid-pause~~ **Fixed** — `_statusResetTimer` cancelled in `_pauseGame` | Was high |
| Tank multi-hit | HP not respected on hero attack path | Medium |
| Missions progress | Survive/coins progress not real | Medium |

### Pause code path (confirmed)

1. Pause icon → `_togglePause()` → `GamePhase.paused` + `_controller.stop()`
2. Stack draws `const _PauseOverlay()` **after** HUD → blocks taps on pause icon
3. Overlay content: only centered `"PAUSED"` text — no buttons
4. Intended resume is the same icon calling `_togglePause` again — **unreachable under overlay**

Required before Phase 2 “done”: Pause → Resume / Restart / Home / Settings→Back→Resume regression suite (§74 of Phase 2 plan).

---

## Needs replacement (for 3D product)

These must not be “slightly prettier 2D” — they are the core of the transform:

| Area | Current | Replace with |
|------|---------|--------------|
| Rendering | Widget sprites + flat sky | Real 3D scene (meshes, lighting, fog) |
| Player visual | 2D PNG cycle | Rigged 3D character + anims |
| Enemy visual | 2D PNG | 3D enemies + telegraphs |
| Environment | Amber color + white road bar | Shadow Forest 3D arena |
| Movement | Stationary hero | Joystick 3D controller |
| Combat UX | Giant ATTACK button | Contextual mobile combat + dodge |
| Collision | X-offset hack | Hitbox / hurtbox / physics layers |
| Camera | Fixed Align | Follow / framing / shake |
| Enemy motion | `SlideTransition` L←R | Nav/AI in X/Y/Z |
| HUD | Prototype overlay | Minimal 3D-friendly HUD |
| Audio | None | SFX + music layers |

---

## Needs migration (keep intent, new runtime)

Port **concepts and numbers**, not Flutter widgets:

| Flutter source | Migrate to 3D client as |
|----------------|-------------------------|
| `GameConfig` | Central balance config / ScriptableObjects |
| `GamePhase` reward loop | Explicit run state machine |
| `PlayerStats` / characters | Character definitions |
| `EnemyCatalog` | Enemy definitions + archetypes |
| `PowerUpCatalog` | Run upgrade pool (extend rarity later) |
| `UpgradeCatalog` | Meta upgrade tree |
| `MissionCatalog` | Missions (finish claim/persist) |
| `ProgressRepository` fields | Save schema |
| `FeatureFlags` | Gating ads/shop/boss |
| Analytics event names | Same vocabulary |
| Monetization order | Fun → retention → ads |

Do **not** invent parallel `NewPlayerSystem` duplicates — evolve these catalogs into the 3D architecture.

---

## Can be preserved (as-is for now)

| Item | Reason |
|------|--------|
| Flutter repo + git history | Reference prototype + design source |
| `lib/data/*` repository pattern | Architecture to mirror |
| `lib/core/config/*` | Portable balance + flags |
| Home / Characters / Upgrades / Missions / Settings / High Scores screens | Usable until Unity hub exists |
| Tests for engine/repos | Specs for ported formulas |
| Store ID caution (`com.example.*`) | Don’t break future updates |
| Docs already written | `3D_ENGINE_DECISION`, `3D_MIGRATION_PLAN`, audits |

Preserve Flutter meta UI until Unity meta parity exists — then archive Flutter gameplay.

---

## Missing (not started)

- Weapons system
- Dodge
- Free movement / jump evaluation
- Boss encounters
- Achievements
- Daily rewards (flag off)
- Shop / IAP / ads (flags off)
- Cloud save / leaderboard (flags off)
- Real analytics/crash SDKs
- Audio assets + service
- Localization ARB files
- Hitbox/hurtbox architecture
- Object pooling
- Quality tiers (LOW/MED/HIGH)
- 3D assets / Unity project folder
- Revive flow (not implemented)

---

## Navigation map

```
HomeScreen
  ├─ PLAY ──────────► GameplayScreen (pushReplacement)
  ├─ Characters / Upgrades / Missions / High Scores / Settings (push)
  └─ (back refreshes home)

GameplayScreen
  ├─ Pause ──► PauseMenu (RESUME / RESTART / SETTINGS / HOME)
  ├─ Level-up power-up overlay (working)
  └─ Death reward overlay
        ├─ HOME ──────► HomeScreen
        └─ PLAY AGAIN ► new GameplayScreen
```

No named router. Pause has **no** exit routes.

---

## Assets

| Asset | Status |
|-------|--------|
| Hero run/attack/die PNGs | Bundled; prototype quality |
| Enemy PNGs + run frames | Partially used |
| `jump.png` | Bundled; unused |
| `birds.png` | On disk; not bundled |
| `background.gif` (~12MB) | On disk; **not bundled**; remove from shipping artifacts |
| Audio | None |

---

## Tests coverage

| Covered | Not covered |
|---------|-------------|
| Engine collision/rewards/difficulty | Pause soft-lock |
| XP curve / upgrade costs | GameplayScreen widget |
| Progress + high score repos | Missions claim |
| Home smoke | Character unlock flow |

---

## Relation to prior production plan

| Production-plan system | Phase 2 action |
|------------------------|----------------|
| Already implemented meta (XP/coins/chars/upgrades/power-ups/saves) | **KEEP** → migrate into 3D loop |
| Partial (missions/gems/pause/enemies) | **IMPROVE** |
| Incompatible (sprite combat, ATTACK button, X-collision) | **REPLACE** via engine migration |
| Flags-off (shop/ads/boss/daily) | Leave off until Fun Test |

Do **not** re-implement the entire previous plan from zero.

---

## Immediate next steps (ordered)

1. ✅ This audit (`PHASE_2_CURRENT_STATE.md`)
2. ✅ `docs/PHASE_2_ENGINE_DECISION.md` (Unity URP confirmed)
3. ✅ Flutter pause soft-lock fixed (`PauseMenu`)
4. → Bootstrap Unity URP project (Phase 2 architecture foundation)
5. → Vertical slice only; Fun Test before content expansion

---

## Definition of “do not start 3D yet”

Blocked until:

- [x] Current-state audit written
- [x] Engine decision verified for Phase 2 (`PHASE_2_ENGINE_DECISION.md`)

Then 3D prototype may begin — not a second parallel demo, but the evolution of this product’s gameplay client.
