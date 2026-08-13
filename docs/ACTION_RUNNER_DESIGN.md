# Shadow Run — Action Runner Direction

**Date:** 2026-08-11  
**Status:** Active product direction for Flutter client  
**Relation to prior 3D/Unity docs:** Unity remains the long-term path for *true* 3D. This document locks the **immediate** shipping gameplay as a **2.5D cyberpunk action runner** inside Flutter — matching the latest design brief without faking Unity-grade 3D.

---

## Product feel

Fast · dark · premium · responsive · cinematic · replayable

Continuous forward run with meaningful decisions every second:

Jump · Slide · Dodge · Melee combo · Ranged (charges + reload) · Hazards · Collect · Survive

**Removed as primary UX:** giant ATTACK button.

---

## Controls

| Input | Action |
|-------|--------|
| Swipe up | Jump (longer swipe → higher jump) |
| Swipe down | Slide / duck |
| Swipe left / right | Dodge dash (i-frames + cooldown) |
| Tap | Melee slash (combo 1→2→3) |
| Hold | Fire ranged (consumes charge) |

Input buffer (~120ms) for forgiveness.

---

## Visual identity

Replace amber/yellow prototype stage with **dark futuristic cyberpunk**:

- Night city / industrial neon
- Parallax layers, fog, neon accents (cyan / magenta)
- Minimal modern HUD (no giant attack CTA)

World themes (data-driven): Cyber City → Industrial Ruins → Underground → Night Wasteland.

---

## Architecture

```
lib/game/runner/          # UI-free simulation (physics, combat, spawn)
lib/features/gameplay/action_runner_screen.dart
lib/features/gameplay/pause_menu.dart   # reuse
lib/data/repositories/    # preserve XP/coins/gems/upgrades
```

Preserve progression repositories. Do not wipe saves.

---

## Implementation phases (this brief)

1. Core movement + combat + reload + collision ← **in progress**
2. Enemy variety + combo juice + VFX
3. Worlds + hazards + procedural segments
4. Progression polish (ranged upgrades, missions)
5. Menus / HUD / game over presentation
6. Audio + performance polish
