import 'package:flutter/widgets.dart';
import 'store.dart';
import '_scope.dart';

/// Extensions on [BuildContext] for easy access to [Store]s.
extension ForgeContext on BuildContext {
  /// Reads a [Store] of type [T] and subscribes the widget to all changes.
  ///
  /// Use this in the `build` method for widgets that depend on the entire state.
  /// Rebuilds are managed surgically by the internal StateForge engine.
  ///
  /// For even better performance control, consider [ForgeSelector] or [StoreWidget].
  T watch<T extends Store>() {
    if (!mounted) {
      throw StateError(
          'context.watch<$T>() was called after the widget was unmounted.\n'
          'This is usually a mistake, as watch() should only be used in the build method.');
    }
    final store = StoreScope.of<T>(this, listen: true);
    if (store == null) {
      throw StateError('No StoreProvider<$T> found above this BuildContext.\n'
          'Make sure the StoreProvider is an ancestor of the widget calling context.watch.');
    }
    return store;
  }

  /// Reads a [Store] of type [T] without subscribing to changes.
  ///
  /// Use this in callbacks like `onTap`, `onPressed`, or inside async blocks.
  T read<T extends Store>() {
    if (!mounted) {
      throw StateError(
          'context.read<$T>() was called after the widget was unmounted.\n'
          'This typically happens after an "await" call. Always check '
          '"if (!context.mounted)" before using context, or use '
          '"context.maybeRead<$T>()" instead.');
    }
    final store = StoreScope.of<T>(this, listen: false);
    if (store == null) {
      throw StateError('No StoreProvider<$T> found above this BuildContext.\n'
          'Make sure the StoreProvider is an ancestor of the widget calling context.read.');
    }
    return store;
  }

  /// Safely attempts to read a [Store] of type [T] without subscribing to changes.
  ///
  /// Returns `null` if the widget has been unmounted or if the store is not found.
  /// This is particularly useful after `await` calls to avoid the classic async
  /// post-unmount crash.
  T? maybeRead<T extends Store>() {
    if (!mounted) return null;
    return StoreScope.of<T>(this, listen: false);
  }

  /// Reads a [Store] and subscribes to it, but only returns a selected part of the state.
  ///
  /// This widget will ONLY rebuild when the result of the [selector] changes.
  ///
  /// Example:
  /// ```dart
  /// final name = context.select<AuthStore, AsyncState<String>, String>((s) => s.data ?? '');
  /// ```
  R select<T extends Store<S>, S, R>(R Function(S state) selector) {
    if (!mounted) {
      throw StateError(
          'context.select<$T, $S, $R>() was called after the widget was unmounted.');
    }
    final selection = StoreScope.select<T, S, R>(this, selector);
    if (!selection.found) {
      throw StateError('No StoreProvider<$T> found above this BuildContext.\n'
          'Make sure the StoreProvider is an ancestor of the widget calling context.select.');
    }
    return selection.value as R;
  }

  /// Alias for [watch].
  @Deprecated('Use watch<T>() instead')
  T forge<T extends Store>() => watch<T>();

  /// Alias for [read].
  @Deprecated('Use read<T>() instead')
  T forgeRead<T extends Store>() => read<T>();

  /// Alias for [select].
  @Deprecated('Use select<T, S, R>() instead')
  R forgeSelect<T extends Store<S>, S, R>(R Function(S state) selector) =>
      select<T, S, R>(selector);
}
