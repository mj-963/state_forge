# state_forge_core

Pure Dart core primitives for StateForge.

This package contains the framework-independent store engine used by the
Flutter-facing `state_forge` package:

- `Store<S>` with listener-based state updates
- `AsyncState<T>` sealed variants
- `effect()` streams for one-time events
- `guard()`, `optimistic()`, and resource cleanup
- `UndoableStore`, `PersistableStore`, and `CompositedStore`
- `StateForge` configuration, storage, diagnostics, and observer hooks

Use this package directly when you want StateForge store logic in a pure Dart
package, CLI, backend, or shared module. Flutter apps should usually depend on
`state_forge`, which re-exports these core APIs and adds widget-tree integration.

```dart
import 'package:state_forge_core/state_forge_core.dart';

class CounterStore extends Store<int> {
  CounterStore() : super(0);

  void increment() => emit(state + 1);
}
```
