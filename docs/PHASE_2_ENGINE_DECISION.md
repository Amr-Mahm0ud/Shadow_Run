# Shadow Run — Phase 2 Engine Decision

**Date:** 2026-08-11  
**Status:** Confirmed  
**Companion audit:** `docs/PHASE_2_CURRENT_STATE.md`  
**Prior decision:** `docs/3D_ENGINE_DECISION.md` (re-verified against Phase 2 requirements)

---

## 1. Question

Can the **current** Shadow Run technology stack deliver Phase 2?

Required capabilities:

| Capability | Required for Phase 2 |
|------------|----------------------|
| Real 3D rendering | Yes |
| 3D lighting / shadows / fog | Yes |
| 3D models + materials | Yes |
| Skeletal animation | Yes |
| Physics (gravity, impulse, knockback, projectiles) | Yes |
| Colliders / hitboxes / hurtboxes | Yes |
| Particles + pooling | Yes |
| Professional follow camera + shake | Yes |
| Mobile performance + quality tiers | Yes |
| Navigation / pathfinding for enemies | Strongly preferred |

---

## 2. Current engine capability (verified)

| Capability | Current Flutter client |
|------------|------------------------|
| 3D rendering | **No** — widgets + sprites |
| Lighting / fog / shadows | **No** — flat colors |
| 3D models / skeletal anim | **No** |
| Physics | **No** |
| Real collision volumes | **No** — X-offset windows |
| Particles | **No** |
| Camera system | **No** |
| Pathfinding | **No** |
| Game loop suitable for 3D sim | **No** — AnimationController tween |

**Conclusion:** The current stack **cannot** reasonably provide Phase 2.  

**Do not fake 3D** with skewed sprites, fake perspective layers, or pseudo-depth over the amber background. That would still resemble the visual baseline screenshot.

**Do not use `flame_3d` for production** — upstream docs mark it experimental and unsuitable for shipping games.

---

## 3. Options re-evaluated for Phase 2

### A) Stay on Flutter widgets / CustomPainter “fake 3D”

| | |
|--|--|
| Pros | No migration |
| Cons | Cannot meet Phase 2 definition of done |
| Verdict | **Rejected** |

### B) Flutter + Flame 2D (polish current genre as 2D)

| | |
|--|--|
| Pros | Dart continuity; good 2D tooling |
| Cons | Explicitly **not** the Phase 2 product goal (“real 3D action-survival”) |
| Verdict | **Rejected** for Phase 2 scope |

### C) Flutter + flame_3d

| | |
|--|--|
| Pros | Stay in Flutter |
| Cons | Experimental Flutter GPU; unstable APIs; “do not use for production”; incomplete commercial combat/physics pipeline |
| Verdict | **Rejected** |

### D) Godot 4

| | |
|--|--|
| Pros | Real 3D, animation, physics, lighting; MIT; strong indie fit; competitive mobile size |
| Cons | Smaller ads/IAP/middleware ecosystem; full client rewrite |
| Verdict | **Viable alternative** |

### E) Unity (URP) — recommended

| | |
|--|--|
| Pros | Mature mobile 3D; Animator; PhysX; URP lighting/fog/shadows; particles; NavMesh; camera tooling; quality settings; Asset Store for vertical-slice speed; mature mobile SDK ecosystem |
| Cons | Package size needs discipline; C# rewrite; licensing awareness |
| Verdict | **Selected** |

### F) Hybrid Flutter hub + embedded Unity view

| | |
|--|--|
| Pros | Reuse Flutter menus short-term |
| Cons | Dual lifecycle, dual builds, higher crash surface; delays Fun Test |
| Verdict | **Rejected for v1** (revisit only after vertical slice is fun) |

### G) Unreal

| | |
|--|--|
| Verdict | **Rejected** — overkill for stylized mobile roguelite |

---

## 4. Final Phase 2 decision

| Field | Value |
|-------|-------|
| **Shipping gameplay client** | **Unity LTS + Universal Render Pipeline (URP)** |
| **Fallback** | Godot 4 (if team prioritizes MIT / lighter tooling over ecosystem) |
| **Flutter role** | Living reference prototype + portable progression/design source until Unity vertical slice replaces gameplay |
| **Fake 3D in Flutter** | Forbidden |
| **Duplicate systems** | Forbidden — migrate catalogs/config/save schema |

This confirms and does not reopen `docs/3D_ENGINE_DECISION.md` unless new production evidence appears.

---

## 5. What migrates vs what is rebuilt

### Migrate (keep working intent)

- Progression fields: XP, coins, gems, level, unlocks, upgrade levels, best score
- Character trio fantasy + base stats
- Power-up / upgrade / mission catalogs (improve stubs)
- Feature-flag and monetization order
- Analytics event names
- `GamePhase`-style explicit states including robust **PAUSE**

### Rebuild in Unity

- Rendering, camera, lighting, environment
- Player controller, combat, dodge, hitboxes
- Enemy AI, spawns, physics interactions
- HUD / controls (no giant ATTACK button)
- Pause UI (Resume / Restart / Settings / Home) — fix soft-lock in architecture
- Audio / VFX / particles

### Improve while migrating

- Missions claim + persistence
- Power-up stubs that don’t affect combat
- Tank multi-hit HP
- Gems earn/spend loop (later, still gated)

---

## 6. Vertical slice gate (before content expansion)

Playable Unity slice must include:

- 3D player + Shadow Forest chunk
- Camera follow
- One weapon
- Three enemy types
- Move / attack / dodge
- Collision + basic physics interactions
- Health / damage / XP + one power-up choice
- Particles + lighting + sound stubs
- Pause (Resume / Restart / Home) **working**
- Game over + rewards wired to progression schema

If it does not feel like a real mobile game → stop adding features; fix feel.

---

## 7. Implementation order (locked)

1. ✅ Phase 2 current-state audit  
2. ✅ This engine decision  
3. Fix Flutter pause soft-lock (reference client + pattern for Unity pause architecture)  
4. Create `unity/ShadowRun` URP project  
5. 3D prototype → player → camera → movement → physics → combat → AI → environment  
6. Integrate progression  
7. UI + pause hardened  
8. Optimize + long-session QA  

One step broken → do not advance.

---

## 8. Reason (one paragraph)

Phase 2 demands genuine 3D worlds, skeletal animation, physics-driven combat, professional cameras, and mobile quality tiers. The current Flutter sprite client has none of these. Experimental Flutter 3D is not a commercial foundation. Unity URP is the lowest-risk path to a polished stylized 3D mobile action-survival game while preserving Shadow Run’s existing progression design through data migration—not through faking depth on the yellow prototype stage.
