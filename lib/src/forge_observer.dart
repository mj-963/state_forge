import 'package:state_forge_core/state_forge_core.dart' as core;

import 'store.dart';

/// An abstract class for observing the lifecycle, state transitions,
/// and side effects of all [Store]s globally.
class ForgeObserver extends core.ForgeObserver {
  /// Creates a [ForgeObserver] with optional callbacks.
  ForgeObserver({
    this.onCreate,
    this.onDispose,
    this.onEmit,
    this.onEffect,
    this.onError,
  });

  /// Called when a [Store] is first instantiated.
  final void Function(Store store)? onCreate;

  /// Called when a [Store] is disposed.
  final void Function(Store store)? onDispose;

  /// Called whenever a [Store] transitions from [oldState] to [newState].
  final void Function(Store store, Object? oldState, Object? newState)? onEmit;

  /// Called whenever a [Store] fires a side [effect].
  final void Function(Store store, Object effect)? onEffect;

  /// Called when a [Store] encounters an [error] during an async [Store.guard].
  final void Function(Store store, Object error, StackTrace stackTrace)?
      onError;

  /// Hook for store creation.
  @override
  void handleCreate(covariant Store store) => onCreate?.call(store);

  /// Hook for store disposal.
  @override
  void handleDispose(covariant Store store) => onDispose?.call(store);

  /// Hook for state transitions.
  @override
  void handleEmit(
    covariant Store store,
    Object? oldState,
    Object? newState,
  ) =>
      onEmit?.call(store, oldState, newState);

  /// Hook for side effects.
  @override
  void handleEffect(covariant Store store, Object effect) =>
      onEffect?.call(store, effect);

  /// Hook for errors.
  @override
  void handleError(
    covariant Store store,
    Object error,
    StackTrace stackTrace,
  ) =>
      onError?.call(store, error, stackTrace);
}
