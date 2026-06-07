import 'package:flutter/foundation.dart';

import 'store.dart';

/// Adapts a pure Dart [Store] to Flutter's [Listenable] interface.
///
/// Use this for interop with Flutter APIs that require a [Listenable].
final class StoreListenableAdapter<T extends Store> implements Listenable {
  /// Creates a [Listenable] adapter for [store].
  StoreListenableAdapter(this.store);

  /// The store being adapted.
  final T store;

  final List<VoidCallback> _listeners = [];

  /// Removes all listeners registered through this adapter.
  void dispose() {
    for (final listener in _listeners.toList()) {
      store.removeListener(listener);
    }
    _listeners.clear();
  }

  @override
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
    store.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
    store.removeListener(listener);
  }
}

/// Flutter interop helpers for [Store].
extension StoreListenableInterop<T extends Store> on T {
  /// Wraps this store in a Flutter [Listenable].
  StoreListenableAdapter<T> asListenable() => StoreListenableAdapter<T>(this);
}
