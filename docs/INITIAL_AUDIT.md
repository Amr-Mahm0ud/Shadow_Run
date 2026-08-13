# Shadow Run — Initial Repository Audit

**Date:** 2026-08-11  
**Repo:** https://github.com/Amr-Mahm0ud/Shadow_Run  
**Auditor role:** Phase 0 production transition audit + 3D transform re-audit  
**Rule:** No significant production behavior changes during audit-only work.

> **3D extension:** Sections 15–17 supersede earlier “stay on Flutter gameplay forever” assumptions.  
> Engine decision: see `docs/3D_ENGINE_DECISION.md`. Migration: `docs/3D_MIGRATION_PLAN.md`.

---

## 1. Executive summary

Shadow Run is a small Flutter arcade prototype with a working core loop (attack/survive, score, lives, speed ramp, local high scores). It is **not production-ready**. Architecture, branding, meta-progression, audio, localization, analytics, monetization, store identity, and testing depth are missing or prototype-level.

**Production readiness today:** Not production ready (prototype).

---

## 2. Environment & identifiers

| Item | Current value |
|------|----------------|
| Flutter | 3.32.5 (stable) |
| Dart | 3.8.1 |
| App version | 1.0.0+1 |
| Dart package name | `multi_media_game` |
| Android `applicationId` / namespace | `com.example.multi_media_game` |
| Android label | `multi_media_game` |
| iOS bundle ID | `com.example.multiMediaGame` |
| iOS display name | `Multi Media Game` |
| iOS deployment target | 12.0 |
| Android minSdk (Flutter default) | 21 |
| Android compileSdk / targetSdk (Flutter default) | 35 |
| Release signing | Debug keys (`signingConfig signingConfigs.debug`) |

**Decision:** Preserve Android/iOS package IDs until a real store account / reverse-DNS ID is chosen. Update **user-facing** names to **Shadow Run** first.

---

## 3. Current architecture

```
lib/
  main.dart                 # orientation lock, GetStorage.init, MaterialApp → Home
  design/
    home.dart               # menu UI + Navigator routes
    start_game.dart         # gameplay UI + game loop + collision + HUD (~476 LOC)
    high_scores.dart        # reads HighScore() directly
  logic/
    controller.dart         # HighScore persistence (GetStorage)
    models/
      hero.dart             # HeroCharacter: status string + lives
      enemy.dart            # Enemy: status string + single image
```

### Layering assessment

| Layer | Status |
|-------|--------|
| UI | Present; mixed with game logic in `start_game.dart` |
| Application / game controller | Implicit inside `_GameState` |
| Explicit game state machine | Missing (booleans / string statuses) |
| Domain models | Minimal (`HeroCharacter`, `Enemy`) |
| Repositories | Missing (UI/controller call GetStorage) |
| Services (analytics/ads/audio/crash) | Missing |

### State management

- Ad-hoc `ValueNotifier`s inside `_GameState`
- `AnimationController` drives enemy slide + collision windows
- No Provider/Riverpod/Bloc; acceptable for MVP if logic is extracted

### Persistence

- `get_storage` via `HighScore` class
- Stores three keys: `first`, `second`, `third`
- Ranking logic has edge-case bugs (ties / equal scores)
- UI constructs `HighScore()` directly (no DI / repository)

---

## 4. Current dependencies

### Direct

| Package | Version | Notes |
|---------|---------|-------|
| flutter | SDK | OK |
| cupertino_icons | ^1.0.8 | Unused for product need; keep or drop later |
| get_storage | ^2.1.1 | Works; pulls old `file` → override required on Dart 3.8+ |

### Overrides

| Package | Version | Why |
|---------|---------|-----|
| file | ^7.0.1 | Unblocks `get_storage` / `path_provider` on Dart 3.8+ |

### Dev

| Package | Version | Notes |
|---------|---------|-------|
| flutter_lints | ^5.0.0 | Resolvable to 6.0.0 |
| flutter_test | SDK | One smoke widget test |

### Outdated (resolvable)

- `flutter_lints` 5 → 6
- `cupertino_icons` patch available

No analytics, crash reporting, ads, billing, audio, localization, or networking packages yet — correct for Phase 0–3.

---

## 5. Current gameplay systems

### What works

1. Landscape-left orientation lock
2. Home → Start Game / High Scores
3. Hero run sprite loop (4 frames)
4. Attack button (timed attack window)
5. Enemy slide via `SlideTransition`
6. Collision: hit while running → lose life; attack during window → +5 score
7. Difficulty: enemy duration decreases by 200ms per wave (floor 1500ms)
8. Theme toggle every 50 score points (sky/sun colors)
9. Game over overlay → Main Menu / Play Again
10. High score write on exit from game over
11. Image precache + `cacheHeight` / `RepaintBoundary` (recent perf work)

### What is missing vs product vision

- Explicit game states (idle/countdown/playing/paused/levelUp/boss/gameOver/reward)
- Movement / dodge
- Coins, XP, level-up power-up choices
- Multiple enemy types / weapons / bosses
- Characters, upgrades, missions, achievements, daily rewards
- Pause, settings, audio, localization
- Professional UI branding (“Avengers Game” still shown)
- Analytics / crash / ads / IAP / cloud save / leaderboards

### Game loop today (simplified)

```
Start → enemy animates L←R → collision window →
  miss/hit handling → wave resets faster → lives→0 → overlay → save score
```

---

## 6. Assets

| Asset | Size | Bundled? | Verdict |
|-------|------|----------|---------|
| run1–4, attack, die1–3, jump, enemy | ~80–180KB each; hero frames ~1200×902 | Yes (except jump unused in UI) | **Retain** for MVP; downsample later |
| enemy_run1–4, enemy1, birds | present | No | **Retain** for future enemy animation |
| background.gif | **~12MB**, 480×270 | No (correctly excluded) | **Do not ship**; replace with lightweight art |

Art direction is inconsistent with a commercial “Shadow / neon fantasy” identity. Treat current sprites as temporary MVP art.

---

## 7. Tests & quality

| Check | Result |
|-------|--------|
| `flutter analyze` | 4× info (`use_super_parameters`) — no errors |
| `flutter test` | Pass (1 widget test: Home labels) |
| Unit tests for game logic | None |
| Integration / golden tests | None |

---

## 8. Problems & technical debt

### Critical (block production)

1. Example store IDs (`com.example.*`) and debug release signing
2. No crash reporting / analytics abstractions
3. No privacy/terms/store compliance assets
4. Product naming inconsistency (Shadow Run vs Avengers / multi_media_game)
5. Gameplay depth far below retention/monetization bar

### Major

1. God-widget `_GameState` mixes UI, timing, collision, theme, persistence navigation
2. Stringly-typed hero/enemy statuses
3. No pause / lifecycle handling (backgrounding mid-run)
4. High-score update logic fragile; no repository boundary
5. `get_storage` requires `file` override (fragile dependency story)
6. Unused jump path / unused assets not organized
7. Hard-coded English UI strings
8. Orientation: code locks landscapeLeft only; iOS Info.plist still allows portrait

### Minor

1. Super parameters not used
2. README still Flutter template + “multi_media_game”
3. Heart icons / Material defaults — prototype look
4. Attack hit detection is X-window based, not hitboxes

### Performance notes

- Positive: precache, cacheHeight, RepaintBoundary, ValueNotifiers
- Risk: large source PNGs (~1200px) on low-end devices; GIF must stay out of bundle
- Animation listener collision checks are light enough for current scope

---

## 9. Proposed architecture

Adopt plan structure with pragmatic MVP subset:

```
lib/
  core/           # theme, constants, routing, config, feature flags, errors
  data/           # models, local storage, repositories
  game/           # engine, player, enemies, systems (testable, UI-free)
  features/       # home, gameplay, high_scores, settings, …
  services/       # storage adapters; later analytics/ads/purchases stubs
  widgets/        # shared UI
  main.dart
```

**Principles**

- UI → controller → game state → domain → repositories → local/remote
- Explicit `GamePhase` enum
- Centralized economy/config maps
- Service interfaces with real adapters later (no fake production claims)
- Feature flags for ads/leaderboard/shop/boss/etc.

---

## 10. Migration risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Renaming Dart package `multi_media_game` → `shadow_run` | Import churn | Mechanical rename + tests |
| Changing store application IDs | Breaks updates if ever published | Keep IDs until store decision |
| Extracting game loop from widget | Regressions in collision/timing | Port behavior first; add unit tests for collision/scoring |
| Replacing `get_storage` | Score migration | Repository with migration from old keys |
| Adding Flame/Forge2D later | Rewrite cost | Stay custom AnimationController until Phase 3–4 proves need |
| Scope explosion (full MVP content) | Incomplete half-features | Follow phase order; ship vertical slices |

---

## 11. Production risks

1. Monetizing before fun → player churn / store rejection risk  
2. Client-only leaderboards → cheating  
3. Trusting device clock for daily rewards  
4. Shipping 12MB GIF or unoptimized art → install size / reviews  
5. Ads without consent/privacy policy → compliance failure  
6. Secrets in repo (none found today; prevent when adding Firebase/AdMob)

---

## 12. Recommended implementation order

Follow master plan phases 0 → 22. Immediate next steps:

1. **Phase 0** — this audit + `IMPLEMENTATION_STATUS.md` ✅  
2. **Phase 1** — branding, lints, pubspec hygiene, dependency cleanup path  
3. **Phase 2** — folder architecture + repository for high scores + routing/theme  
4. **Phase 3** — extract engine, `GamePhase`, pause, reward/game-over flow  
5. Then enemies → weapons → power-ups → difficulty/boss → progression…

Do **not** add ads/IAP until gameplay + progression are stable.

---

## 13. Useful existing behavior to preserve

- Attack timing / collision window feel
- Wave speed ramp curve (6s → 1.5s step 200ms)
- Score +5 on kill, 3 lives
- Local top-3 scores
- Image precache + cacheHeight approach
- Landscape gameplay assumption

---

## 14. Assets / code to replace or remove later

- Branding strings: “Avengers Game”, “multi_media_game”, “Multi Media Game” (user-facing largely fixed; store IDs still `com.example.*`)
- Unused `background.gif` from release artifacts (already not in pubspec; ~12MB on disk)
- Prototype Material home / game-over cards
- Direct GetStorage usage from UI (mitigated via repositories)

---

## 15. 3D transform re-audit (2026-08-11)

### 15.1 What currently exists (post Flutter production scaffold)

| System | Status |
|--------|--------|
| Layered `lib/` (core/data/game/features/services) | Present |
| `GameEngine` + `GamePhase` | Present (2D rules) |
| Characters Shadow/Ninja/Demon | Stats + unlock UI |
| Enemies normal/fast/tank | Data-driven defs; simple slide AI |
| Power-ups (10) choose-3 | Partial |
| Upgrades (8) coin sink | Partial |
| Missions UI | Partial (claim/daily TBD) |
| Progress/high score/settings repos | Present |
| Analytics/crash facades | Dev adapters only |
| Flame / 3D / physics | **Absent** |
| Free movement / dodge / weapons / bosses | **Absent** |
| Tests | Engine, repos, home smoke (~11 tests historically) |

**Gameplay feel today:** Side-view sprite survival with a permanent ATTACK button. Enemies slide on a tween path. Not a 3D action game.

### 15.2 Preserve

- Product name, fantasy, character trio concepts
- Economy / XP / upgrade / power-up design seeds
- Meta progression fields and repository boundaries
- Monetization order (fun → retention → ads)
- Analytics intent and feature-flag approach
- Landscape mobile focus
- Documentation discipline

### 15.3 Replace

- Entire sprite/`AnimationController` gameplay client
- ATTACK-button-primary combat
- X-offset collision model
- Flat colored “sky” as environment
- Prototype character/enemy PNGs as final hero art

### 15.4 Engine feasibility (summary)

| Option | Verdict |
|--------|---------|
| Current Flutter widgets | Cannot deliver required 3D |
| Flame 2D | Good for alternate 2D product only |
| flame_3d | Experimental; **not production** |
| Godot 4 | Viable |
| **Unity URP** | **Recommended shipping client** |

Full analysis: `docs/3D_ENGINE_DECISION.md`.

### 15.5 Production risks unique to 3D path

1. Scope explosion past vertical slice  
2. Binary size / low-end thermal throttling  
3. Physics bugs ending runs unfairly  
4. Maintaining Flutter + Unity dual clients too long  
5. Art/animation pipeline stalling engineering  

### 15.6 Recommended order now

1. Lock engine decision ✅  
2. Migration plan ✅  
3. Status tracker for 3D phases ✅  
4. Bootstrap Unity URP project  
5. 3D rendering prototype → player controller → physics → combat  
6. Vertical slice → Fun Test → only then content/monetization  

Do **not** start coding the whole 3D game in one pass.

---

## 16. File inventory snapshot (Flutter client)

~30 Dart files under `lib/`, 3 under `test/`, ~14MB `assets/` (dominated by unused `background.gif`).

No `flame` dependency. No platformer/3D modules present in tree at audit time (any earlier experimental platformer paths are not part of the current workspace).

---

## 17. Related documents

| Doc | Role |
|-----|------|
| `docs/3D_ENGINE_DECISION.md` | Engine choice |
| `docs/3D_MIGRATION_PLAN.md` | How to migrate |
| `docs/IMPLEMENTATION_STATUS.md` | Live phase tracker |
| `docs/ARCHITECTURE.md` | Current Flutter layering |
| `docs/ROADMAP.md` | Prior 2D production roadmap (superseded for gameplay client by 3D plan) |
