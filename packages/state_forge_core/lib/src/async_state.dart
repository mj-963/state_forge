import 'package:meta/meta.dart';

/// A universal sealed class for representing asynchronous states.
///
/// Eliminates the need to manually define Idle, Loading, Success, and Failure
/// classes for standard feature stores.
@immutable
sealed class AsyncState<T> {
  /// Base constructor for all [AsyncState] variants.
  const AsyncState();

  /// Whether the state is [Idle].
  bool get isIdle => this is Idle<T>;

  /// Whether the state is [Loading].
  bool get isLoading => this is Loading<T>;

  /// Whether the state is [Success].
  bool get isSuccess => this is Success<T>;

  /// Whether the state is [Failure].
  bool get isFailure => this is Failure<T>;

  /// Returns the data if the state is [Success], otherwise returns null.
  T? get data {
    final self = this;
    return self is Success<T> ? self.value : null;
  }

  /// Returns the error if the state is [Failure], otherwise returns null.
  Object? get error {
    final self = this;
    return self is Failure<T> ? self.e : null;
  }

  /// Functional pattern matching to handle all [AsyncState] cases.
  R when<R>({
    required R Function() idle,
    required R Function() loading,
    required R Function(T data) success,
    required R Function(Object error) failure,
  }) {
    return switch (this) {
      Idle<T>() => idle(),
      Loading<T>() => loading(),
      Success<T>(:final value) => success(value),
      Failure<T>(:final e) => failure(e),
    };
  }

  /// Functional pattern matching with a mandatory [orElse] fallback.
  R maybeWhen<R>({
    R Function()? idle,
    R Function()? loading,
    R Function(T data)? success,
    R Function(Object error)? failure,
    required R Function() orElse,
  }) {
    return when(
      idle: idle ?? orElse,
      loading: loading ?? orElse,
      success: success ?? (_) => orElse(),
      failure: failure ?? (_) => orElse(),
    );
  }

  /// Maps the state to a new type based on its current variant.
  R map<R>({
    required R Function(Idle<T> idle) idle,
    required R Function(Loading<T> loading) loading,
    required R Function(Success<T> success) success,
    required R Function(Failure<T> failure) failure,
  }) {
    final self = this;
    if (self is Idle<T>) return idle(self);
    if (self is Loading<T>) return loading(self);
    if (self is Success<T>) return success(self);
    if (self is Failure<T>) return failure(self);
    throw StateError('Unknown AsyncState variant');
  }

  /// Maps the state with a mandatory [orElse] fallback.
  R maybeMap<R>({
    R Function(Idle<T> idle)? idle,
    R Function(Loading<T> loading)? loading,
    R Function(Success<T> success)? success,
    R Function(Failure<T> failure)? failure,
    required R Function() orElse,
  }) {
    return map(
      idle: idle ?? (_) => orElse(),
      loading: loading ?? (_) => orElse(),
      success: success ?? (_) => orElse(),
      failure: failure ?? (_) => orElse(),
    );
  }
}

/// The initial state before any action has been taken.
final class Idle<T> extends AsyncState<T> {
  /// Const constructor for the [Idle] state.
  const Idle();
}

/// The state when an asynchronous action is in progress.
final class Loading<T> extends AsyncState<T> {
  /// Const constructor for the [Loading] state.
  const Loading();
}

/// The state when an asynchronous action has completed successfully.
final class Success<T> extends AsyncState<T> {
  /// Creates a [Success] state containing the provided [value].
  const Success(this.value);

  /// The resulting data of the successful action.
  final T value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success<T> &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;
}

/// The state when an asynchronous action has failed.
final class Failure<T> extends AsyncState<T> {
  /// Creates a [Failure] state containing the error [e].
  const Failure(this.e);

  /// The error object encountered during the action.
  final Object e;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure<T> && runtimeType == other.runtimeType && e == other.e;

  @override
  int get hashCode => e.hashCode;
}
