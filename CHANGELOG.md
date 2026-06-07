# Changelog

All notable changes to this project will be documented in this file.

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
- **Example App**: A full-featured Movie E-commerce app using TVMaze API.
- **Persistence Ergonomics**: `PersistableStore.persistOnChange()` for opt-in
  automatic persistence with debounce support.
- **Hydration Lifecycle**: `PersistableStore.hydrateOnCreate()` to load
  persisted state before attaching automatic persistence.
- **SharedPreferences Adapter**: First-party
  `state_forge_shared_preferences` package for lightweight durable JSON state.
