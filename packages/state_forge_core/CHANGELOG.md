# Changelog

## 0.1.5 - 2026-08-05

### Fixed

- `optimistic()` reported a rolled-back failure to `StateForge.onError` but not
  to `StateForge.observer`, so those errors were missing from the audit trail
  that `guard()` populated. Both are now notified.

## 0.1.4 - 2026-08-05

### Added

- `EffectStore<S, E>`, a `Store` whose `effect()` is narrowed to a declared
  effect type `E`, plus a typed `Stream<E> get effects`.

### Changed

- **`StateForge.debugMode` now defaults to `false`.** It previously defaulted to
  on whenever assertions were enabled, so every debug build and every
  `flutter test` run printed a line per state transition. That flooded test
  output and roughly doubled update cost in debug. Set
  `StateForge.debugMode = true` to restore the old behaviour.

### Fixed

- Transition and effect log messages were interpolated on every emit before the
  debug flag was checked, so a `toString()` of both states ran even when logging
  was off, including in release builds. The call sites are now guarded.

## 0.1.3 - 2026-06-07

### Fixed

- Added a pure Dart package example for pub.dev scoring.
- Made `StateForge` non-instantiable so dartdoc no longer reports an
  undocumented default constructor.

## 0.1.2 - 2026-06-07

### Fixed

- Updated the MIT license copyright holder to Marcus Jacob.

## 0.1.1 - 2026-06-07

### Fixed

- Updated package metadata with reachable repository, issue tracker, and
  documentation links for pub.dev scoring.
- Expanded the package description to match pub.dev display guidelines.

## 0.1.0 - 2026-06-07

### Added

- Initial pure Dart StateForge core package.
- `Store<S>` with coalesced async emits, synchronous emits, listeners, effects,
  disposal, resource cleanup, guarded async actions, and optimistic updates.
- `AsyncState<T>` sealed variants for idle, loading, success, and failure.
- `StateForge` global configuration, storage adapter contract, diagnostics hook,
  and observer support.
- `UndoableStore`, `PersistableStore`, and `CompositedStore` mixins.
