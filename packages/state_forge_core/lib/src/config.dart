import 'forge_observer.dart';
import 'store.dart';

/// Storage contract used by [PersistableStore].
abstract interface class ForgeStorageAdapter {
  /// Reads persisted JSON data for [key].
  Future<Map<String, dynamic>?> read(String key);

  /// Writes JSON data for [key].
  Future<void> write(String key, Map<String, dynamic> data);

  /// Deletes persisted data for [key].
  Future<void> delete(String key);
}

/// Diagnostics hooks used by platform adapters such as the Flutter package.
abstract interface class StateForgeDiagnostics {
  /// Initializes diagnostics integrations.
  void init();

  /// Called when a store is created.
  void registerStore(Store store);

  /// Called when a store is disposed.
  void unregisterStore(Store store);

  /// Records a state transition.
  void recordTransition(Store store, Object? oldState, Object? newState);

  /// Records a side effect.
  void recordEffect(Store store, Object effect);
}

/// Global configuration and hooks for the StateForge library.
class StateForge {
  StateForge._();

  /// Whether to print every state transition and effect to the console.
  ///
  /// Off by default: it is useful while debugging one feature, but as a default
  /// it floods test output and costs a `toString()` of every state on every
  /// emit. Turn it on when you want it, and only where you want it:
  ///
  /// ```dart
  /// void main() {
  ///   StateForge.debugMode = true;
  ///   runApp(const MyApp());
  /// }
  /// ```
  ///
  /// Printing is additionally guarded by an assertion, so enabling this in a
  /// release build still prints nothing.
  static bool debugMode = false;

  /// Global error handler hook.
  ///
  /// Assign a function here to capture every error thrown during
  /// a store's [Store.guard] call. Perfect for Sentry or Crashlytics integration.
  static void Function(Object error, StackTrace stackTrace)? onError;

  /// Global observer for monitoring store lifecycles and transitions.
  ///
  /// Implement [ForgeObserver] to create custom audit trails or
  /// analytics pipelines.
  static ForgeObserver? observer;

  /// Optional global storage adapter used by [PersistableStore].
  static ForgeStorageAdapter? storage;

  /// Optional diagnostics adapter used by platform packages.
  static StateForgeDiagnostics? diagnostics;

  /// Initializes optional StateForge platform integrations.
  static void init() {
    diagnostics?.init();
  }
}
