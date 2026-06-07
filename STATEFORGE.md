# StateForge — Complete Planning & Design Document

> Flutter state management with zero boilerplate, zero code generation, and zero ceremony.
> One store file per feature. Built on Dart 3 sealed classes, a pure Dart core, and Flutter's InheritedModel.

---

## Table of Contents

1. [Origin & Problem Statement](#1-origin--problem-statement)
2. [Market Research — What Flutter Devs Are Complaining About](#2-market-research--what-flutter-devs-are-complaining-about)
3. [Competitive Landscape](#3-competitive-landscape)
4. [Why StateForge — The Gap Nobody Has Filled](#4-why-stateforge--the-gap-nobody-has-filled)
5. [Core Philosophy & Design Constraints](#5-core-philosophy--design-constraints)
6. [Name Decision](#6-name-decision)
7. [Internal Architecture Decisions](#7-internal-architecture-decisions)
8. [Complete Public API Surface](#8-complete-public-api-surface)
9. [State Design — Two Patterns](#9-state-design--two-patterns)
10. [Scoping Model — Four Store Lifetimes](#10-scoping-model--four-store-lifetimes)
11. [Effects System](#11-effects-system)
12. [Edge Cases & Solutions](#12-edge-cases--solutions)
13. [Package File Structure](#13-package-file-structure)
14. [pubspec.yaml](#14-pubspecyaml)
15. [Developer Experience — What You Write](#15-developer-experience--what-you-write)
16. [Testing Story](#16-testing-story)
17. [DevTools & Debugging](#17-devtools--debugging)
18. [Problem Scorecard — What We Solve](#18-problem-scorecard--what-we-solve)
19. [Market Positioning vs 2026 Competitors](#19-market-positioning-vs-2026-competitors)
20. [Example App Plan](#20-example-app-plan)
21. [Build Phases](#21-build-phases)

---

## 1. Origin & Problem Statement

This project started from researching what Flutter developers are *chronically* complaining about — not one-off bugs, but multi-year unresolved pain that has large community signal.

The #1 complaint, confirmed across GitHub issues, Reddit, Stack Overflow, and the 2024 LeanCode CTO Report:

> **"BLoC / Riverpod ceremony is exhausting. Every feature needs events, states, blocs, providers, and freezed models. Changing a simple field requires touching 5–12 files."**

This pain has existed since 2019 and no existing tool has fully solved it. Every existing solution either:
- Requires code generation (Riverpod, BLoC with freezed)
- Sacrifices architecture for simplicity (GetX)
- Solves a different problem entirely (signals, state_beacon — reactive primitives, not structured state management)

StateForge is designed to be what Cubit wished it was: structured, testable, and fully devoid of ceremony.

---

## 2. Market Research — What Flutter Devs Are Complaining About

Researched from: GitHub issues, Reddit, Stack Overflow, LeanCode CTO Report 2024, dev.to, medium, Flutter Discord.

### The 8 Biggest Pain Points (with community signal)

| # | Pain Point | Signal | StateForge Solves? |
|---|---|---|---|
| 1 | BLoC/Riverpod ceremony — 5+ files per feature | 500+ GitHub thumbs, countless Reddit threads | ✅ Fully |
| 2 | No standard project structure — every project is a snowflake | Top Stack Overflow complaint, CTO Report 2024 | ✅ Fully |
| 3 | build_runner is slow and painful — 2–5 min on large projects | 900+ GitHub thumbs on related issues | ✅ Fully |
| 4 | Wiring up DI / providers everywhere manually | Chronic onboarding complaint | ✅ Fully |
| 5 | Mental overhead of events → states → handlers | Every BLoC tutorial has a "this is a lot" moment | ✅ Fully |
| 6 | Golden tests break constantly across OS/CI | Chronic CI/CD complaint | 〜 Partially |
| 7 | l10n / i18n workflow is clunky | Dev.to, GitHub issues, ongoing in 2026 | 〜 Partially |
| 8 | Flutter Web SEO broken / Desktop stagnant | 43% of CTOs, Flock fork reason | ❌ Out of scope |

**Notes on partial:**
- **Golden tests**: We don't fix rendering — but because Stores have no `BuildContext` dependency, business logic is fully unit-testable without widgets, reducing reliance on golden tests.
- **l10n**: The ARB/generator tooling is out of scope, but Stores don't depend on `BuildContext`, so locale-related logic is testable with plain unit tests.

---

## 3. Competitive Landscape

### Packages Investigated

#### state_beacon (pub.dev)
- **What it is**: Reactive primitives library. `Beacon.writable()`, `Beacon.future()`, `Beacon.derived()`.
- **Category**: Fine-grained reactivity (like MobX), NOT structured state management.
- **Gaps**: No store concept, no lifecycle scoping, no DI, no effects system, no architecture opinion.
- **Verdict**: Different category. Not a competitor. We complement each other.

#### signals (pub.dev)
- **What it is**: Port of Preact Signals to Dart. `Signal<T>`, `Computed<T>`, `Effect`.
- **Category**: Fine-grained reactive primitives, NOT structured state management.
- **Gaps**: Requires `SignalsMixin` on StatefulWidget. No store abstraction. No scoping story.
- **Verdict**: Different category. Not a competitor. Can be used alongside StateForge.

#### Riverpod 3.0 (2026 standard)
- **Strengths**: Compile-time safety, offline persistence (new in 3.0), smart rebuilds, no ProviderNotFound exceptions.
- **Gaps**: Codegen now almost mandatory (`@riverpod` annotations + build_runner). `ref` object is confusing. Provider explosion as apps grow. Offline persistence adds complexity most apps don't need.
- **Boilerplate rating**: Low *with* code gen — codegen is the price.
- **Verdict**: Our closest competitor for new projects. We win on zero-codegen simplicity.

#### BLoC 9.0 (enterprise standard)
- **Strengths**: Event-driven audit trails, strict separation of concerns, battle-tested at scale, excellent for regulated industries.
- **Gaps**: 6 files minimum per feature. The community literally says "accept the boilerplate as the cost of predictability." Events → handlers indirection is exhausting.
- **Boilerplate rating**: High. Acknowledged by the BLoC team themselves.
- **Verdict**: Direct replacement for non-regulated teams. Same predictability, zero ceremony.

#### GetX (declining)
- **Strengths**: Low ceremony, fast to prototype, batteries included.
- **Critical problems**: Maintenance crisis (single maintainer, GetX 5.0 stuck in RC since 2023), global singleton chaos, untestable in practice, custom navigation conflicts with ecosystem packages.
- **2026 verdict**: The Foresight Mobile article (Jan 2026, 9 years / 50+ Flutter apps experience) explicitly says "avoid GetX for new professional projects."
- **Opportunity**: 800,000+ GetX-dependent projects need to migrate. They're used to low ceremony and will refuse BLoC boilerplate. StateForge is their natural target.

#### Mason CLI
- **What it is**: Template-based file generator (mustache syntax).
- **Gaps**: Dumb string substitution — knows nothing about your actual codebase. Every team writes and maintains their own bricks. Quickly diverges across projects.
- **Verdict**: Not a competitor. StateForge is a runtime library, not a generator.

#### Cubit (part of BLoC package)
- **What it is**: Simplified BLoC — removes event layer, direct method calls emit states.
- **Gaps**: Still requires BlocProvider/BlocBuilder. Still needs bloc_test for testing. No built-in effects stream, no lifecycle management, no optimistic updates, no scoping story.
- **Verdict**: Closest in concept to StateForge. We are what Cubit wished it was.

---

## 4. Why StateForge — The Gap Nobody Has Filled

The 2026 Flutter state management world presents developers with a false choice:

> **"Accept codegen (Riverpod) or accept boilerplate (BLoC)."**

StateForge proves this is a false tradeoff. The design goal:

**Structured + Testable + Zero Codegen + Zero Ceremony + Scales from solo to enterprise**

No existing library hits all five simultaneously:

| Library | Structured | Testable | Zero Codegen | Zero Ceremony | Scales |
|---|---|---|---|---|---|
| BLoC 9.0 | ✅ | ✅ | ❌ (freezed) | ❌ | ✅ |
| Riverpod 3.0 | ✅ | ✅ | ❌ (@riverpod) | ❌ | ✅ |
| GetX | ❌ | ❌ | ✅ | ✅ | ❌ |
| Cubit | ✅ | ✅ | ❌ | 〜 | 〜 |
| **StateForge** | ✅ | ✅ | ✅ | ✅ | ✅ |

---

## 5. Core Philosophy & Design Constraints

### The Developer Contract
> "One store file per feature. Zero code generation. Full testability. Direct method calls."

### Hard Design Constraints (non-negotiable)
1. **Zero code generation** — no build_runner, no annotations that require a generator, no waiting
2. **Zero third-party runtime dependencies** — only Flutter SDK itself
3. **One file per feature** (minimum viable) — store + state can live together in one file
4. **Plain unit tests** — stores testable with zero Flutter widget pumping
5. **No GetX-style chaos** — structure is enforced by design, not documentation

### Design Priorities (ranked by developer input)
1. Minimal files / zero ceremony
2. No code generation at all
3. Still testable and structured (not GetX-style chaos)
4. Works beautifully with AI tools and autocomplete

### Target Developer
Everyone — solo devs building fast, mid-size teams that need structure without ceremony, enterprise teams migrating away from BLoC or GetX. The API should be approachable on day one and scale to large codebases.

---

## 6. Name Decision

**Package name: `state_forge`**

**Rationale:**
- "Forge" implies crafting something durable and intentional — not just managing
- Technically accurate: you forge state transitions
- Memorable and unique on pub.dev
- `state_beacon` already exists (different library, reactive primitives)
- `signals` already exists (Preact Signals port)
- `arc_state` was considered — clean but less evocative
- `RapidState` (original idea) sounds like a code generator, not a library

**Pub.dev package name**: `state_forge`
**Import**: `import 'package:state_forge/state_forge.dart';`

---

## 7. Internal Architecture Decisions

### Q1: What powers state changes internally?

**Decision: pure Dart `Store` listeners + Flutter `InheritedModel` adapter**

**Why:**
- The core `Store` has no Flutter dependency and can run in CLI, server, or test packages.
- The Flutter package adapts stores into the widget tree with `InheritedModel`.
- Store lookup remains O(1) from descendant widgets.
- State notifications remain listener-based and avoid `StreamBuilder` widget overhead.
- `emit()` still coalesces repeated updates per microtask, while `emitSync()` notifies immediately.

**Rejected alternatives:**
- `Stream` as the primary state channel — async overhead and `StreamBuilder` required
- `ValueNotifier` — Flutter-bound and only holds one value, not suitable for complex state
- `ChangeNotifier` as the store base — Flutter-bound, preventing pure Dart reuse
- Custom reactive graph — overkill for store-level state (signals/beacon use this for primitives — correct for their use case, wrong for ours)

```dart
// Internal — developers never see this
abstract class Store<S> {
  S _state;
  S get state => _state;
  bool _disposed = false;
  final _listeners = <void Function()>[];

  @protected
  void emit(S newState) {
    if (_disposed) return;       // async-safety: swallow after dispose
    if (newState == _state) return; // no-op if state identical
    _state = newState;
    scheduleMicrotask(notifyListeners); // coalesced async notification
  }
}

// InheritedModel scope — created by StoreProvider, invisible to dev
class StoreScope<T extends Store> extends InheritedModel<Object> {
  const StoreScope({required this.store, required super.child});

  final T store;
}
```

### Q2: How does widget tree integration work?

**Decision: Dart 3 extension methods on `BuildContext`**

Two extension methods:
- `context.forge<T>()` — subscribes to rebuilds (use in `build()`)
- `context.forgeRead<T>()` — reads without subscribing (use in callbacks/async)

```dart
extension ForgeContext on BuildContext {
  // Subscribes — triggers rebuild on state change
  T forge<T extends Store>() {
    final scope = dependOnInheritedWidgetOfExactType<_StoreScope<T>>();
    assert(scope != null, 'No StoreProvider<$T> found above this widget');
    return scope!.notifier!;
  }

  // Read-only — no rebuild subscription. Safe for callbacks and async.
  T forgeRead<T extends Store>() =>
    getInheritedWidgetOfExactType<_StoreScope<T>>()!.notifier!;
}
```

### Q3: Selective rebuilds

**Decision: `ForgeSelector` with Dart Records for multi-field selection**

- `ForgeSelector` stores the previous selected value
- On each notify, runs `select(state)` and compares with `==`
- For Dart Records: `==` is structural by default — no `operator==` override needed
- For custom objects: developers opt into `Equatable` or implement `==` themselves
- **Never override `==` on the Store itself** — Flutter docs explicitly warn this causes O(N²) behavior

### Q4: Why not Streams for effects?

Effects use a `StreamController.broadcast()` internally — but this is hidden from the developer. `ForgeListener` subscribes and auto-cancels on dispose. The developer just calls `effect(MyEffect())` from their store method. The stream is an implementation detail, not part of the public API.

---

## 8. Complete Public API Surface

Every class and method a developer will ever touch:

| Name | Type | Purpose |
|---|---|---|
| `Store<S>` | Abstract class | Extend this. Has `emit()`, `effect()`, `guard()`, `keep()` |
| `StoreProvider<T>` | Widget | Provides + scopes a store. Auto-disposes on unmount |
| `StoreProvider.value` | Widget | Share an existing store instance with a subtree |
| `StoreWidget<T, S>` | Abstract widget | Extend instead of StatelessWidget. Gets store + state in `build()` |
| `ForgeBuilder<T, S>` | Widget | Inline builder — use when not extending StoreWidget |
| `ForgeListener<T, E>` | Widget | Listens to effects only. Never triggers rebuilds |
| `ForgeSelector<T, S, R>` | Widget | Rebuild only when `select(state)` result changes |
| `ForgeConsumer<T, S, E>` | Widget | Builder + Listener combined (like BlocConsumer) |
| `context.forge<T>()` | Extension | Get store + subscribe to rebuilds |
| `context.forgeRead<T>()` | Extension | Get store without subscribing (for callbacks) |
| `StateForge.onError` | Static setter | Global error handler hook (wire to Sentry/Crashlytics) |
| `UndoableStore<S>` | Mixin | Adds `undo()`, `redo()`, `canUndo`, `canRedo` to any Store |
| `PersistableStore<S>` | Mixin | Adds `fromJson`/`toJson` persistence hooks |

### Store Base Class — Full Method Surface

```dart
abstract class Store<S> {
  Store(S initialState) : _state = initialState;

  S _state;
  bool _disposed = false;
  final _subs = <StreamSubscription>[];
  final _effectController = StreamController<dynamic>.broadcast();

  /// Current state — readable from anywhere
  S get state => _state;

  /// Emit a new state — the only way to update UI
  @protected
  void emit(S newState) { ... }

  /// Fire a side effect (navigation, snackbar, analytics)
  @protected
  void effect<E>(E event) => _effectController.add(event);

  /// Guard an async future — auto-swallows if store disposed mid-flight
  @protected
  Future<T?> guard<T>(Future<T> future) async { ... }

  /// Register a StreamSubscription — auto-cancelled on dispose
  @protected
  void keep(StreamSubscription sub) => _subs.add(sub);

  @override
  void dispose() {
    _disposed = true;
    for (final sub in _subs) sub.cancel();
    _effectController.close();
    super.dispose();
  }
}
```

---

## 9. State Design — Two Patterns

### Pattern A: Sealed Variants (recommended for most features)

Best for: Authentication, async data loading, multi-step flows, any feature with clearly distinct states.

**Why sealed classes over freezed:**
- Dart 3 `sealed` keyword provides compile-time exhaustive switching natively
- The compiler errors if you forget to handle a variant in a `switch` — same guarantee freezed gave you, zero codegen
- Minimum Dart SDK: 3.0.0

```dart
// auth_state.dart
sealed class AuthState {}

class AuthIdle    extends AuthState { const AuthIdle(); }
class AuthLoading extends AuthState { const AuthLoading(); }
class AuthSuccess extends AuthState {
  const AuthSuccess(this.user);
  final User user;
}
class AuthFailure extends AuthState {
  const AuthFailure(this.message);
  final String message;
}
```

```dart
// In widget — compiler enforces all cases are handled
return switch (state) {
  AuthIdle()    => const LoginForm(),
  AuthLoading() => const CircularProgressIndicator(),
  AuthSuccess(:final user) => WelcomeScreen(user: user),
  AuthFailure(:final message) => ErrorView(message: message),
};
```

### Pattern B: Data State with Named Transition Methods (for complex forms, settings, profiles)

Best for: Profile editing, checkout flows, settings screens — anywhere you have many fields that update independently.

**Why named transition methods over `copyWith`:**
- `state.loading()` communicates WHY the state changes, not just what changed
- More readable in code review: `emit(state.withAvatar(bytes))` vs `emit(state.copyWith(avatar: bytes))`
- Self-documenting — the method names become your state transition vocabulary
- `copyWith` is still supported — just write it manually (8 lines, once per state class)

```dart
// profile_state.dart
class ProfileState {
  const ProfileState({
    this.name = '',
    this.email = '',
    this.avatar,
    this.isLoading = false,
    this.error,
  });

  final String name;
  final String email;
  final Uint8List? avatar;
  final bool isLoading;
  final String? error;

  // Named transitions — self-documenting
  ProfileState loading() =>
    ProfileState(name: name, email: email, avatar: avatar, isLoading: true);

  ProfileState withName(String n) =>
    ProfileState(name: n, email: email, avatar: avatar);

  ProfileState withEmail(String e) =>
    ProfileState(name: name, email: e, avatar: avatar);

  ProfileState withAvatar(Uint8List bytes) =>
    ProfileState(name: name, email: email, avatar: bytes);

  ProfileState withError(String e) =>
    ProfileState(name: name, email: email, avatar: avatar, error: e);

  ProfileState saved() =>
    ProfileState(name: name, email: email, avatar: avatar);

  // Optional: traditional copyWith for teams that prefer it
  ProfileState copyWith({String? name, String? email, bool? isLoading, String? error}) =>
    ProfileState(
      name: name ?? this.name,
      email: email ?? this.email,
      avatar: avatar,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
}
```

### When to Use Which Pattern

| Scenario | Use Pattern |
|---|---|
| Login, signup, auth flows | A — Sealed (Idle/Loading/Success/Failure) |
| Data fetching screens | A — Sealed (Empty/Loading/Loaded/Error) |
| Profile editing | B — Data state with transitions |
| Multi-field forms | B — Data state with transitions |
| Settings / preferences | B — Data state with transitions |
| Checkout wizard | A or B depending on complexity |
| Global app state (cart, theme) | B — Data state with transitions |

---

## 10. Scoping Model — Four Store Lifetimes

One of StateForge's key differentiators: explicit, predictable scoping with four clear tiers.

### Screen-Scoped (most common)
- Created when the widget is inserted into the tree
- **Auto-disposed when the route pops** — no manual cleanup
- Use for: login forms, detail pages, wizard steps, any screen-specific state

```dart
// Auto-disposes when LoginPage leaves the widget tree
StoreProvider<LoginStore>(
  create: (_) => LoginStore(repo: AuthRepository()),
  child: const LoginPage(),
)
```

### Global (app-lifetime)
- Placed at MaterialApp level
- Lives for the entire app session
- Survives navigation — route pushes/pops don't affect it
- Use for: auth, cart, user profile, theme, feature flags

```dart
// At app root — never disposed
StoreProvider<AuthStore>(
  create: (_) => AuthStore(repo: AuthRepository()),
  child: MaterialApp(home: const HomePage()),
)
```

### Shared (pass existing instance)
- Pass an already-created store instance to a subtree
- Owner controls lifecycle
- Use for: multi-step wizards where all steps share one store, sibling tabs

```dart
// Wizard: all 3 steps read the same CheckoutStore instance
StoreProvider<CheckoutStore>.value(
  store: existingCheckoutStore,
  child: StepThreePage(),
)
```

### Lazy (created on first access)
- Store created only when first accessed via `context.forge<T>()`
- Cached until the providing widget is disposed
- Use for: heavy stores (maps, large data), conditional features, rarely-visited screens

```dart
LazyStoreProvider<MapStore>(
  create: (_) => MapStore(), // not created until first context.forge<MapStore>()
  child: MapSection(),
)
```

---

## 11. Effects System

Effects solve a specific problem: **how do you trigger side effects (navigation, snackbars, analytics) from a store without rebuilding the UI?**

### The Problem Effects Solve

State drives UI structure. But some things need to "happen once" and not be reflected in state:
- Navigate to a new screen after login
- Show a snackbar on error
- Log an analytics event
- Trigger a haptic feedback

Putting these in state causes problems (how do you clear "show snackbar" state? How do you prevent re-triggering on rebuild?).

### The Solution

Effects are a separate, fire-and-forget stream alongside state:

```dart
// Define effect types as a sealed class
sealed class AuthEffect {}
class NavigateToHome extends AuthEffect {
  const NavigateToHome(this.user);
  final User user;
}
class ShowLoginError extends AuthEffect {
  const ShowLoginError(this.message);
  final String message;
}

// In your store — fire effects alongside state changes
class AuthStore extends Store<AuthState> {
  AuthStore({required this.repo}) : super(const AuthIdle());
  final AuthRepository repo;

  Future<void> login(String email, String password) async {
    emit(const AuthLoading());
    try {
      final user = await guard(repo.login(email, password));
      if (user == null) return; // guard returns null if store disposed
      emit(AuthSuccess(user));
      effect(NavigateToHome(user)); // ← fire-and-forget, no rebuild
    } catch (e) {
      emit(AuthFailure(e.toString()));
      effect(ShowLoginError(e.toString())); // ← fire-and-forget
    }
  }
}

// In your widget — ForgeListener reacts without triggering rebuild
ForgeListener<AuthStore, AuthEffect>(
  onEffect: (context, eff) => switch (eff) {
    NavigateToHome(:final user) => context.go('/home', extra: user),
    ShowLoginError(:final message) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      ),
  },
  child: const LoginForm(),
)
```

### Effect Rules
- Effects are broadcast — multiple listeners can react to the same effect
- Effects are NOT replayed — a new `ForgeListener` does not receive past effects
- `ForgeListener` auto-cancels its subscription on dispose (no memory leaks)
- Effects do not require a generic type parameter if the store fires no effects

---

## 12. Edge Cases & Solutions

Every hard problem solved at the framework level — not left to the developer.

### 1. Async operations after widget dispose (crash prevention)
**Problem:** Store fires a `Future`, widget pops, `Future` completes and calls `emit()` on disposed store.

**Solution:** `_disposed` flag in Store base class. `emit()` after dispose silently no-ops. In debug mode: prints a dev warning. `guard()` method auto-handles this for futures.

```dart
// Developer wraps their async call in guard()
final user = await guard(repo.login(email, password));
if (user == null) return; // store was disposed mid-flight
```

### 2. Stream subscriptions that outlive the widget (memory leaks)
**Problem:** `StreamSubscription` inside a store not cancelled on dispose → memory leak.

**Solution:** `keep()` method. All registered subscriptions auto-cancelled in base class `dispose()`.

```dart
@override
void onInit() {
  keep(
    repo.userStream.listen((user) => emit(state.withUser(user)))
  ); // auto-cancelled when store disposes
}
```

### 3. Unnecessary widget rebuilds (performance)
**Problem:** Global stores cause every listener to rebuild even when irrelevant data changes.

**Solution:** `ForgeSelector` — pick a slice of state, only rebuild when that slice changes.

```dart
// Only rebuilds when user.name changes
ForgeSelector<ProfileStore, ProfileState, String>(
  select: (state) => state.user.name,
  builder: (context, name, store) => Text(name),
)

// Multi-field via Dart Records (structural equality for free)
ForgeSelector<CartStore, CartState, (int, double)>(
  select: (state) => (state.itemCount, state.total),
  builder: (context, record, store) {
    final (count, total) = record;
    return CartBadge(count: count, total: total);
  },
)
```

### 4. Cross-store dependencies (without tight coupling)
**Problem:** `CartStore` needs to read `AuthStore` — how without global singletons?

**Solution:** Constructor injection. Dependencies are declared at `StoreProvider` creation time.

```dart
StoreProvider<CartStore>(
  create: (context) => CartStore(
    cartRepo: CartRepository(),
    authStore: context.forgeRead<AuthStore>(), // reads parent store
  ),
  child: const CartPage(),
)
```

**Lifecycle rule:** constructor-injected store dependencies should be stable for
the lifetime of the dependent store. App-wide stores should stay mounted and
change state instead of being destroyed and recreated. If a parent store
instance must be replaced, recreate dependent stores in the same scope or use
`CompositedStore` to explicitly manage the relationship.

For intentionally replaceable dependencies, use `StoreProxyProvider`. It creates
a store from another store higher in the tree and reacts when that parent store
instance is replaced:

```dart
StoreProxyProvider<AuthStore, CartStore>(
  create: (context, auth) => CartStore(authStore: auth),
  update: (context, auth, cart) => cart.rebindAuth(auth),
  child: const CartPage(),
)
```

If `update` is omitted, StateForge disposes the old dependent store and creates a
new one from the replacement dependency.

### 5. State during navigation transitions
**Problem:** User taps back mid-async, store deactivated, in-flight result tries to update disposed store.

**Solution:** `_disposed` guard in `emit()`. Store disposed → emits silently swallowed. `guard()` returns `null` on disposed store, developer checks and returns early.

### 6. Testing without Flutter widget environment
**Problem:** BLoC tests need `bloc_test` package and complex setup. Riverpod needs `ProviderContainer`.

**Solution:** Store has no `BuildContext` dependency. Unit tests are plain
Flutter/Dart unit tests without widget pumping or provider containers.

```dart
test('login emits AuthSuccess on valid credentials', () async {
  final store = AuthStore(repo: MockAuthRepository());
  await store.login('user@example.com', 'password123');
  expect(store.state, isA<AuthSuccess>());
});

// No WidgetTester. No pumpWidget. No async frame gymnastics.
```

### 7. Hot reload behavior
- **Screen-scoped stores**: `StoreProvider` recreates the store on hot reload (StatefulWidget rebuilds). Correct behavior — screen state resets, expected during development.
- **Global stores**: Placed at `MaterialApp` level, survive hot reload because `MaterialApp`'s `StatefulWidget` persists. For a forced reset: hot restart.
- No special handling needed — Flutter's own lifecycle covers it correctly.

### 8. Error state that needs side effects (snackbar, navigation)
**Problem:** State changes rebuild widgets, but snackbars/navigation can't live in state.

**Solution:** Effects system (see Section 11). `ForgeListener` reacts to effects without rebuilding.

### 9. Optimistic updates
**Problem:** Show result immediately, revert if server fails. Normally requires careful state juggling.

**Solution:** `optimistic()` helper method on Store (Phase 2).

```dart
Future<void> likePost(String postId) async {
  await optimistic(
    state.withLike(postId),              // emit immediately
    repo.likePost(postId),               // await server
    onFailure: state.withoutLike(postId) // revert on error
  );
}
```

### 10. Undo / Redo
**Problem:** Implementing undo in BLoC/Riverpod requires manual state history management.

**Solution:** `UndoableStore` mixin. Opt in only when needed.

```dart
class DrawingStore extends Store<DrawingState> with UndoableStore<DrawingState> {
  DrawingStore() : super(const DrawingState());
  // undo(), redo(), canUndo, canRedo are automatically available
}
```

### 11. Global error handling
**Solution:** `StateForge.onError` — static hook, set once at app init.

```dart
void main() {
  StateForge.onError = (store, error, stackTrace) {
    Sentry.captureException(error, stackTrace: stackTrace);
  };
  runApp(const MyApp());
}
```

Default behavior: rethrows in debug mode, logs and swallows in release (with dev warning in debug).

---

## 13. Package File Structure

```
state_forge/
├── lib/
│   ├── state_forge.dart              ← barrel export (public API only)
│   └── src/
│       ├── store.dart                ← Store<S> base class
│       ├── store_provider.dart       ← StoreProvider widget + lazy variant
│       ├── store_widget.dart         ← StoreWidget abstract base
│       ├── forge_builder.dart        ← ForgeBuilder inline widget
│       ├── forge_listener.dart       ← ForgeListener (effects only)
│       ├── forge_selector.dart       ← ForgeSelector (partial rebuilds)
│       ├── forge_consumer.dart       ← ForgeConsumer (builder + listener)
│       ├── context_extensions.dart   ← context.forge<T>(), context.forgeRead<T>()
│       ├── state_forge_config.dart   ← StateForge.onError, debugMode
│       ├── mixins/
│       │   ├── undoable_store.dart   ← UndoableStore mixin
│       │   └── persistable_store.dart ← PersistableStore mixin
│       └── _scope.dart               ← StoreScope InheritedModel (private)
├── test/
│   ├── store_test.dart
│   ├── provider_test.dart
│   ├── selector_test.dart
│   ├── effects_test.dart
│   └── undoable_store_test.dart
├── example/
│   └── lib/
│       ├── main.dart
│       └── features/
│           ├── auth/
│           │   ├── auth_store.dart   ← Pattern A: sealed state
│           │   ├── auth_state.dart
│           │   └── auth_page.dart
│           ├── products/
│           │   ├── product_store.dart ← ForgeSelector demo
│           │   ├── product_state.dart
│           │   └── product_page.dart
│           └── cart/
│               ├── cart_store.dart   ← Pattern B + UndoableStore
│               ├── cart_state.dart
│               └── cart_page.dart
├── extension/                        ← DevTools extension (Phase 3)
│   └── devtools/
│       ├── config.yaml
│       └── build/
├── CHANGELOG.md
├── LICENSE
├── README.md
├── analysis_options.yaml
└── pubspec.yaml
```

### Export Rules
- Everything in `lib/src/` is internal — never import directly
- Only `lib/state_forge.dart` is the public surface
- `_scope.dart` (with underscore prefix) is package-private by convention

---

## 14. pubspec.yaml

```yaml
name: state_forge
description: Structured Flutter state management with typed stores, scoped rebuilds, effects, persistence, and test helpers.
version: 0.1.2
homepage: https://github.com/mj-963/state_forge
repository: https://github.com/mj-963/state_forge
issue_tracker: https://github.com/mj-963/state_forge/issues
documentation: https://github.com/mj-963/state_forge/tree/main/doc

topics:
  - flutter
  - dart
  - state-management
  - reactive
  - testing
  - reactive

environment:
  sdk: '>=3.3.0 <4.0.0'    # Dart 3.3+ for Records destructuring in patterns
  flutter: '>=3.19.0'       # Feb 2024 — stable sealed class + pattern matching

dependencies:
  flutter:
    sdk: flutter
  # Zero third-party runtime dependencies.

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  devtools_extensions: ^0.0.10   # For Phase 3 DevTools extension only
```

**Key decisions:**
- **Zero third-party runtime dependencies** — no version conflicts, no transitive dependency hell, maximum pub.dev score
- **Dart 3.3.0 minimum** — needed for record destructuring in patterns (`(int, String)` as state slices)
- **Flutter 3.19.0 minimum** — stable sealed class support and modern pattern matching

---

## 15. Developer Experience — What You Write

### Full Feature Example: Login (Pattern A — Sealed State)

```dart
// ─── auth_state.dart ───────────────────────────────────────────────
sealed class AuthState {}

class AuthIdle    extends AuthState { const AuthIdle(); }
class AuthLoading extends AuthState { const AuthLoading(); }
class AuthSuccess extends AuthState {
  const AuthSuccess(this.user);
  final User user;
}
class AuthFailure extends AuthState {
  const AuthFailure(this.message);
  final String message;
}

// ─── auth_effect.dart ──────────────────────────────────────────────
sealed class AuthEffect {}
class NavigateHome  extends AuthEffect { const NavigateHome(this.user); final User user; }
class ShowError     extends AuthEffect { const ShowError(this.message); final String message; }

// ─── auth_store.dart ───────────────────────────────────────────────
class AuthStore extends Store<AuthState> {
  AuthStore({required this.repo}) : super(const AuthIdle());
  final AuthRepository repo;

  Future<void> login(String email, String password) async {
    emit(const AuthLoading());
    try {
      final user = await guard(repo.login(email, password));
      if (user == null) return;
      emit(AuthSuccess(user));
      effect(NavigateHome(user));
    } catch (e) {
      emit(AuthFailure(e.toString()));
      effect(ShowError(e.toString()));
    }
  }

  void logout() => emit(const AuthIdle());
}

// ─── auth_page.dart ────────────────────────────────────────────────
class AuthPage extends StoreWidget<AuthStore, AuthState> {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context, AuthState state, AuthStore store) {
    return ForgeListener<AuthStore, AuthEffect>(
      onEffect: (context, eff) => switch (eff) {
        NavigateHome(:final user) => context.go('/home', extra: user),
        ShowError(:final message) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message))),
      },
      child: switch (state) {
        AuthIdle()    => LoginForm(onSubmit: store.login),
        AuthLoading() => const Center(child: CircularProgressIndicator()),
        AuthSuccess(:final user) => WelcomeScreen(user: user),
        AuthFailure(:final message) => ErrorView(message: message),
      },
    );
  }
}

// ─── In your router ────────────────────────────────────────────────
StoreProvider<AuthStore>(
  create: (_) => AuthStore(repo: AuthRepository()),
  child: const AuthPage(),
)
```

### BLoC Equivalent for Comparison

For the same login feature, BLoC requires:
- `auth_event.dart` — LoginRequested event class
- `auth_state.dart` — AuthInitial, AuthLoading, AuthSuccess, AuthFailure (with freezed)
- `auth_bloc.dart` — Bloc class with constructor + on<LoginRequested> handler
- Registration in your DI/injection file
- `BlocProvider` in widget tree
- `BlocBuilder` + `BlocListener` in UI
- `pubspec.yaml` additions: flutter_bloc, freezed, json_serializable, build_runner
- Run: `dart run build_runner build`

**StateForge: 3 files. BLoC: 6+ files + codegen step.**

---

## 16. Testing Story

One of StateForge's strongest differentiators: stores are plain classes with no
`BuildContext` dependency, so business logic is testable without widget pumping.
The core implementation lives in `state_forge_core`, so the same store logic can
also run in pure Dart packages.

```dart
// test/auth_store_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:state_forge/state_forge.dart';
import '../mocks/mock_auth_repository.dart';

void main() {
  late AuthStore store;
  late MockAuthRepository mockRepo;

  setUp(() {
    mockRepo = MockAuthRepository();
    store = AuthStore(repo: mockRepo);
  });

  tearDown(() => store.dispose());

  test('initial state is AuthIdle', () {
    expect(store.state, isA<AuthIdle>());
  });

  test('login emits AuthLoading then AuthSuccess', () async {
    final states = <AuthState>[];
    store.addListener(() => states.add(store.state));

    mockRepo.setLoginResponse(User(id: '1', name: 'Test User'));
    await store.login('test@example.com', 'password');

    expect(states[0], isA<AuthLoading>());
    expect(states[1], isA<AuthSuccess>());
    expect((states[1] as AuthSuccess).user.name, 'Test User');
  });

  test('login emits AuthFailure on error', () async {
    mockRepo.setLoginError('Invalid credentials');
    await store.login('bad@email.com', 'wrong');
    expect(store.state, isA<AuthFailure>());
    expect((store.state as AuthFailure).message, 'Invalid credentials');
  });

  test('logout resets to AuthIdle', () async {
    mockRepo.setLoginResponse(User(id: '1', name: 'Test'));
    await store.login('test@example.com', 'password');
    store.logout();
    expect(store.state, isA<AuthIdle>());
  });
}
```

**No `WidgetTester`. No `pumpWidget()`. No `pump()` calls. No async frame delays. Just Dart.**

Compare to BLoC testing which requires:
```dart
// BLoC equivalent needs bloc_test package
blocTest<AuthBloc, AuthState>(
  'emits [AuthLoading, AuthSuccess] when LoginRequested',
  build: () => AuthBloc(authRepo: MockAuthRepo()),
  act: (bloc) => bloc.add(LoginRequested(email: '...', password: '...')),
  expect: () => [AuthLoading(), AuthSuccess(...)],
);
```

---

## 17. DevTools & Debugging

### Phase 1 (ships with MVP): Debug Mode

```dart
// Add one line at app init — stripped automatically from release builds
void main() {
  assert(() {
    StateForge.debugMode = true;
    return true;
  }());
  runApp(const MyApp());
}

// Console output during development:
// [StateForge] AuthStore: AuthIdle → AuthLoading  (+0ms)
// [StateForge] AuthStore: AuthLoading → AuthSuccess(user: User{id: 1})  (+342ms)
// [StateForge] AuthStore fired effect: NavigateHome(user: User{id: 1})
// [StateForge] CartStore: CartState{items: 0} → CartState{items: 1}  (+12ms)
```

### Phase 3: Custom DevTools Extension

Built using `package:devtools_extensions`. Shipped inside the `state_forge` package itself in the `extension/devtools/` directory. Auto-appears as a new tab in Flutter DevTools when the package is a dependency.

Features:
- Live state timeline per store (visual diff of state changes)
- Effect log (what effects fired, when, from which store)
- Store lifecycle events (created, disposed, hot reloaded)
- Store dependency graph (which stores depend on which)

**How it works technically:**
- App registers service extensions via Dart VM service
- DevTools extension queries these via `ExtensionManager`
- DevTools UI is a Flutter web app embedded as iFrame in DevTools
- Zero performance cost in production — service extensions only run when DevTools requests data

---

## 18. Problem Scorecard — What We Solve

| Original Complaint | Solved? | How |
|---|---|---|
| BLoC/Riverpod ceremony — 5+ files per feature | ✅ Fully | 1 Store file per feature, direct method calls |
| No standard project structure | ✅ Fully | Store + State + Widget pattern enforced by design. Example app demonstrates canonical structure. |
| build_runner slow and painful | ✅ Fully | Zero codegen. Zero build_runner. Zero waiting. Hard design constraint. |
| Wiring up DI / providers manually | ✅ Fully | Constructor injection at StoreProvider. No separate DI file. Dependencies visible at the widget that uses them. |
| Mental overhead of events → states → handlers | ✅ Fully | Direct method calls. `store.login()` not `bloc.add(LoginRequested())`. |
| Golden tests break across OS/CI | 〜 Partially | Business logic is unit-testable without widgets, reducing golden test reliance |
| l10n workflow is clunky | 〜 Partially | Stores are context-free — locale logic testable without widget pumping |
| Flutter Web SEO / Desktop stagnation | ❌ Out of scope | Platform/engine problems — no state management library can fix these |

---

## 19. Market Positioning vs 2026 Competitors

*Based on the Foresight Mobile article (Jan 2026) by Gareth Reese, CTO — 9 years, 50+ Flutter apps for Levi's, EA, Bodybuilding.com.*

### The Core Gap We Fill

The 2026 article presents two professional options:
- **Riverpod 3.0** — "Low boilerplate (code gen)" — codegen is the price
- **BLoC 9.0** — "Accept boilerplate as the cost of predictability" — boilerplate is the price

**StateForge's position: you don't have to pay either price.**

### vs Riverpod 3.0

| | Riverpod 3.0 | StateForge |
|---|---|---|
| Code generation | Required (`@riverpod` + build_runner) | None |
| Learning curve | Medium (ref, providers, watch/read/listen) | Low (Store, emit, forge) |
| Offline persistence | Native (3.0) | PersistableStore mixin (Phase 2) |
| Effects/side effects | Lifecycle methods (awkward) | First-class `effect()` + `ForgeListener` |
| Boilerplate | Low with codegen | Zero |
| Testability | Excellent (ProviderContainer overrides) | Excellent (no widget pump, no container) |

**Who stays on Riverpod:** Teams that need native offline-first persistence at the provider level, or already have Riverpod codegen integrated into CI.

**Who moves to StateForge:** Teams who chose Riverpod to escape BLoC boilerplate but are frustrated that codegen became mandatory in 3.0.

### vs BLoC 9.0

| | BLoC 9.0 | StateForge |
|---|---|---|
| Files per feature | 6+ | 1-2 |
| Code generation | Required (freezed) | None |
| API pattern | Events → Handlers → States | Direct method calls |
| Audit trail | Explicit (every event logged) | Via debug mode + DevTools |
| Testability | Excellent (bloc_test) | Excellent (no widget pump) |
| Enterprise-scale | Industry standard | Designed to scale |

**Who stays on BLoC:** Regulated industries (banking, healthcare) where event audit trails are a compliance requirement, and large enterprise teams (50+ devs) with BLoC tooling investment.

**Who moves to StateForge:** Everyone else who found themselves saying "accept the boilerplate."

### vs Signals 6.0

Not competitors — different layers. Signals is fine-grained reactive primitives. StateForge is structured store architecture. A team can use both: Signals for surgical UI micro-updates within a widget, StateForge for feature-level business logic. We should document this combination pattern.

### vs GetX (migration target)

The article says: "avoid GetX for new professional projects." ~800,000 projects using GetX need to migrate. They're accustomed to low ceremony and will refuse BLoC boilerplate. StateForge gives them the low ceremony they're used to with the architecture they've been missing.

### The One Gap to Address Honestly

Riverpod 3.0's native offline persistence (stale-while-revalidate, automatic hydration) is a genuine differentiator for offline-first apps. Our `PersistableStore` mixin (Phase 2) covers basic persistence but won't match Riverpod's full offline caching machinery. We document this honestly: StateForge is not the right choice if offline-first data caching at the provider level is your primary requirement. For everything else, we're the better choice.

---

## 20. Example App Plan

A full e-commerce mini-app demonstrating every StateForge capability.

### Features

**1. Auth Feature (Pattern A — Sealed State)**
- Demonstrates: Sealed state variants, `ForgeListener` for navigation effects, `guard()` for async safety
- Store: `AuthStore` with `login()`, `logout()`
- State: `AuthIdle | AuthLoading | AuthSuccess | AuthFailure`
- Effects: `NavigateToHome`, `ShowLoginError`

**2. Product Catalog Feature (Performance Demo)**
- Demonstrates: `ForgeSelector` for granular rebuilds, global store access, `context.forgeRead()` in callbacks
- Store: `ProductStore` with `loadProducts()`, `setFilter()`, `setSort()`
- State: Pattern B data state (filter, sort, product list, loading, error)
- Highlight: Product list rebuilds separately from filter/sort UI via `ForgeSelector`

**3. Cart Feature (Pattern B + Mixins)**
- Demonstrates: Pattern B data state with `withX()` transitions, `UndoableStore` mixin, cross-store dependency (reads AuthStore), global scope
- Store: `CartStore` extends `Store<CartState>` with `UndoableStore<CartState>`
- State: `CartState` with items list, total, item count
- Highlight: `store.undo()` to remove last-added item — 1 mixin, zero extra code

### Example App Structure

```
example/lib/
├── main.dart                    ← App root, global store setup
├── repositories/
│   ├── auth_repository.dart
│   ├── product_repository.dart
│   └── cart_repository.dart
├── models/
│   ├── user.dart
│   ├── product.dart
│   └── cart_item.dart
└── features/
    ├── auth/
    │   ├── auth_store.dart
    │   ├── auth_state.dart
    │   ├── auth_effect.dart
    │   └── login_page.dart
    ├── products/
    │   ├── product_store.dart
    │   ├── product_state.dart
    │   └── product_page.dart
    └── cart/
        ├── cart_store.dart
        ├── cart_state.dart
        └── cart_page.dart
```

---

## 21. Build Phases

### Phase 1 — Core MVP (~2 weeks, pub.dev ready)

**What we build:**
- `Store<S>` base class with `emit()`, `effect()`, `guard()`, `keep()`, `dispose()`
- `StoreProvider<T>` widget (create + .value variants)
- `LazyStoreProvider<T>` widget
- `StoreWidget<T, S>` abstract base widget
- `ForgeBuilder<T, S>` inline builder widget
- `ForgeListener<T, E>` effects listener widget
- `ForgeSelector<T, S, R>` selective rebuild widget
- `ForgeConsumer<T, S, E>` combined builder + listener
- `context.forge<T>()` and `context.forgeRead<T>()` extensions
- `StateForge.debugMode` and `StateForge.onError`
- `StoreScope` internal `InheritedModel`
- Full unit test suite
- README with quick-start guide
- E-commerce example app (all 3 features)

**Target:** Publish to pub.dev at version `0.1.0`

### Phase 2 — Power Features (~2 weeks)

**What we build:**
- `UndoableStore<S>` mixin — `undo()`, `redo()`, `canUndo`, `canRedo`, configurable history depth
- `PersistableStore<S>` mixin — `fromJson`/`toJson` hooks, auto-hydration on init
- `optimistic()` helper method on Store — emit optimistically, revert on failure
- VS Code snippet pack (`.code-snippets` file in repo) — `forge-store`, `forge-state-sealed`, `forge-state-data`, `forge-provider`, `forge-widget`
- Migration guide from BLoC (with side-by-side code comparisons)
- Migration guide from Riverpod

**Target:** Publish at version `0.2.0`

### Phase 3 — Ecosystem (~3 weeks)

**What we build:**
- Custom DevTools extension (state timeline, effect log, store graph)
- Full documentation site
- "StateForge + Signals" combination pattern guide
- Community launch (pub.dev, Reddit r/FlutterDev, Twitter/X, Medium article)
- Blog post: "Why we built StateForge" — including the research from this document

**Target:** Publish at version `1.0.0` (stable)

---

## Quick Reference Card

```
StateForge in 30 seconds:

1. Define your store:
   class MyStore extends Store<MyState> { ... }

2. Define your state (choose one):
   sealed class MyState {}              // Pattern A: variants
   class MyState { ... }               // Pattern B: data class

3. Provide it:
   StoreProvider<MyStore>(create: (_) => MyStore(), child: ...)

4. Use it:
   context.forge<MyStore>()            // subscribe (in build)
   context.forgeRead<MyStore>()        // read only (in callbacks)

5. Selective rebuild:
   ForgeSelector(select: (s) => s.name, builder: ...)

6. Side effects:
   ForgeListener(onEffect: (ctx, eff) => ..., child: ...)

That's it. No events. No codegen. No build_runner. No ceremony.
```

---

*Document generated from planning session — April 2026*
*Ready for IDE. Start with Phase 1 core.*
