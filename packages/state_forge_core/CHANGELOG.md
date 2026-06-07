# Changelog

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
