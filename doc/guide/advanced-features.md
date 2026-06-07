# Advanced Features 🚀

Once you master the basics, StateForge offers powerful tools for industrial-scale apps.

## 1. Mixins: Optional Power-Ups
StateForge is "batteries included but opt-in."

### `UndoableStore`
Add undo/redo support to any store in one line.
```dart
class CanvasStore extends Store<Drawing> with UndoableStore<Drawing> { ... }

// store.undo() and store.redo() are now available!
```

### `PersistableStore`
Define how your state is serialized, then connect it to a storage adapter.
```dart
class ThemeStore extends Store<ThemeMode> with PersistableStore<ThemeMode> {
  ThemeStore() : super(ThemeMode.system) {
    hydrateOnCreate(debounce: const Duration(milliseconds: 250));
  }

  @override
  String get storageKey => 'theme';

  @override
  Map<String, dynamic> toJson(ThemeMode state) => {'mode': state.name};

  @override
  ThemeMode fromJson(Map<String, dynamic> json) => ThemeMode.values.byName(json['mode']);
}
```

Configure a global adapter once:
```dart
StateForge.storage = await SharedPreferencesForgeStorage.create();
```

Persistence is intentionally opt-in. Use `hydrateOnCreate()` when a store should
load saved state first and then save every future state change. Use
`persistOnChange()` directly when you only need auto-save, or call `persist()`
manually when saving should happen only after explicit user actions.

### `CompositedStore`
Easily watch other stores from inside your store. No more global singletons.
```dart
class OrderStore extends Store<OrderState> with CompositedStore<OrderState> {
  OrderStore(AuthStore auth) : super(const OrderState()) {
    // Automatically updates when user logs in/out
    watchStore(auth, (a) => emit(state.withUserId(a.state.data)));
  }
}
```

### `StoreProxyProvider`
Use `StoreProxyProvider` when one store is created from another store and the
parent store instance may be replaced. Without `update`, the dependent store is
disposed and recreated. With `update`, the existing dependent store can rebind
to the new dependency.

```dart
StoreProxyProvider<AuthStore, CartStore>(
  create: (context, auth) => CartStore(authStore: auth),
  update: (context, auth, cart) => cart.rebindAuth(auth),
  child: const CartPage(),
)
```

---

## 2. Global Auditing (`ForgeObserver`)
Enterprise apps need audit trails. Create a `ForgeObserver` to log every single state transition in your app.

```dart
final logger = ForgeObserver(
  onEmit: (store, oldState, newState) {
    print('${store.runtimeType} changed: $newState');
  },
);

void main() {
  StateForge.observer = logger;
  runApp(MyApp());
}
```

---

## 3. Scoping: `LazyStoreProvider`
For performance optimization, you can defer the creation of a heavy store until a widget actually tries to watch it.

```dart
LazyStoreProvider<MapStore>(
  create: (context) => MapStore(), // Not created until the Map screen opens
  child: const MapScreen(),
)
```

---

## 4. `optimistic()` Updates
Build "instantly successful" UIs. This helper emits a state immediately, runs an async action, and automatically rolls back if the action fails.

```dart
Future<void> likePost(String id) async {
  await optimistic(
    state.withLike(id), // Emits immediately
    api.postLike(id),    // Runs in background
  ); // Automatically reverts to previous state if api fails
}
```
