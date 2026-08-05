# Changelog

All notable changes to this project will be documented in this file.

## 0.2.0 - 2026-08-05

### Added
- Documented `optimistic()`, `LazyStoreProvider`, and `ForgeConsumer` in the
  README. All three already existed and none were mentioned.
- `EffectStore<S, E>`, a `Store` that declares the type of one-time effect it
  emits. `effect()` is narrowed to `E`, so passing an undeclared effect is a
  compile error instead of a message that silently goes nowhere, and
  `store.effects` exposes a typed `Stream<E>`. Pairs with the existing
  type-filtering in `ForgeListener` / `ForgeConsumer`.

### Fixed
- README documented `StoreProvider.value(store: ...)`; the parameter is
  `value:`, so the snippet did not compile.

### Changed
- Debug logging is now opt-in (`StateForge.debugMode = true`) rather than on
  whenever assertions are enabled, and log messages are no longer built when it
  is off. Via `state_forge_core` 0.1.4.
- README now leads with store composition (`watchStore`, `keep`) and an
  explicit migration-away section, and no longer presents `StoreWidget` as the
  primary way to read a store.

## 0.1.9 - 2026-07-22

### Fixed
- `forgeTest` now captures **every** state transition, including intermediate
  states produced by multiple synchronous `emit`s. Previously it observed state
  through a listener, which only fired after microtask coalescing and therefore
  dropped intermediate states — contradicting its documented "captures every
  state change" contract. Capture now happens through the synchronous observer
  hook and preserves/restores any previously installed observer.

### Changed
- **Behavior change (tests only):** a `forgeTest` whose `act` performs several
  synchronous emits now sees each state (e.g. `[1, 2]`) instead of only the
  final coalesced value (`[2]`). This matches `bloc_test` semantics. Runtime UI
  behavior is unchanged — widgets still coalesce synchronous emits into a single
  rebuild. Update affected `expect` lists accordingly, or use `emitSync` if you
  intend distinct notifications.

## 0.1.8 - 2026-06-10

### Changed
- Repositioned the example app as a movie watchlist demo instead of an
  e-commerce-style cart demo.
- Renamed the example cart feature to watchlist for clearer domain fit.
- Added clickable documentation links across README, guides, migration docs,
  benchmark notes, and DevTools notes.
- Added `bloc` as a pub topic for state-management discoverability.

## 0.1.7 - 2026-06-08

### Added
- Added a bundled Flutter DevTools extension under `extension/devtools`.
- Added public DevTools source under `state_forge_devtools`.
- Added a local benchmark and stress-test suite under `benchmark_suite`.
- Added a table of contents to the main README.

### Changed
- Updated package docs to describe feature-scoped adoption, scoped stores,
  one-time effects, and benchmark/devtools resources more precisely.
- Raised the `state_forge_core` dependency constraint to the published
  `^0.1.3` release.

## 0.1.6 - 2026-06-07

### Changed
- Refined README positioning to use more precise, less adversarial comparison
  language.
- Moved selective rebuild guidance higher in the README and added a simple
  architecture diagram.
- Replaced unsupported performance wording with references to benchmark and
  test coverage.

## 0.1.5 - 2026-06-07

### Fixed
- Added the Android internet permission to the example app main manifest.
- Converted example network failures into `AsyncState.failure` UI states
  instead of unhandled async exceptions.
- Encoded TVMaze request query parameters with structured `Uri` APIs.

## 0.1.4 - 2026-06-07

### Fixed
- Removed internal planning notes from the repository and published package
  archive.

## 0.1.3 - 2026-06-07

### Fixed
- Updated the MIT license copyright holder to Marcus Jacob.

## 0.1.2 - 2026-06-07

### Fixed
- Corrected GitHub links in README badges and long-form package notes.
- Aligned package metadata examples with the published repository URL.

## 0.1.1 - 2026-06-07

### Fixed
- Updated package metadata with reachable repository, issue tracker, and
  documentation links for pub.dev scoring.
- Shortened the package description for pub.dev display guidelines.

## 0.1.0 - 2026-04-20

### Added
- **Core Engine**: High-performance state propagation using `InheritedModel` and `SelectorAspect`.
- **Zero Codegen**: Entirely removes the need for `build_runner` or `freezed`.
- **AsyncState**: Built-in universal sealed class for `Idle`, `Loading`, `Success`, and `Failure` states.
- **Pattern Matching**: Functional API for `AsyncState` with `.when()`, `.maybeWhen()`, `.map()`, and `.maybeMap()`.
- **Side Effects**: First-class `effect()` system with `ForgeEffectListener` mixin for `StatefulWidget`.
- **Power Mixins**: `UndoableStore` (History) and `PersistableStore` (Persistence with `hydrate()`).
- **Dev-Friendly API**: Shorthand `context.watch()`, `context.read()`, and `context.select()` extensions.
- **Lazy Loading**: `LazyStoreProvider` for deferred store instantiation.
- **Optimistic Updates**: `optimistic()` helper for "success-first" UI transitions.
- **Global Hooks**: `StateForge.onError` and `StateForge.debugMode`.
- **DevTools Integration**: Initial hooks for Flutter DevTools extension.
- **Example App**: A movie discovery/watchlist app using the TVMaze API.
- **Persistence Ergonomics**: `PersistableStore.persistOnChange()` for opt-in
  automatic persistence with debounce support.
- **Hydration Lifecycle**: `PersistableStore.hydrateOnCreate()` to load
  persisted state before attaching automatic persistence.
- **SharedPreferences Adapter**: First-party
  `state_forge_shared_preferences` package for lightweight durable JSON state.
