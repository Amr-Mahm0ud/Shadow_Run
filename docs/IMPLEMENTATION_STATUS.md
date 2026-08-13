# Shadow Run — Implementation Status

**Last updated:** 2026-08-11  
**Active gameplay client:** Flutter **2.5D cyberpunk action runner**  
**Design:** `docs/ACTION_RUNNER_DESIGN.md` + SHADOW//RUN character concept sheet  
**Note:** Unity remains a long-term option for true 3D; immediate product path is this runner.

---

## Action runner — Phase 1 foundation

| Item | Status |
|------|--------|
| Continuous forward run + gravity/jump | **Done** |
| Slide (swipe down) | **Done** |
| Dodge + i-frames (swipe L/R) | **Done** |
| Melee combo tap (1–3) | **Done** |
| Ranged hold + 3 charges + reload UI | **Done** |
| Gesture controls (no giant ATTACK button) | **Done** |
| Cyberpunk parallax world | **Done** |
| Enemy archetypes (melee/fast/ranged/heavy) | **Partial** |
| Hazards (spikes / lasers) | **Partial** |
| Combo multiplier + score | **Done** |
| Pause RESUME/RESTART/SETTINGS/HOME | **Done** |
| Run rewards → progress/high scores | **Done** |
| Modern HUD (HP, score, ranged, combo, ability, ult) | **Done** |
| 4 playable characters (Runner/Hunter/Blade/Phantom) | **Done** |
| Unique stats + ability + ultimate per character | **Done** |
| Sprite sheets + weapons + VFX assets | **Done** |
| Character select / unlock / equip | **Done** |
| SHADOW//RUN branding (SVG + PNG + icon) | **Done** |
| Double-tap ability / charged ultimate | **Done** |

### Asset layout
```
assets/
  branding/     logo.svg, symbol.svg, PNGs, app icon
  characters/   runner|hunter|blade|phantom spritesheets + frames
  weapons/      per-character weapon PNGs
  vfx/          slash, dash, muzzle, mark, wave, phase, fracture…
```

### Tests
`flutter test` — **22 passed**  
`flutter analyze lib/ test/` — clean

Legacy `GameplayScreen` remains in repo but is no longer the PLAY entry point.
