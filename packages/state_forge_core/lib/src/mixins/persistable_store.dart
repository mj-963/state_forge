import 'dart:async';

import '../config.dart';
import '../store.dart';

/// A mixin that defines a contract for state persistence in a [Store].
mixin PersistableStore<S> on Store<S> {
  /// The unique key used to identify this store's data in storage.
  String get storageKey;

  /// Serializes the current state into a JSON-encodable [Map].
  Map<String, dynamic> toJson(S state);

  /// Deserializes a JSON [Map] into a new state instance.
  S fromJson(Map<String, dynamic> json);

  /// Asynchronously loads and restores the state from storage.
  Future<void> hydrate([
    Future<Map<String, dynamic>?> Function(String key)? fetch,
  ]) async {
    final reader = fetch ?? StateForge.storage?.read;
    if (reader == null) {
      throw StateError(
        'No StateForge.storage adapter configured for $runtimeType.hydrate().',
      );
    }

    final data = await reader(storageKey);
    if (data != null) {
      try {
        final state = fromJson(data);
        emit(state);
      } catch (e, stack) {
        if (StateForge.onError != null) {
          StateForge.onError!(e, stack);
        }
      }
    }
  }

  /// Triggers the persistence logic.
  Future<void> persist([
    Future<void> Function(String key, Map<String, dynamic> data)? save,
  ]) async {
    final writer = save ?? StateForge.storage?.write;
    if (writer == null) {
      throw StateError(
        'No StateForge.storage adapter configured for $runtimeType.persist().',
      );
    }

    final data = toJson(state);
    await writer(storageKey, data);
  }

  /// Deletes this store's persisted data.
  Future<void> clearPersisted([
    Future<void> Function(String key)? delete,
  ]) async {
    final remover = delete ?? StateForge.storage?.delete;
    if (remover == null) {
      throw StateError(
        'No StateForge.storage adapter configured for '
        '$runtimeType.clearPersisted().',
      );
    }

    await remover(storageKey);
  }

  /// Hydrates this store and then enables automatic persistence.
  Future<void> hydrateOnCreate({
    bool persistChanges = true,
    Duration? debounce,
    bool persistInitialState = false,
    Future<Map<String, dynamic>?> Function(String key)? fetch,
    Future<void> Function(String key, Map<String, dynamic> data)? save,
    void Function(Object error, StackTrace stackTrace)? onError,
    bool rethrowErrors = false,
  }) async {
    try {
      await hydrate(fetch);

      await Future<void>.delayed(Duration.zero);

      if (isDisposed || !persistChanges) return;

      persistOnChange(
        debounce: debounce,
        persistInitialState: persistInitialState,
        save: save,
        onError: onError,
      );
    } catch (error, stackTrace) {
      _reportPersistenceError(error, stackTrace, onError);
      if (rethrowErrors) {
        Error.throwWithStackTrace(error, stackTrace);
      }
    }
  }

  /// Persists state automatically whenever this store notifies listeners.
  void persistOnChange({
    Duration? debounce,
    bool persistInitialState = false,
    Future<void> Function(String key, Map<String, dynamic> data)? save,
    void Function(Object error, StackTrace stackTrace)? onError,
  }) {
    Timer? timer;

    void reportError(Object error, StackTrace stackTrace) {
      _reportPersistenceError(error, stackTrace, onError);
    }

    Future<void> persistSafely() async {
      try {
        await persist(save);
      } catch (error, stackTrace) {
        reportError(error, stackTrace);
      }
    }

    void schedulePersist() {
      timer?.cancel();
      if (debounce == null || debounce == Duration.zero) {
        unawaited(persistSafely());
        return;
      }

      timer = Timer(debounce, () {
        timer = null;
        unawaited(persistSafely());
      });
    }

    addListener(schedulePersist);
    keep(
      _PersistOnChangeHandle(
        disposeCallback: () {
          timer?.cancel();
          removeListener(schedulePersist);
        },
      ),
    );

    if (persistInitialState) {
      schedulePersist();
    }
  }

  void _reportPersistenceError(
    Object error,
    StackTrace stackTrace,
    void Function(Object error, StackTrace stackTrace)? onError,
  ) {
    final handler = onError ?? StateForge.onError;
    if (handler != null) {
      handler(error, stackTrace);
    } else {
      Zone.current.handleUncaughtError(error, stackTrace);
    }
  }
}

final class _PersistOnChangeHandle implements ForgeDisposable {
  _PersistOnChangeHandle({required this.disposeCallback});

  final void Function() disposeCallback;

  @override
  void dispose() {
    disposeCallback();
  }
}
