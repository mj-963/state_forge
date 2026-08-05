import 'dart:async';

import 'package:meta/meta.dart';

import 'config.dart';

/// A callback invoked when a [Store] notifies listeners.
typedef StoreListener = void Function();

/// A resource with explicit cleanup semantics.
///
/// Pass a [ForgeDisposable] to [Store.keep] when a store-owned helper registers
/// listeners or timers that should be released with the store.
abstract interface class ForgeDisposable {
  /// Releases the resource.
  void dispose();
}

/// The foundation for all business logic in StateForge.
abstract class Store<S> {
  /// Initializes the store with its initial state.
  Store(this._state) {
    StateForge.diagnostics?.registerStore(this);
    StateForge.observer?.handleCreate(this);
  }

  S _state;
  bool _disposed = false;
  bool _emitQueued = false;
  bool _isNotifying = false;
  List<StoreListener>? _listeners = <StoreListener>[];

  /// The current immutable state of the store.
  S get state => _state;

  /// Whether the store has been disposed.
  bool get isDisposed => _disposed;

  final _effectController = StreamController<Object>.broadcast();

  /// Exposes the stream of effects emitted by this store.
  Stream<Object> get effectStream => _effectController.stream;

  final List<Object> _resources = [];

  /// Registers a callback to run when this store notifies listeners.
  void addListener(StoreListener listener) {
    if (_disposed) return;
    _listeners ??= <StoreListener>[];
    _listeners!.add(listener);
  }

  /// Removes a previously registered listener.
  void removeListener(StoreListener listener) {
    final listeners = _listeners;
    if (listeners == null) return;
    if (_isNotifying) {
      _listeners = List<StoreListener>.of(listeners)..remove(listener);
    } else {
      listeners.remove(listener);
    }
  }

  /// Updates the store's state and notifies listeners.
  @protected
  void emit(S newState) {
    if (_disposed || _state == newState) return;

    final oldState = _state;

    if (StateForge.debugMode) {
      _debugLog('[StateForge] $runtimeType: $oldState -> $newState');
    }
    StateForge.diagnostics?.recordTransition(this, oldState, newState);
    StateForge.observer?.handleEmit(this, oldState, newState);

    _state = newState;

    if (!_emitQueued) {
      _emitQueued = true;
      scheduleMicrotask(() {
        if (!_disposed) {
          notifyListeners();
        }
        _emitQueued = false;
      });
    }
  }

  /// Updates the state and notifies listeners immediately.
  @protected
  void emitSync(S newState) {
    if (_disposed || _state == newState) return;

    final oldState = _state;

    if (StateForge.debugMode) {
      _debugLog('[StateForge] $runtimeType (Sync): $oldState -> $newState');
    }
    StateForge.diagnostics?.recordTransition(this, oldState, newState);
    StateForge.observer?.handleEmit(this, oldState, newState);

    _state = newState;
    notifyListeners();
  }

  /// Emits a one-time side effect.
  @protected
  void effect(Object effect) {
    if (!_disposed) {
      if (StateForge.debugMode) {
        _debugLog('[StateForge] $runtimeType Effect: $effect');
      }
      StateForge.diagnostics?.recordEffect(this, effect);
      StateForge.observer?.handleEffect(this, effect);
      _effectController.add(effect);
    }
  }

  /// Performs an optimistic state update.
  @protected
  Future<T?> optimistic<T>(
    S optimisticState,
    Future<T> action, {
    S? onFailure,
  }) async {
    final previousState = state;
    emit(optimisticState);
    try {
      return await action;
    } catch (e, stack) {
      emit(onFailure ?? previousState);
      if (StateForge.onError != null) {
        StateForge.onError!(e, stack);
      }
      rethrow;
    }
  }

  /// Registers a resource to be automatically cleaned up.
  T keep<T extends Object>(T resource) {
    _resources.add(resource);
    return resource;
  }

  /// Executes an asynchronous action safely.
  @protected
  Future<T?> guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (e, stack) {
      StateForge.observer?.handleError(this, e, stack);
      if (StateForge.onError != null) {
        StateForge.onError!(e, stack);
      }
      rethrow;
    }
  }

  /// Notifies all listeners immediately.
  @protected
  void notifyListeners() {
    final listeners = _listeners;
    if (_disposed || listeners == null || listeners.isEmpty) return;

    final snapshot = List<StoreListener>.of(listeners);
    _isNotifying = true;
    try {
      for (final listener in snapshot) {
        if (_listeners?.contains(listener) ?? false) {
          listener();
        }
      }
    } finally {
      _isNotifying = false;
    }
  }

  /// Releases this store and any resources registered with [keep].
  @mustCallSuper
  void dispose() {
    if (_disposed) return;
    _disposed = true;

    StateForge.diagnostics?.unregisterStore(this);
    StateForge.observer?.handleDispose(this);
    _effectController.close();

    for (final resource in _resources) {
      _disposeResource(resource);
    }
    _resources.clear();
    _listeners = null;
  }

  void _disposeResource(Object resource) {
    if (resource is ForgeDisposable) {
      resource.dispose();
    } else if (resource is Sink) {
      resource.close();
    } else if (resource is StreamSubscription) {
      unawaited(resource.cancel());
    } else if (resource is Timer) {
      resource.cancel();
    } else {
      _tryDisposeDynamic(resource);
    }
  }

  void _tryDisposeDynamic(Object resource) {
    try {
      final disposable = resource as dynamic;
      disposable.dispose();
    } on NoSuchMethodError {
      // Resource does not expose a dispose method. Ignore it.
    }
  }

  void _debugLog(String message) {
    if (!StateForge.debugMode) return;
    assert(() {
      // ignore: avoid_print
      print(message);
      return true;
    }());
  }
}
