# StateForge ⚒️

[![Build Status](https://img.shields.io/badge/build-passing-brightgreen.svg)](https://github.com/mj-963/state_forge)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Pub Version](https://img.shields.io/badge/pub-v0.1.6-blue.svg)](https://pub.dev/packages/state_forge)
[![Selectors](https://img.shields.io/badge/context.select-tested-brightgreen.svg)](https://github.com/mj-963/state_forge/tree/main/test)

**Structured Flutter state management. Zero boilerplate. Zero code generation. Zero ceremony.**

> One file per feature. Direct method calls. No events. No `build_runner`. No waiting.

---

## Why StateForge

StateForge is for Flutter features that should stay small without becoming
implicit or hard to test.

BLoC emphasizes explicit event-driven architecture. Riverpod emphasizes provider
composition and strong dependency modeling. Provider keeps close to Flutter's
widget tree. StateForge focuses on a narrower goal:

> Build a feature in one or two files, with direct method calls, predictable
> state transitions, scoped rebuilds, and first-class one-time effects.

No event classes. No generated state classes. No `build_runner` step required.

## Mental Model

```text
Widget
  │ reads / selects / listens
  ▼
Store
  ├─ state  ──> rebuild UI
  └─ effect ──> navigation, snackbars, analytics
  │
  ▼
Repository / API
```

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

That is the complete feature. **2 files. No event class. No generated state
class. No `build_runner` step.**

<details>
<summary>See the BLoC equivalent for comparison</summary>

Depending on team conventions, the same feature in BLoC often uses:
- `login_event.dart` — LoginRequested event class
- `login_state.dart` — LoginInitial, LoginLoading, LoginSuccess, LoginFailure
- `login_bloc.dart` — Bloc class + `on<LoginRequested>()` handler
- Optional DI setup — register bloc and repository
- `login_page.dart` — `BlocProvider` + `BlocBuilder` + `BlocListener`

StateForge compresses that shape when you want direct command methods instead of
an event pipeline.

</details>

---

## Quick Start

**1. Add to pubspec.yaml**
```yaml
dependencies:
  state_forge: ^0.1.6
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

### Selective Rebuilds — ForgeSelector

When a global store (cart, auth, profile) changes, only the widgets that care
should rebuild. `ForgeSelector` lets you subscribe to a slice of state and
rebuild only when that selected value changes.

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

Cross-store dependencies are declared at the widget level and injected via
constructor, which keeps store relationships visible and easy to test.

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
- **Selective rebuilds** — `ForgeSelector` rebuilds only when the selected value changes
- Benchmark scenarios live in [`benchmark_suite/`](/benchmark_suite/) and focused rebuild behavior is covered by tests

---

## Comparison

This table is about default ergonomics and package focus, not a claim that other
tools cannot model the same workflows.

| | StateForge | BLoC | Riverpod | Provider |
|---|---|---|---|---|
| Primary unit | Store | Bloc / Cubit | Provider | ChangeNotifier / value |
| Code generation required | **No** | No | No | No |
| Generated APIs available | No | Optional via ecosystem | Optional | No |
| Async state helper | ✅ `AsyncState` | Common via custom states | ✅ `AsyncValue` | Custom |
| One-time effects | ✅ Dedicated effect stream | Common via listener patterns | Common via listeners/ref | Custom |
| Selective rebuilds | ✅ `ForgeSelector`, `context.select` | ✅ `BlocSelector` | ✅ `select` | ✅ `Selector` |
| Pure Dart core | ✅ `state_forge_core` | ✅ | ✅ | 〜 Flutter-oriented |
| Typical feature shape | Direct store methods | Event/command handlers | Provider graph | Notifier methods |

Need to pass a store to a Flutter API that requires `Listenable`? Use the
interop adapter:

```dart
final listenable = counterStore.asListenable();
```

---

## Migrating

- **[From BLoC →](/doc/migration/from_bloc.md)** Move from event handlers to direct store methods.
- **[From Riverpod →](/doc/migration/from_riverpod.md)** Move feature state into explicit store objects.
- **[From GetX →](/doc/migration/from_getx.md)** Keep low ceremony while making dependencies explicit.

---

## Resources

- **[Complete User Guide](/doc/README.md)** — Deep dive into every feature
- **[Performance Benchmark Suite](/benchmark_suite/)** — Rebuild and stress-test scenarios
- **[Example App](/example/)** — Full e-commerce app: auth + products + cart

---

## License

StateForge is open-source under the **MIT License**.

---

<p align="center">
  <i>Built for Flutter developers who want small feature files without giving up predictable state transitions.</i>
</p>
