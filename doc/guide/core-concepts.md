# Core Concepts 🏗️

StateForge is built on a single, powerful premise: **The Store is the entire state layer for a feature.** 

Unlike libraries that treat state as a collection of variables, StateForge enforces an architecture where logic, state, and side effects are encapsulated in a single, self-contained unit.

## 1. The Store (`Store<S>`)
The `Store` is the brain of your feature. It is a plain class with no `BuildContext` dependency that manages a single state object and serves as the only point of entry for modifying that state.

### Basic Implementation
```dart
class CounterStore extends Store<int> {
  CounterStore() : super(0);

  void increment() => emit(state + 1);
}
```

### Key Store Methods:
- **`emit(S newState)`**: The standard way to update state. Updates are coalesced per microtask to prevent redundant UI rebuilds.
- **`emitSync(S newState)`**: Updates state and notifies the UI immediately. Use this for frame-perfect logic (animations, drawing).
- **`guard(Future<T> Function() action)`**: Safely runs an async function. It catches errors and pipes them to the global `onError` handler.
- **`keep(T resource)`**: Registers a resource (Timer, StreamSubscription, etc.) to be auto-disposed when the store is destroyed.

---

## 2. AsyncState: The Boilerplate Killer
Most features deal with loading data. Instead of writing your own `Loading`, `Success`, and `Error` classes every time, use the built-in `AsyncState<T>`.

```dart
class UserStore extends Store<AsyncState<User>> {
  UserStore(this.api) : super(const Idle());
  final UserApi api;

  Future<void> load(int id) async {
    emit(const Loading());
    await guard(() async {
      final user = await api.fetchUser(id);
      emit(Success(user));
    });
  }
}
```

### Pattern Matching in the UI
```dart
state.when(
  idle: () => const Text('Ready'),
  loading: () => const CircularProgressIndicator(),
  success: (user) => Text('Hello ${user.name}'),
  failure: (e) => Text('Error: $e'),
)
```

---

## 3. Pattern A vs. Pattern B
StateForge supports two distinct ways to design your state.

### Pattern A: Sealed Variants (Recommended)
Best for features with mutually exclusive states (e.g., Auth, Loading).
```dart
sealed class AuthState {}
class AuthIdle extends AuthState {}
class AuthSuccess extends AuthState { final User user; AuthSuccess(this.user); }
```
**Benefit**: The compiler ensures you handle every case in your `switch` or `.when()`.

### Pattern B: Data Class
Best for complex forms or settings where many fields update independently.
```dart
class ProfileState {
  final String name;
  final bool isEditing;
  const ProfileState({this.name = '', this.isEditing = false});

  // Use named transitions for better readability
  ProfileState withName(String n) => ProfileState(name: n, isEditing: isEditing);
  ProfileState toggleEdit() => ProfileState(name: name, isEditing: !isEditing);
}
```
**Benefit**: Extremely readable state transitions without the magic of `copyWith`.
