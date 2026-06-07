# Migrating from GetX to StateForge

If you are coming from GetX, you likely value **simplicity** and **low ceremony**. You might be frustrated with BLoC's boilerplate or Riverpod's code generation. 

StateForge is the perfect destination for GetX developers: it keeps the "one file per feature" speed but adds the **structured architecture** and **testability** that professional apps require.

## Core Concepts Comparison

| GetX Concept | StateForge Equivalent |
| :--- | :--- |
| `GetxController` | `Store<S>` |
| `obs` / `RxInt` | The `state` object (immutable) |
| `obx` / `GetX` widget | `ForgeBuilder` or `context.watch<T>()` |
| `Get.find<T>()` | `context.read<T>()` or `context.watch<T>()` |
| `Get.put(Store())` | `StoreProvider(create: (_) => Store())` |

## Why Move to StateForge?

1.  **Scoped Lifecycles**: In GetX, managing when a controller is deleted is notoriously difficult. In StateForge, stores are scoped to the widget tree—they are **automatically disposed** when the screen is removed. No more memory leaks or global state pollution.
2.  **Immutability**: GetX relies on observable primitives (`.obs`) which can lead to unpredictable side effects in large apps. StateForge uses immutable states, making your app's flow 100% predictable.
3.  **No Global Magic**: StateForge doesn't use a global internal map for dependency injection. It uses Flutter's native `InheritedWidget` system, making it faster and compatible with all Flutter dev tools.
4.  **Testability**: Because StateForge stores have no `BuildContext` dependency and are not global singletons, you can unit test them without pumping widgets or clearing global state between tests.

## Side-by-Side Example

### GetX (Global Singletons)
```dart
class CounterController extends GetxController {
  var count = 0.obs;
  void increment() => count++;
}

// UI
Obx(() => Text('${controller.count}'));
```

### StateForge (Scoped & Structured)
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
StateForge gives you the same "one-file" velocity as GetX, but with an architectural foundation that scales to enterprise-level applications.
