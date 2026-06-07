# Widgets & UI Integration 🎨

StateForge provides three ways to connect your Store to your Flutter UI.

## 1. The Shorthand (Extensions)
For most cases, using the `BuildContext` extensions is the fastest way to get started.

- **`context.watch<T>()`**: Subscribes to the store. Rebuilds the whole widget when the state changes.
- **`context.read<T>()`**: Fetches the store without subscribing. Use this inside `onPressed` or `onTap`.
- **`context.select<T, S, R>((s) => ...)`**: The surgical option. Only rebuilds if the specific selected value changes.

```dart
Widget build(BuildContext context) {
  final count = context.watch<CounterStore>().state;
  return Text('$count');
}
```

---

## 2. The Integrated Base (`StoreWidget`)
Instead of `StatelessWidget`, extend `StoreWidget` for features that center around a single store. This removes the need for context lookups entirely.

```dart
class CounterView extends StoreWidget<CounterStore, int> {
  @override
  Widget buildStore(BuildContext context, CounterStore store, int state) {
    return Column(
      children: [
        Text('Count: $state'),
        ElevatedButton(onPressed: store.increment, child: const Text('+')),
      ],
    );
  }
}
```

---

## 3. The Declarative Widgets
For localized rebuilds or combined logic.

### `ForgeBuilder`
Use this inside a large `build` method to ensure only a small portion of the screen rebuilds.
```dart
ForgeBuilder<AuthStore, AsyncState<String>>(
  builder: (context, state, store) => Text(state.data ?? 'Guest'),
)
```

### `ForgeSelector`
The widget version of `context.select`.
```dart
ForgeSelector<CartStore, CartState, int>(
  select: (state) => state.itemCount,
  builder: (context, count, store) => Badge(label: Text('$count')),
)
```

### `ForgeListener`
React to side effects (snackbars, navigation) without rebuilding the UI.
```dart
ForgeListener<AuthStore, String>(
  onEffect: (context, effect) {
    if (effect == 'login_success') Navigator.push(...);
  },
  child: MyForm(),
)
```
**Pro Tip**: If you are in a `StatefulWidget`, use the `ForgeEffectListener` mixin instead of this widget to keep your tree shallow.
