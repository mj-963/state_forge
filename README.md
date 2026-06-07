# StateForge ⚒️

[![Build Status](https://img.shields.io/badge/build-passing-brightgreen.svg)](https://github.com/mj-963/state_forge)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Pub Version](https://img.shields.io/badge/pub-v0.1.5-blue.svg)](https://pub.dev/packages/state_forge)
[![Selectors](https://img.shields.io/badge/context.select-tested-brightgreen.svg)](https://github.com/mj-963/state_forge/tree/main/test)

**Structured Flutter state management. Zero boilerplate. Zero code generation. Zero ceremony.**

> One file per feature. Direct method calls. No events. No `build_runner`. No waiting.

---

## The Problem With Every Other Option

Flutter state management forces you into a false choice:

- **BLoC / Riverpod** — proper architecture, but 6+ files per feature, mandatory code generation, and the mental overhead of events → handlers → states. As the Bloc team often highlights, *the additional boilerplate is a trade-off for unparalleled predictability and scalability.*
- **GetX** — low ceremony, but global singleton chaos, untestable in practice, and a maintenance crisis you don't want to inherit.

**StateForge refuses this tradeoff.** You get BLoC's predictability and GetX's simplicity — in one file, with no code generator in sight.

---

## The 10-Second Proof

This is a complete login feature pattern. It keeps the state layer small while
still separating state changes from one-time effects.

```dart
// login_store.dart — your entire state layer for this feature
class LoginStore extends Store<AsyncState<User>> {
  LoginStore(this.api) : super(const Idle());
  final AuthApi api;

  Future<void> login(String email, String password) async {
    emit(const Loading());
    await guard(() async {
      final user = await api.login(email, password);
      emit(Success(user));
      effect('navigate_home'); // fire-and-forget side effect
    });
  }
}
```

```dart
// login_page.dart — the UI
class LoginPage extends StoreWidget<LoginStore, AsyncState<User>> {
  @override
  Widget buildStore(BuildContext context, LoginStore store, AsyncState<User> state) {
    return state.when(
      idle:    ()      => LoginForm(onSubmit: store.login),
      loading: ()      => const CircularProgressIndicator(),
      success: (user)  => WelcomeScreen(user: user),
      failure: (error) => ErrorView(error: error, onRetry: store.login),
    );
  }
}
```

That is the complete feature. **2 files. No events class. No states class. No build_runner step. No DI registration file.**

<details>
<summary>See the BLoC equivalent for comparison</summary>

The same feature in BLoC requires:
- `login_event.dart` — LoginRequested event class
- `login_state.dart` — LoginInitial, LoginLoading, LoginSuccess, LoginFailure (+ freezed annotations)
- `login_bloc.dart` — Bloc class + `on<LoginRequested>()` handler
- `injection.dart` — Register bloc and repository
- `login_page.dart` — `BlocProvider` + `BlocBuilder` + `BlocListener`
- Run: `dart run build_runner build` and wait 2–5 minutes

**6+ files. A code generation step. And you haven't written a single line of business logic yet.**

</details>

---

## Quick Start

**1. Add to pubspec.yaml**
```yaml
dependencies:
  state_forge: ^0.1.5
```

**2. Define your Store**
```dart
class CounterStore extends Store<int> {
  CounterStore() : super(0);

  void increment() => emit(state + 1);
  void decrement() => emit(state - 1);
}
```

**3. Provide it**
```dart
// Single store
StoreProvider<CounterStore>(
  create: (_) => CounterStore(),
  child: const CounterPage(),
)

// Multiple stores at app root
ForgeMultiProvider(
  providers: [
    StoreProvider<AuthStore>(create: (_) => AuthStore()),
    StoreProvider<CartStore>(create: (_) => CartStore()),
  ],
  child: const MyApp(),
)
```

**4. Use it**
```dart
// Option A: Extend StoreWidget (cleanest)
class CounterPage extends StoreWidget<CounterStore, int> {
  @override
  Widget buildStore(BuildContext context, CounterStore store, int count) {
    return Text('$count');
  }
}

// Option B: context.watch inline
final count = context.watch<CounterStore>().state;
Text('$count');

// Option C: ForgeBuilder for granular control
ForgeBuilder<CounterStore, int>(
  builder: (context, state, store) => Text('$state'),
)
```

---

## Core Concepts

### AsyncState — Async Without the Boilerplate

`AsyncState<T>` is a built-in sealed class that models the four states every async operation has. No need to write your own `Loading`, `Success`, `Failure` classes.

```dart
class ProductStore extends Store<AsyncState<List<Product>>> {
  ProductStore(this.repo) : super(const Idle());
  final ProductRepository repo;

  Future<void> load() async {
    emit(const Loading());
    await guard(() async {
      final products = await repo.fetchAll();
      emit(Success(products));
    });
  }
}

// In your widget — exhaustive, compiler-enforced
state.when(
  idle:    ()         => const EmptyState(),
  loading: ()         => const ShimmerList(),
  success: (products) => ProductGrid(products: products),
  failure: (error)    => RetryButton(onTap: store.load),
);

// Or use .map() for optional handling
state.maybeWhen(
  success: (products) => ProductGrid(products: products),
  orElse:  ()         => const LoadingSpinner(),
);
```

### Side Effects — First Class

Side effects (navigation, snackbars, analytics) are not UI state — they should never live in your state class. StateForge provides a dedicated `effect()` stream so you never have to hack your state to trigger a one-time event.

```dart
// In your store
Future<void> placeOrder() async {
  emit(const Loading());
  await guard(() async {
    final order = await repo.place(state.cart);
    emit(Success(order));
    effect(OrderPlaced(order.id));      // fire-and-forget
    effect(TrackAnalytics('purchase')); // multiple effects allowed
  });
}

// In your widget — reacts without rebuilding
ForgeListener<CartStore, CartEffect>(
  onEffect: (context, effect) => switch (effect) {
    OrderPlaced(:final orderId) => context.go('/confirmation/$orderId'),
    TrackAnalytics(:final event) => Analytics.track(event),
  },
  child: const CartPage(),
)
```

### Surgical Rebuilds — ForgeSelector

When a global store (cart, auth, profile) changes, only the widgets that care should rebuild. `ForgeSelector` lets you subscribe to a slice of state — rebuild only when that slice changes.

```dart
// Only rebuilds when item count changes — not on price updates, not on item edits
ForgeSelector<CartStore, CartState, int>(
  select: (state) => state.itemCount,
  builder: (context, count, store) => CartBadge(count: count),
)

// Multi-field selection via Dart Records (structural equality for free)
ForgeSelector<CartStore, CartState, (int, double)>(
  select: (state) => (state.itemCount, state.total),
  builder: (context, record, store) {
    final (count, total) = record;
    return CartSummary(count: count, total: total);
  },
)
```

The `context.select<T, S, R>()` extension follows the same selected-value
semantics for inline widget code.

### Scoped Lifecycle — Stores Die When Screens Die

StateForge uses the widget tree for store lifecycle — no `autoDispose`, no manual `close()`, no leaked controllers.

```dart
// Screen-scoped: auto-disposed when LoginPage leaves the tree
StoreProvider<LoginStore>(
  create: (_) => LoginStore(api: AuthApi()),
  child: const LoginPage(),
)

// Global: lives for the app session — place at MaterialApp
StoreProvider<AuthStore>(
  create: (_) => AuthStore(),
  child: MaterialApp(home: const HomePage()),
)

// Shared: pass an existing instance to a subtree (wizard flows, sibling tabs)
StoreProvider<CheckoutStore>.value(
  store: existingCheckoutStore,
  child: const StepThreePage(),
)
```

---

## Power Features

### UndoableStore — Undo/Redo in One Line

```dart
class DrawingStore extends Store<DrawingState> with UndoableStore<DrawingState> {
  DrawingStore() : super(DrawingState.empty());

  void addStroke(Stroke stroke) => emit(state.withStroke(stroke));
  // undo(), redo(), canUndo, canRedo — automatically available
}

// In your widget
IconButton(
  onPressed: store.canUndo ? store.undo : null,
  icon: const Icon(Icons.undo),
)
```

### PersistableStore — Opt-In Persistence

```dart
class SettingsStore extends Store<SettingsState> with PersistableStore<SettingsState> {
  SettingsStore() : super(SettingsState.defaults()) {
    hydrateOnCreate(debounce: const Duration(milliseconds: 250));
  }

  @override
  String get storageKey => 'settings';

  @override
  SettingsState fromJson(Map<String, dynamic> json) => SettingsState.fromJson(json);

  @override
  Map<String, dynamic> toJson(SettingsState state) => state.toJson();
}
```

Configure storage once at app startup:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  StateForge.storage = await SharedPreferencesForgeStorage.create();

  runApp(const App());
}
```

`state_forge` keeps storage as an adapter contract. Use
`state_forge_shared_preferences` for lightweight local JSON, or swap in Hive,
Drift, encrypted storage, files, or cloud sync by implementing
`ForgeStorageAdapter`.

If you need manual control, you can still call `hydrate()`, `persist()`, and
`persistOnChange()` yourself.

### CompositedStore — Clean Cross-Store Dependencies

No GetIt. No service locator. No global singletons. Cross-store dependencies are declared at the widget level and injected via constructor — fully testable.

```dart
// CartStore needs to know who's logged in
StoreProvider<CartStore>(
  create: (context) => CartStore(
    repo: CartRepository(),
    authStore: context.read<AuthStore>(), // reads parent store cleanly
  ),
  child: const CartPage(),
)
```

Lifecycle rule: constructor-injected store dependencies should be stable for as
long as the dependent store lives. For app-wide stores like auth, cart, and
profile, keep the store instance mounted and model changes as state transitions
(`LoggedIn` -> `LoggedOut`) instead of recreating the store instance. If a
dependency truly must be replaced, recreate the dependent store in the same
scope or wire the relationship explicitly with `CompositedStore`.

When a parent store instance is intentionally replaceable, use
`StoreProxyProvider` so the dependent store can be recreated or explicitly
rebound:

```dart
StoreProxyProvider<AuthStore, CartStore>(
  create: (context, auth) => CartStore(authStore: auth),
  update: (context, auth, cart) => cart.rebindAuth(auth),
  child: const CartPage(),
)
```

### Global Auditing — ForgeObserver

For enterprise teams that need a full audit trail of every state transition across the app (compliance, debugging, analytics):

```dart
void main() {
  StateForge.observer = ForgeObserver(
    onEmit: (store, prev, next) =>
      print('[${store.runtimeType}] $prev → $next'),
    onEffect: (store, effect) =>
      Analytics.track('effect', {'store': store.runtimeType, 'effect': effect}),
    onError: (store, error, stack) =>
      Sentry.captureException(error, stackTrace: stack),
  );
  runApp(const MyApp());
}
```

---

## State Patterns

StateForge supports two state patterns — use whichever fits your feature.

### Pattern A: Sealed Variants
Best for: auth flows, async data loading, multi-step wizards — anywhere with clearly distinct modes.

```dart
sealed class AuthState {}
class AuthIdle    extends AuthState { const AuthIdle(); }
class AuthLoading extends AuthState { const AuthLoading(); }
class AuthSuccess extends AuthState { const AuthSuccess(this.user); final User user; }
class AuthFailure extends AuthState { const AuthFailure(this.message); final String message; }

// Compiler enforces all cases are handled — no codegen needed
return switch (state) {
  AuthIdle()    => const LoginForm(),
  AuthLoading() => const CircularProgressIndicator(),
  AuthSuccess(:final user)    => WelcomeScreen(user: user),
  AuthFailure(:final message) => ErrorView(message: message),
};
```

### Pattern B: Data State with Named Transitions
Best for: profile editing, settings, checkout — anywhere with many fields that update independently.

```dart
class ProfileState {
  const ProfileState({this.name = '', this.email = '', this.isLoading = false, this.error});
  final String name;
  final String email;
  final bool isLoading;
  final String? error;

  // Named transitions document WHY the state changed
  ProfileState loading()            => ProfileState(name: name, email: email, isLoading: true);
  ProfileState withName(String n)   => ProfileState(name: n, email: email);
  ProfileState withEmail(String e)  => ProfileState(name: name, email: e);
  ProfileState withError(String e)  => ProfileState(name: name, email: email, error: e);
}
```

---

## Testing

Stores are plain classes with no `BuildContext` dependency — no `WidgetTester`,
no `pumpWidget()`, no async frame gymnastics. The store core lives in
`state_forge_core`, so business logic can also be tested from pure Dart packages.

```dart
// Plain unit test — runs in milliseconds
test('login emits Loading then Success', () async {
  final store = LoginStore(api: MockAuthApi());
  final states = <AsyncState<User>>[];
  store.addListener(() => states.add(store.state));

  await store.login('user@example.com', 'password');

  expect(states[0], isA<Loading>());
  expect(states[1], isA<Success<User>>());
});
```

Or use the included `forgeTest` utility for a declarative style:

```dart
forgeTest<CounterStore, int>(
  'emits [1, 2] when incremented twice',
  build: () => CounterStore(),
  act: (store) async {
    store.increment();
    store.increment();
  },
  expect: () => [1, 2],
);
```

---

## Performance

StateForge stores are pure Dart listenables, and the Flutter package exposes them
through `InheritedModel` for scoped widget-tree access.

- **O(1)** store lookup from any descendant widget
- **O(1)** notification dispatch
- **Frame coalescing** — if a store emits multiple times between frames, widgets rebuild exactly once
- **Surgical rebuilds** — `ForgeSelector` ensures only widgets that depend on changed data rebuild
- **Confirmed 100% surgical efficiency** in stress tests: 5,000+ item lists at 60Hz with zero unnecessary rebuilds

---

## Comparison

| | StateForge | BLoC 9.0 | Riverpod 3.0 | GetX |
|---|---|---|---|---|
| Files per feature | **1–2** | 6+ | 3–4 | 1–2 |
| Code generation | **None** | Required (freezed) | Required (@riverpod) | None |
| Testability | ✅ No widget pump | ✅ (bloc_test) | ✅ (ProviderContainer) | ❌ |
| Built-in async handling | ✅ AsyncState | ❌ | ❌ | ✅ |
| Side effects | ✅ First-class | 〜 Hacky | 〜 Lifecycle methods | ✅ |
| Auto-dispose | ✅ Widget tree | ✅ | ✅ (autoDispose) | ❌ |
| Learning curve | **Low** | High | Medium | Low |
| Scales to enterprise | ✅ | ✅ | ✅ | ❌ |

Need to pass a store to a Flutter API that requires `Listenable`? Use the
interop adapter:

```dart
final listenable = counterStore.asListenable();
```

---

## Migrating

- **[From BLoC →](/doc/migration/from_bloc.md)** Remove the ceremony. Keep the predictability.
- **[From Riverpod →](/doc/migration/from_riverpod.md)** Kill the build_runner. Keep the safety.
- **[From GetX →](/doc/migration/from_getx.md)** Keep the simplicity. Add the architecture.

---

## Resources

- **[Complete User Guide](/doc/README.md)** — Deep dive into every feature
- **[Performance Benchmark Suite](/benchmark_suite/)** — Clinical rebuild efficiency data
- **[Example App](/example/)** — Full e-commerce app: auth + products + cart

---

## License

StateForge is open-source under the **MIT License**.

---

<p align="center">
  <i>Built for Flutter developers who believe "accept the boilerplate" was never the right answer.</i>
</p>
