# Shadow Run — Architecture

## Layering

```
UI (features/*)
  → AppServices / repositories
  → GameEngine (rules, no Flutter timers)
  → Domain (player, enemies, powerups, upgrades)
  → LocalStorage (GetStorage adapter)
```

Widgets must not call GetStorage, ads, purchases, or analytics SDKs directly.

## Game state

`GamePhase`: idle → countdown → playing ↔ paused → levelUp → playing → gameOver → reward

## Key modules

| Path | Responsibility |
|------|----------------|
| `lib/game/engine/` | Phases, collision, difficulty, run rewards |
| `lib/game/player/` | Player stats + character catalog |
| `lib/game/enemies/` | Data-driven enemy definitions |
| `lib/game/powerups/` | Run power-up catalog |
| `lib/data/repositories/` | High scores, progress, settings |
| `lib/services/` | Analytics/crash facades (dev adapters) |
| `lib/features/` | Screens |

## Feature flags

`lib/core/config/feature_flags.dart` gates ads, shop, boss, cloud save, etc.

## Persistence keys

Defined in `AppConstants`. Legacy high-score keys are migrated automatically.
