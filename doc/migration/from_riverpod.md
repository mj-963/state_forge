# Migrating from Riverpod to StateForge

If you are coming from Riverpod, you will love the **Zero Codegen** philosophy of StateForge. While Riverpod 3.0 moves towards mandatory code generation, StateForge stays with handwritten Dart classes and Flutter widgets.

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

1.  **No `ref` object**: You don't need to pass a `WidgetRef` or `ref` around. Everything is accessible via `BuildContext` or constructor injection.
2.  **No Code Generation**: You never need to run `build_runner`. No `@riverpod` annotations. Just classes and methods.
3.  **Scoped by Design**: StateForge uses Flutter's widget tree for scoping. When a `StoreProvider` is removed from the tree, the store is automatically disposed. No more `autoDispose` flags.
4.  **OOP First**: While Riverpod is functional, StateForge is Object-Oriented. Logic lives inside your Store class methods.

## Side-by-Side Example

### Riverpod 3.0 (with Codegen)
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

### StateForge (Zero Codegen)
```dart
class CounterStore extends Store<int> {
  CounterStore() : super(0);

  void increment() => emit(state + 1);
}

// UI
final count = context.watch<CounterStore>().state;
```

## Summary
StateForge provides the same high-performance, fine-grained reactivity as Riverpod but with a significantly lower learning curve and zero dependency on code generators.
