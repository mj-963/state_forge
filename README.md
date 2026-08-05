# StateForge ⚒️

[![Build Status](https://img.shields.io/badge/build-passing-brightgreen.svg)](https://github.com/mj-963/state_forge)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Pub Version](https://img.shields.io/badge/pub-v0.2.1-blue.svg)](https://pub.dev/packages/state_forge)
[![Selectors](https://img.shields.io/badge/context.select-tested-brightgreen.svg)](https://github.com/mj-963/state_forge/tree/main/test)

**Feature-scoped stores for Flutter. They compose, they own their subscriptions,
and your widgets don't have to inherit from them.**

> Plain Dart classes. Direct method calls. No event classes, no code generation,
> no `build_runner`.

---

## Table of Contents

- [Why StateForge](#why-stateforge)
- [Mental Model](#mental-model)
- [The 10-Second Proof](#the-10-second-proof)
- [Removing It](#removing-it)
- [Quick Start](#quick-start)
- [Core Concepts](#core-concepts)
- [Power Features](#power-features)
- [State Patterns](#state-patterns)
- [Testing](#testing)
- [Performance](#performance)
- [When Not to Use StateForge](#when-not-to-use-stateforge)
- [Comparison](#comparison)
- [Migrating](#migrating)
- [Resources](#resources)
- [License](#license)

---

## Why StateForge

Most state libraries ask for an architectural commitment before they will hold a
single value. StateForge asks for a class.

A store is a plain Dart object: one piece of state, and methods that change it.
Widgets read it with `context.watch` / `context.read`. **No widget of yours has
to extend anything from this package**, so one feature can use StateForge
without the rest of the app agreeing to it. (`StoreWidget` exists as a
convenience if you want it — it is never required.)

That is about what StateForge decides for you, not about how far it scales.
Mount stores at the app root and you have app-wide state management. A shipping
personal-finance app runs on it end to end: sixteen stores over a local
database, with persistence, undo, cross-store composition, and no second state
library.

What it will not do is pick an architecture for you. Every transition, effect,
and error is observable through [`ForgeObserver`](#global-auditing--forgeobserver),
so auditing is covered — but intent is not modelled as data the way BLoC's
events are, no dependency graph works out invalidation on your behalf, and
nothing enforces a single shape across a team. You bring that structure, or you
do without it. Those are real things to want, and if you want them decided and
enforced rather than agreed,
[BLoC](https://pub.dev/packages/flutter_bloc) and
[Riverpod](https://pub.dev/packages/flutter_riverpod) are built for exactly
that.

## Mental Model

```text
Widget
  │ reads / selects / listens
  ▼
Store
  ├─ state  ──> rebuild UI
  └─ effect ──> one-time navigation, snackbars, analytics
  │
  ▼
Repository / API
```

---

## The 10-Second Proof

A store is a class with methods. The widget is an ordinary `StatelessWidget`.

```dart
// counter_store.dart
class CounterStore extends Store<int> {
  CounterStore() : super(0);

  void increment() => emit(state + 1);
}
```

```dart
// counter_page.dart — no base class, no builder ceremony
class CounterPage extends StatelessWidget {
  const CounterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final count = context.watch<CounterStore>().state;
    return Scaffold(
      body: Center(child: Text('$count')),
      floatingActionButton: FloatingActionButton(
        onPressed: context.read<CounterStore>().increment,
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

### Stores compose, and they clean up after themselves

This is the part worth adopting the package for. A store can derive its state
from another store and own the subscriptions feeding it — no `dispose()` to
write, no listener bookkeeping:

```dart
class TransactionStore extends Store<TransactionState>
    with CompositedStore<TransactionState> {
  final Database _db;
  final WorkspaceStore _workspace;
  List<Transaction> _rows = const [];

  TransactionStore(this._db, this._workspace) : super(TransactionState()) {
    // Re-derive whenever the active workspace changes.
    watchStore(_workspace, (_) => _emitScoped());

    // keep() ties the subscription to this store's lifetime.
    keep(_db.watchTransactions().listen((rows) {
      _rows = rows;
      _emitScoped();
    }));
  }

  void _emitScoped() => emitSync(
    state.withTransactions(
      _rows.where((r) => r.workspaceId == _workspace.state.id).toList(),
    ),
  );
}
```

`keep()` accepts any `StreamSubscription`, `Timer`, `Sink`, or object with a
`dispose()`, and disposes it when the store goes. `watchStore()` unsubscribes
the same way.

## Removing It

Worth asking of any dependency before you adopt it, so here is the honest
answer: a `Store` is a plain Dart class from `state_forge_core`, and unless you
opted into `StoreWidget`, no widget of yours inherits from this package.
Migrating away moves your logic as-is and changes only the widget-facing edge —
`context.watch` becomes whatever the next library reads with.

For Flutter APIs that take a `Listenable` — `ListenableBuilder`,
`AnimatedBuilder`, `Listenable.merge` — there is an adapter, which is also the
seam to migrate through:

```dart
final listenable = counterStore.asListenable();
```

---

## Quick Start

**1. Add to pubspec.yaml**
```yaml
dependencies:
  state_forge: ^0.2.1
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
// Option A: context.watch inline — the common case
final count = context.watch<CounterStore>().state;
Text('$count');

// Option B: ForgeBuilder to scope the rebuild to a subtree
ForgeBuilder<CounterStore, int>(
  builder: (context, state, store) => Text('$state'),
)

// Option C: StoreWidget, a convenience base class for a page that is
// entirely driven by one store. Optional — nothing else requires it.
class CounterPage extends StoreWidget<CounterStore, int> {
  @override
  Widget buildStore(BuildContext context, CounterStore store, int count) {
    return Text('$count');
  }
}
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

// Or maybeWhen / maybeMap when you only care about some cases
state.maybeWhen(
  success: (products) => ProductGrid(products: products),
  orElse:  ()         => const LoadingSpinner(),
);
```

### Selective Rebuilds — ForgeSelector

When a shared store (cart, auth, profile) changes, only the widgets that care
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

Side effects (navigation, snackbars, analytics) are not UI state — they should
never live in your state class. StateForge provides a dedicated `effect()`
stream so you never have to hack your state to trigger a one-time event.
Effects are consumed once by listeners and are not replayed just because a
widget rebuilds.

Extend `EffectStore<S, E>` to declare what a store is allowed to emit. `E` is
enforced by the compiler, so a typo or an effect from another feature is an
error rather than a message that silently goes nowhere:

```dart
sealed class CartEffect {}

final class OrderPlaced extends CartEffect {
  const OrderPlaced(this.orderId);
  final String orderId;
}

final class TrackAnalytics extends CartEffect {
  const TrackAnalytics(this.event);
  final String event;
}

class CartStore extends EffectStore<AsyncState<Order>, CartEffect> {
  CartStore(this.repo) : super(const Idle());
  final CartRepository repo;

  Future<void> placeOrder() async {
    emit(const Loading());
    await guard(() async {
      final order = await repo.place(state.cart);
      emit(Success(order));
      effect(OrderPlaced(order.id));      // fire-and-forget
      effect(TrackAnalytics('purchase')); // multiple effects allowed
      effect('order_placed');             // compile error
    });
  }
}
```

```dart
// In your widget — reacts without rebuilding
ForgeListener<CartStore, CartEffect>(
  onEffect: (context, effect) => switch (effect) {
    OrderPlaced(:final orderId) => context.go('/confirmation/$orderId'),
    TrackAnalytics(:final event) => Analytics.track(event),
  },
  child: const CartPage(),
)
```

Because `E` is a sealed type, the `switch` above is exhaustive — add a new
effect variant and every listener that does not handle it stops compiling.
`ForgeListener` can also narrow to a single variant
(`ForgeListener<CartStore, OrderPlaced>`), and `store.effects` is a `Stream<E>`
for listening outside the widget tree.

When a widget needs to both rebuild on state *and* react to effects, use
`ForgeConsumer` instead of nesting a builder inside a listener:

```dart
ForgeConsumer<CartStore, AsyncState<Order>, CartEffect>(
  onEffect: (context, effect) => switch (effect) {
    OrderPlaced(:final orderId) => context.go('/confirmation/$orderId'),
    TrackAnalytics(:final event) => Analytics.track(event),
  },
  builder: (context, state, store) => CartView(state: state),
)
```

Plain `Store<S>` keeps the untyped `effect(Object)` channel, so nothing that
already works needs to change.

### Optimistic Updates — Roll Back on Failure

`optimistic()` applies a state immediately, then reverts it if the work throws.
The rollback target defaults to the state you had before, so the common case is
one call:

```dart
Future<void> toggleLike(Post post) {
  return optimistic(
    state.withLiked(post.id),      // shown immediately
    api.like(post.id),             // if this throws, the state reverts
  );
}

// Or revert to a specific state instead of the previous one
Future<void> submit(Draft draft) {
  return optimistic(
    state.sending(),
    api.send(draft),
    onFailure: state.failed(),
  );
}
```

The error is rethrown after the rollback, so callers can still react to it.

### Scoped Lifecycle — Stores Die When Screens Die

StateForge uses the widget tree for store lifecycle. A store lives for as long
as its provider is mounted, then it is disposed automatically.

```dart
// Screen-scoped: auto-disposed when LoginPage leaves the tree
StoreProvider<LoginStore>(
  create: (_) => LoginStore(api: AuthApi()),
  child: const LoginPage(),
)

// App-scoped: lives for the app session — place at MaterialApp
StoreProvider<AuthStore>(
  create: (_) => AuthStore(),
  child: MaterialApp(home: const HomePage()),
)

// Shared: pass an existing instance to a subtree (wizard flows, sibling tabs)
StoreProvider<CheckoutStore>.value(
  value: existingCheckoutStore,
  child: const StepThreePage(),
)

// Deferred: not constructed until something first reads it. For expensive
// stores behind a route the user may never open.
LazyStoreProvider<ReportsStore>(
  create: (context) => ReportsStore(context.read<TransactionStore>()),
  child: const ReportsPage(),
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
[`state_forge_shared_preferences`](https://github.com/mj-963/state_forge/tree/main/packages/state_forge_shared_preferences) for
lightweight local JSON, or swap in
[Hive](https://pub.dev/packages/hive), [Drift](https://pub.dev/packages/drift),
encrypted storage, files, or cloud sync by implementing `ForgeStorageAdapter`.

If you need manual control, you can still call `hydrate()`, `persist()`, and
`persistOnChange()` yourself.

### CompositedStore — Clean Cross-Store Dependencies

Dependencies are injected through the constructor, which keeps store
relationships visible and easy to test:

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

Injection alone gives you a reference. To make the dependent store *react*, add
the `CompositedStore` mixin and use `watchStore` — the subscription is released
when the store is disposed, so there is nothing to unwind by hand:

```dart
class CartStore extends Store<CartState> with CompositedStore<CartState> {
  CartStore({required AuthStore authStore}) : super(const CartState()) {
    watchStore(authStore, (auth) {
      if (auth.state.isLoggedOut) clear();
    });
  }
}
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
  // emit() coalesces notifications into a microtask, so let the queue drain
  // before asserting. Use emitSync() if you need each one delivered eagerly.
  await Future<void>.delayed(Duration.zero);

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

StateForge limits rebuild work by batching asynchronous notifications into a
microtask, resolving stores through scoped inherited widgets rather than global
listeners, rebuilding selector widgets only when the selected value changes, and
keeping one-time effects off the state path entirely.

The bundled
[`benchmark_suite/`](https://github.com/mj-963/state_forge/tree/main/benchmark_suite)
runs the same scenarios against BLoC and Riverpod. On 1,000 updates driving a
subscribed widget, `ForgeBuilder` is on par with `BlocBuilder` and ahead of
Riverpod's `Consumer`; after 1,000 *unrelated* updates all three rebuild exactly
once. Reading through `context.watch` costs more than either, because it rebuilds
the provider rather than a leaf — reach for `ForgeBuilder` or `ForgeSelector` on
hot paths.

These are local engineering signals on one machine, not universal claims. The
suite ships in the repo with the competing implementations beside it, so run it
yourself.

---

## When Not to Use StateForge

StateForge is intentionally focused on feature-scoped state and direct store
methods. It may not be the best fit when:

- Your team is already standardized on
  [BLoC](https://pub.dev/packages/flutter_bloc),
  [Riverpod](https://pub.dev/packages/flutter_riverpod), or
  [Provider](https://pub.dev/packages/provider) and the current architecture is
  working well
- You need strict event-sourcing semantics where every state transition must be
  modeled as a domain event
- Your app is mostly a provider graph or dependency graph problem rather than a
  feature-state problem
- You want generated provider APIs, compile-time provider wiring, or a larger
  ecosystem around dependency injection

## Comparison

This table is about default ergonomics and package focus, not a claim that other
tools cannot model the same workflows.

| | StateForge | BLoC | Riverpod | Provider |
|---|---|---|---|---|
| Primary unit | Store | Bloc / Cubit | Provider | ChangeNotifier / value |
| Code generation required | **No** | No | No | No |
| Generated APIs available | No | Optional via ecosystem | Optional | No |
| Async state helper | ✅ `AsyncState` | Common via custom states | ✅ `AsyncValue` | Custom |
| One-time effects | ✅ Dedicated stream, typed via `EffectStore<S, E>` | Common via listener patterns | Common via listeners/ref | Custom |
| Selective rebuilds | ✅ `ForgeSelector`, `context.select` | ✅ `BlocSelector` | ✅ `select` | ✅ `Selector` |
| Pure Dart core | ✅ `state_forge_core` | ✅ | ✅ | 〜 Flutter-oriented |
| Typical feature shape | Direct store methods | Event/command handlers | Provider graph | Notifier methods |

---

## Migrating

- **[From BLoC →](https://github.com/mj-963/state_forge/blob/main/doc/migration/from_bloc.md)** Move from event handlers to direct store methods.
- **[From Riverpod →](https://github.com/mj-963/state_forge/blob/main/doc/migration/from_riverpod.md)** Move feature state into explicit store objects.
- **[From GetX →](https://github.com/mj-963/state_forge/blob/main/doc/migration/from_getx.md)** Keep low ceremony while making dependencies explicit.

---

## Resources

- **[Complete User Guide](https://github.com/mj-963/state_forge/tree/main/doc)** — Deep dive into every feature
- **[Benchmark Suite](https://github.com/mj-963/state_forge/tree/main/benchmark_suite)** — Local rebuild and stress-test scenarios
- **[DevTools Source](https://github.com/mj-963/state_forge/tree/main/state_forge_devtools)** — Source for the bundled DevTools extension
- **[Example App](https://github.com/mj-963/state_forge/tree/main/example)** — Movie watchlist demo with auth, search, details, profile, and persistence

---

## License

StateForge is open-source under the **MIT License**.

---

<p align="center">
  <i>Built for Flutter developers who want small feature files without giving up predictable state transitions.</i>
</p>
