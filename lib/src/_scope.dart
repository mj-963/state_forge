import 'package:flutter/widgets.dart';
import 'store.dart';

/// Internal scope that exposes a [Store] to the widget tree.
///
/// Uses [InheritedModel] so `watch()` can rebuild on every store update while
/// `select()` only rebuilds when its selected value changes.
class StoreScope<T extends Store> extends InheritedModel<Object> {
  const StoreScope({
    super.key,
    required T store,
    required this.stateSnapshot,
    required this.revision,
    required super.child,
  }) : _store = store;

  final T _store;
  final Object? stateSnapshot;
  final int revision;

  T get store => _store;

  static T? of<T extends Store>(BuildContext context, {bool listen = false}) {
    final aspect = listen ? const _WatchStoreAspect() : null;
    final scope = listen
        ? context.dependOnInheritedWidgetOfExactType<StoreScope<T>>(
            aspect: aspect,
          )
        : context.getInheritedWidgetOfExactType<StoreScope<T>>();
    if (scope != null) {
      return scope.store;
    }

    final lazyScope = listen
        ? context.dependOnInheritedWidgetOfExactType<LazyStoreScope<T>>(
            aspect: aspect,
          )
        : context.getInheritedWidgetOfExactType<LazyStoreScope<T>>();
    return lazyScope?.store;
  }

  static T? identityOf<T extends Store>(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<StoreScope<T>>(
      aspect: const _StoreIdentityAspect(),
    );
    if (scope != null) {
      return scope.store;
    }

    final lazyScope =
        context.dependOnInheritedWidgetOfExactType<LazyStoreScope<T>>(
            aspect: const _StoreIdentityAspect());
    return lazyScope?.store;
  }

  static StoreSelection<R> select<T extends Store<S>, S, R>(
    BuildContext context,
    R Function(S state) selector,
  ) {
    final aspect = _SelectorStoreAspect<S, R>(selector);
    final scope = context.dependOnInheritedWidgetOfExactType<StoreScope<T>>(
      aspect: aspect,
    );
    if (scope != null) {
      return StoreSelection.found(selector(scope.store.state));
    }

    final lazyScope = context
        .dependOnInheritedWidgetOfExactType<LazyStoreScope<T>>(aspect: aspect);
    final store = lazyScope?.store;
    return store == null
        ? const StoreSelection.notFound()
        : StoreSelection.found(selector(store.state));
  }

  @override
  bool updateShouldNotify(StoreScope<T> oldWidget) {
    return revision != oldWidget.revision;
  }

  @override
  bool updateShouldNotifyDependent(
    StoreScope<T> oldWidget,
    Set<Object> dependencies,
  ) {
    for (final dependency in dependencies) {
      if (dependency is _StoreIdentityAspect) {
        if (!identical(oldWidget.store, store)) {
          return true;
        }
      }
      if (dependency is _StoreAspect) {
        if (dependency.shouldNotify(oldWidget.stateSnapshot, stateSnapshot)) {
          return true;
        }
      }
    }
    return false;
  }
}

class StoreSelection<R> {
  const StoreSelection.found(this.value) : found = true;
  const StoreSelection.notFound()
      : found = false,
        value = null;

  final bool found;
  final R? value;
}

class LazyStoreScope<T extends Store> extends InheritedModel<Object> {
  const LazyStoreScope({
    super.key,
    required T Function() getStore,
    required this.stateSnapshot,
    required this.revision,
    required super.child,
  }) : _getStore = getStore;

  final T Function() _getStore;
  final Object? stateSnapshot;
  final int revision;

  T get store => _getStore();

  @override
  bool updateShouldNotify(LazyStoreScope<T> oldWidget) {
    return revision != oldWidget.revision;
  }

  @override
  bool updateShouldNotifyDependent(
    LazyStoreScope<T> oldWidget,
    Set<Object> dependencies,
  ) {
    for (final dependency in dependencies) {
      if (dependency is _StoreIdentityAspect) {
        if (!identical(oldWidget.store, store)) {
          return true;
        }
      }
      if (dependency is _StoreAspect) {
        if (dependency.shouldNotify(oldWidget.stateSnapshot, stateSnapshot)) {
          return true;
        }
      }
    }
    return false;
  }
}

abstract interface class _StoreAspect {
  bool shouldNotify(Object? oldState, Object? newState);
}

class _WatchStoreAspect implements _StoreAspect {
  const _WatchStoreAspect();

  @override
  bool shouldNotify(Object? oldState, Object? newState) {
    return oldState != newState;
  }
}

class _StoreIdentityAspect {
  const _StoreIdentityAspect();
}

class _SelectorStoreAspect<S, R> implements _StoreAspect {
  const _SelectorStoreAspect(this.selector);

  final R Function(S state) selector;

  @override
  bool shouldNotify(Object? oldState, Object? newState) {
    if (oldState is! S || newState is! S) {
      return oldState != newState;
    }
    return selector(oldState) != selector(newState);
  }
}
