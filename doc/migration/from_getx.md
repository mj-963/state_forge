# Migrating from GetX to StateForge

If you are coming from [GetX](https://pub.dev/packages/get), you likely value
simplicity and low ceremony. [StateForge](../../README.md) keeps direct method
calls, but scopes stores through Flutter's widget tree and models state as
immutable values.

You can try it in one feature without changing the rest of your app.

## Core Concepts Comparison

| GetX Concept | StateForge Equivalent |
| :--- | :--- |
| `GetxController` | `Store<S>` |
| `obs` / `RxInt` | The `state` object (immutable) |
| `obx` / `GetX` widget | `ForgeBuilder` or `context.watch<T>()` |
| `Get.find<T>()` | `context.read<T>()` or `context.watch<T>()` |
| `Get.put(Store())` | `StoreProvider(create: (_) => Store())` |

## Key Differences

1. **Widget-tree scoping**: Stores live where you mount their provider. They are
   only app-wide if you place them at the app root.
2. **Immutable state objects**: Store state is a value. Update it by emitting a
   new value.
3. **Explicit lookup**: Read stores from `BuildContext` or pass dependencies
   through constructors.
4. **Plain unit tests**: Stores have no `BuildContext` dependency, so most
   business logic can be tested without a widget tree.

## Side-by-Side Example

### GetX
```dart
class CounterController extends GetxController {
  var count = 0.obs;
  void increment() => count++;
}

// UI
Obx(() => Text('${controller.count}'));
```

### StateForge
```dart
class CounterStore extends Store<int> {
  CounterStore() : super(0);
  void increment() => emit(state + 1);
}

// UI
final count = context.watch<CounterStore>().state;
Text('$count');
```

## Summary
StateForge is a fit when you want direct methods and small feature files while
making store ownership and dependencies explicit.

Related docs: [Core Concepts](../guide/core-concepts.md),
[UI Integration](../guide/widgets.md), and
[Advanced Features](../guide/advanced-features.md).
