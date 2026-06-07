import 'store.dart';

/// An abstract class for observing the lifecycle, state transitions,
/// and side effects of all [Store]s globally.
///
/// You can either extend this class or use the default constructor
/// to provide inline callbacks.
class ForgeObserver {
  /// Creates a [ForgeObserver] with optional callbacks.
  ForgeObserver({
    void Function(Store store)? onCreate,
    void Function(Store store)? onDispose,
    void Function(Store store, Object? oldState, Object? newState)? onEmit,
    void Function(Store store, Object effect)? onEffect,
    void Function(Store store, Object error, StackTrace stackTrace)? onError,
  })  : _onCreate = onCreate,
        _onDispose = onDispose,
        _onEmit = onEmit,
        _onEffect = onEffect,
        _onError = onError;

  final void Function(Store store)? _onCreate;
  final void Function(Store store)? _onDispose;
  final void Function(Store store, Object? oldState, Object? newState)? _onEmit;
  final void Function(Store store, Object effect)? _onEffect;
  final void Function(Store store, Object error, StackTrace stackTrace)?
      _onError;

  /// Hook for store creation.
  void handleCreate(Store store) => _onCreate?.call(store);

  /// Hook for store disposal.
  void handleDispose(Store store) => _onDispose?.call(store);

  /// Hook for state transitions.
  void handleEmit(Store store, Object? oldState, Object? newState) =>
      _onEmit?.call(store, oldState, newState);

  /// Hook for side effects.
  void handleEffect(Store store, Object effect) =>
      _onEffect?.call(store, effect);

  /// Hook for errors.
  void handleError(Store store, Object error, StackTrace stackTrace) =>
      _onError?.call(store, error, stackTrace);
}
