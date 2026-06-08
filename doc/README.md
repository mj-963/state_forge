# StateForge Documentation

StateForge is a feature-scoped state layer for Flutter apps. It keeps feature
state in explicit store objects, uses the widget tree for scoping, and separates
one-time effects from rebuild-driving state.

## Start Here
- **[README](/README.md)**: Package overview, mental model, and quick start.
- **[When Not to Use StateForge](/README.md#when-not-to-use-stateforge)**:
  Tradeoffs and cases where another tool may be a better fit.

## Core Guide
- **[Core Concepts](/doc/guide/core-concepts.md)**: Deep dive into Stores, States, and the `AsyncState` engine.
- **[UI Integration](/doc/guide/widgets.md)**: How to use `watch`, `read`, `select`, builders, selectors, and effect listeners.
- **[Advanced Features](/doc/guide/advanced-features.md)**: Mixins for history, persistence, and store composition.

## Developer Tooling
- **[Testing with `forgeTest`](/lib/src/forge_test.dart)**: Declarative unit testing for your business logic.
- **[Benchmark Suite](/benchmark_suite/)**: Local rebuild and stress-test scenarios.
- **[DevTools Source](/state_forge_devtools/)**: Source for the DevTools extension bundled in `extension/devtools/`.

## Migration Path
- **[From BLoC](/doc/migration/from_bloc.md)**: Removing the indirection of events and handlers.
- **[From Riverpod](/doc/migration/from_riverpod.md)**: Moving selected feature state into explicit store objects.
- **[From GetX](/doc/migration/from_getx.md)**: Moving from globally registered controllers to widget-scoped stores.

---
Built by the StateForge community.
