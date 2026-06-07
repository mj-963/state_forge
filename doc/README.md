# StateForge: Master the Architecture 📚

StateForge is more than a state management library; it is a **structured architecture system** for Flutter. It is designed to provide the rigor of BLoC with the simplicity of Riverpod, all without the need for code generation.

## 🚀 Architectural Foundations
- **[Introduction & Philosophy](/README.md#-the-core-philosophy)**: Why StateForge exists and the false dichotomy of BLoC vs Riverpod.
- **[The Four Pillars](/README.md#-architectural-pillars)**: Intent-based updates, first-class effects, scoped lifecycles, and async safety.

## 🏗️ Core Guide
- **[Core Concepts](/doc/guide/core-concepts.md)**: Deep dive into Stores, States, and the `AsyncState` engine.
- **[UI Integration](/doc/guide/widgets.md)**: How to use `watch`, `read`, and `select` to build surgical UIs.
- **[Advanced Power-Ups](/doc/guide/advanced-features.md)**: Mixins for History, Persistence, and Store Composition.

## 🛠️ Developer Tooling
- **[Testing with `forgeTest`](/lib/src/forge_test.dart)**: Declarative unit testing for your business logic.
- **[DevTools Extension](/state_forge_devtools/)**: Visualizing state timelines and side effects in real-time.
- **[Performance Benchmark Suite](/benchmark_suite/)**: Clinical data proving 100% surgical rebuild efficiency.

## 🔄 Migration Path
- **[From BLoC](/doc/migration/from_bloc.md)**: Removing the indirection of events and handlers.
- **[From Riverpod](/doc/migration/from_riverpod.md)**: Moving from `@riverpod` annotations to handwritten Dart classes.
- **[From GetX](/doc/migration/from_getx.md)**: Moving from global magic to scoped architecture.

---
Built with ⚒️ by the StateForge community.
