import 'package:flutter/widgets.dart';
import 'store.dart';
import '_scope.dart';

/// An interface for widgets that can be nested in [ForgeMultiProvider].
abstract interface class SingleChildWidget extends Widget {
  /// Base constructor for single-child widgets.
  const SingleChildWidget({super.key});

  /// Builds the widget with the given [child].
  Widget buildWithChild(BuildContext context, Widget child);
}

/// A widget that provides and manages the lifecycle of a [Store].
///
/// The store is created using the [create] function when the provider is
/// first inserted into the tree and is automatically disposed when
/// the provider is removed.
class StoreProvider<T extends Store> extends StatefulWidget
    implements SingleChildWidget {
  /// Creates a [StoreProvider] that manages a new store instance.
  const StoreProvider({
    super.key,
    required T Function(BuildContext context) create,
    this.child,
  })  : _create = create,
        _value = null;

  /// Creates a [StoreProvider] that provides an existing [Store] instance.
  ///
  /// The provided [value] will NOT be disposed by this provider.
  const StoreProvider.value({super.key, required T value, this.child})
      : _value = value,
        _create = null;

  final T Function(BuildContext context)? _create;
  final T? _value;
  final Widget? child;

  @override
  Widget buildWithChild(BuildContext context, Widget child) {
    if (_create != null) {
      return StoreProvider<T>(key: key, create: _create, child: child);
    }
    return StoreProvider<T>.value(key: key, value: _value!, child: child);
  }

  @override
  State<StoreProvider<T>> createState() => _StoreProviderState<T>();
}

class _StoreProviderState<T extends Store> extends State<StoreProvider<T>> {
  late T _store;
  int _revision = 0;
  Object? _stateSnapshot;

  @override
  void initState() {
    super.initState();
    _store = widget._create?.call(context) ?? widget._value!;
    _stateSnapshot = _store.state;
    _store.addListener(_handleStoreChanged);
  }

  @override
  void didUpdateWidget(StoreProvider<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget._create == null && widget._value != oldWidget._value) {
      _store.removeListener(_handleStoreChanged);
      _store = widget._value!;
      _stateSnapshot = _store.state;
      _store.addListener(_handleStoreChanged);
      _revision++;
    }
  }

  @override
  void dispose() {
    _store.removeListener(_handleStoreChanged);
    if (widget._create != null) {
      _store.dispose();
    }
    super.dispose();
  }

  void _handleStoreChanged() {
    if (!mounted) return;
    setState(() {
      _stateSnapshot = _store.state;
      _revision++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StoreScope<T>(
      store: _store,
      stateSnapshot: _stateSnapshot,
      revision: _revision,
      child: widget.child ?? const SizedBox.shrink(),
    );
  }
}

/// Creates a [Store] from another store higher in the widget tree.
///
/// Use this when a dependent store must stay in sync with the lifecycle of a
/// parent store instance. If the dependency instance changes, [update] is called
/// when provided; otherwise the dependent store is recreated.
class StoreProxyProvider<D extends Store, T extends Store>
    extends StatefulWidget implements SingleChildWidget {
  /// Creates a [StoreProxyProvider].
  const StoreProxyProvider({
    super.key,
    required this.create,
    this.update,
    this.child,
  });

  /// Creates the dependent store from the current dependency.
  final T Function(BuildContext context, D dependency) create;

  /// Updates an existing store when the dependency instance changes.
  ///
  /// Omit this to recreate the dependent store when [D] is replaced.
  final void Function(BuildContext context, D dependency, T store)? update;

  /// The widget subtree that will have access to the provided store.
  final Widget? child;

  @override
  Widget buildWithChild(BuildContext context, Widget child) {
    return StoreProxyProvider<D, T>(
      key: key,
      create: create,
      update: update,
      child: child,
    );
  }

  @override
  State<StoreProxyProvider<D, T>> createState() =>
      _StoreProxyProviderState<D, T>();
}

class _StoreProxyProviderState<D extends Store, T extends Store>
    extends State<StoreProxyProvider<D, T>> {
  T? _store;
  D? _dependency;
  int _revision = 0;
  Object? _stateSnapshot;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final dependency = StoreScope.identityOf<D>(context);
    if (dependency == null) {
      throw StateError(
        'No StoreProvider<$D> found above this StoreProxyProvider<$D, $T>.\n'
        'Make sure the dependency provider is an ancestor of the proxy provider.',
      );
    }

    if (_store == null) {
      _dependency = dependency;
      _store = widget.create(context, dependency);
      _stateSnapshot = _store!.state;
      _store!.addListener(_handleStoreChanged);
      return;
    }

    if (!identical(_dependency, dependency)) {
      _dependency = dependency;
      final update = widget.update;
      if (update == null) {
        _replaceStore(widget.create(context, dependency));
      } else {
        _store!.removeListener(_handleStoreChanged);
        update(context, dependency, _store!);
        _stateSnapshot = _store!.state;
        _store!.addListener(_handleStoreChanged);
        _revision++;
      }
    }
  }

  @override
  void dispose() {
    _store?.removeListener(_handleStoreChanged);
    _store?.dispose();
    super.dispose();
  }

  void _replaceStore(T nextStore) {
    final previousStore = _store!;
    previousStore.removeListener(_handleStoreChanged);
    previousStore.dispose();

    _store = nextStore;
    _stateSnapshot = nextStore.state;
    nextStore.addListener(_handleStoreChanged);
    _revision++;
  }

  void _handleStoreChanged() {
    if (!mounted || _store == null) return;
    setState(() {
      _stateSnapshot = _store!.state;
      _revision++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StoreScope<T>(
      store: _store!,
      stateSnapshot: _stateSnapshot,
      revision: _revision,
      child: widget.child ?? const SizedBox.shrink(),
    );
  }
}

/// A widget that merges multiple [StoreProvider]s into one list.
///
/// This flattens the widget tree and avoids "Provider Hell" (deep nesting).
///
/// Example:
/// ```dart
/// ForgeMultiProvider(
///   providers: [
///     StoreProvider<AuthStore>(create: (_) => AuthStore()),
///     StoreProvider<CartStore>(create: (_) => CartStore()),
///   ],
///   child: MyApp(),
/// )
/// ```
class ForgeMultiProvider extends StatelessWidget {
  /// Creates a [ForgeMultiProvider] with a list of [providers].
  const ForgeMultiProvider({
    super.key,
    required this.providers,
    required this.child,
  });

  /// The list of [StoreProvider]s or [SingleChildWidget]s to nest.
  final List<Widget> providers;

  /// The widget subtree that will have access to the provided stores.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    Widget tree = child;
    for (final provider in providers.reversed) {
      if (provider is SingleChildWidget) {
        tree = provider.buildWithChild(context, tree);
      } else {
        throw FlutterError(
          'ForgeMultiProvider only accepts StoreProvider, LazyStoreProvider, '
          'or widgets that implement SingleChildWidget. Found '
          '${provider.runtimeType}.',
        );
      }
    }
    return tree;
  }
}
