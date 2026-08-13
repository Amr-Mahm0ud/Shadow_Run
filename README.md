# Shadow Run

Fast-paced arcade survival game built with Flutter.

Survive waves of enemies, collect coins and XP, choose power-ups, unlock characters, and upgrade between runs.

## Status

**Active gameplay:** 2.5D cyberpunk **action runner** (gesture combat — no giant ATTACK button).

See:

- [`docs/ACTION_RUNNER_DESIGN.md`](docs/ACTION_RUNNER_DESIGN.md)
- [`docs/IMPLEMENTATION_STATUS.md`](docs/IMPLEMENTATION_STATUS.md)
- [`docs/PHASE_2_CURRENT_STATE.md`](docs/PHASE_2_CURRENT_STATE.md)

## Run

```bash
flutter pub get
flutter run
```

## Test

```bash
flutter analyze
flutter test
```

## Notes

- Landscape gameplay
- Local persistence via GetStorage (repository-backed)
- Analytics/crash reporting currently use development adapters (no production backends configured yet)
- Android/iOS application IDs remain `com.example.*` until store IDs are finalized
