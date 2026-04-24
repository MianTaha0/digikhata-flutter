# DigiKhata (Flutter)

Cross-platform rewrite of [digikhata-clone](https://github.com/MianTaha0/digikhata-clone) targeting Android + iOS from a single Flutter codebase.

## Stack

- Flutter 3.x / Dart 3.x
- Riverpod — state management + DI
- go_router — routing
- drift — SQLite persistence (type-safe)
- Material 3

## Status

**M0 — Scaffold.** Empty 5-tab Home, DigiRed theme, drift skeleton, smoke test green.

See [`../digikhata-clone/docs/superpowers/specs/2026-04-24-digikhata-flutter-rewrite-design.md`](../digikhata-clone/docs/superpowers/specs/2026-04-24-digikhata-flutter-rewrite-design.md) for the full spec and milestone plan.

## Develop

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # regen drift
flutter test                                               # run tests
flutter run                                                # launch on connected device/simulator
```
