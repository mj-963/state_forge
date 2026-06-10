# Migrating from Riverpod to StateForge

[Riverpod](https://pub.dev/packages/flutter_riverpod) is strong at provider
composition and dependency modeling. [StateForge](../../README.md) is narrower:
it moves feature state into explicit store objects that are scoped in the
Flutter widget tree.

## Core Concepts Comparison

| Riverpod Concept | StateForge Equivalent |
| :--- | :--- |
| `Notifier<S>` / `AsyncNotifier<S>` | `Store<S>` |
| `ref.watch(provider)` | `context.watch<T>()` |
| `ref.read(provider)` | `context.read<T>()` |
| `provider.select((s) => s.x)` | `context.select<T, S, R>((s) => s.x)` |
| `ConsumerWidget` / `ref` | `StoreWidget` / `context` |
| `ProviderScope` | `ForgeMultiProvider` / `StoreProvider` |

## Key Differences

1. **Store object per feature**: State and feature commands live in a plain Dart
   class.
2. **Widget-tree scoping**: `StoreProvider` owns the store lifecycle. When the
   provider leaves the tree, the store is disposed.
3. **Constructor injection**: Pass repositories or parent stores into the store
   constructor when you want explicit dependencies.
4. **No required code generation**: StateForge APIs are handwritten Dart classes
   and Flutter widgets.

## Side-by-Side Example

### Riverpod Notifier
```dart
@riverpod
class Counter extends _$Counter {
  @override
  int build() => 0;

  void increment() => state++;
}

// UI
final count = ref.watch(counterProvider);
```

### StateForge
```dart
class CounterStore extends Store<int> {
  CounterStore() : super(0);

  void increment() => emit(state + 1);
}

// UI
final count = context.watch<CounterStore>().state;
```

## Summary
StateForge is a fit when a feature wants a small object-oriented state layer.
Riverpod remains a strong choice when the provider graph itself is the center of
the architecture.

Related docs: [Core Concepts](../guide/core-concepts.md),
[UI Integration](../guide/widgets.md), and
[Advanced Features](../guide/advanced-features.md).
