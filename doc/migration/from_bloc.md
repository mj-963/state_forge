# Migrating from BLoC to StateForge

If you are coming from BLoC or Cubit, StateForge will feel familiar in one
important way: state changes still move in one direction. The main difference is
that feature commands are direct store methods instead of dispatched events.

## Core Concepts Comparison

| BLoC Concept | StateForge Equivalent |
| :--- | :--- |
| `Bloc<Event, State>` | `Store<S>` |
| `Cubit<State>` | `Store<S>` |
| `on<Event>((event, emit) => ...)` | Standard methods: `void login() => emit(...)` |
| `BlocProvider` | `StoreProvider` |
| `BlocBuilder` | `ForgeBuilder` or `context.watch<T>()` |
| `BlocListener` | `ForgeEffectListener` or `ForgeListener` |
| `BlocSelector` | `context.select<T, S, R>()` |

## Key Differences

1. **Direct commands**: Instead of dispatching an event and handling it in an
   `on<Event>` handler, call methods directly on the store.
2. **Fewer moving parts**: Feature logic lives in store methods. State can be a
   native Dart sealed hierarchy, a data class, or `AsyncState<T>`.
3. **Effects are separate**: Use `effect()` for one-time signals such as
   navigation or snackbars.

## Side-by-Side Example

### BLoC
```dart
// Event
class LoginRequested extends LoginEvent { ... }

// Bloc
class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc() : super(LoginInitial()) {
    on<LoginRequested>((event, emit) async {
      emit(LoginLoading());
      final user = await repo.login(event.email, event.password);
      emit(LoginSuccess(user));
    });
  }
}

// UI
context.read<LoginBloc>().add(LoginRequested(email, password));
```

### StateForge (Direct)
```dart
// Store
class LoginStore extends Store<AsyncState<User>> {
  LoginStore() : super(const Idle());

  Future<void> login(String email, String password) async {
    emit(const Loading());
    final user = await repo.login(email, password);
    emit(Success(user));
  }
}

// UI
context.read<LoginStore>().login(email, password);
```

## Summary
StateForge is useful when you like predictable state transitions but want direct
feature methods instead of an event pipeline.
