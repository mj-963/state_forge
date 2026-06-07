# Migrating from BLoC to StateForge

StateForge is often described as "what Cubit wished it was." If you are coming from BLoC, you'll find the architecture familiar but the ceremony significantly reduced.

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

1.  **No Events**: Instead of dispatching an event and handling it in an `on<Event>` handler, you call methods directly on the Store.
2.  **No Indirection**: You don't need a separate file for events. Logic lives in the Store methods.
3.  **No Codegen**: While BLoC often uses `freezed` for states, StateForge uses native Dart 3 sealed classes or the built-in `AsyncState`.

## Side-by-Side Example

### BLoC (with Indirection)
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
StateForge gives you the same predictable, one-way data flow as BLoC but removes 50% of the files and 100% of the code generation.