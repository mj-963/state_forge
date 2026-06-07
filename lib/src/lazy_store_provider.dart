import 'package:flutter/widgets.dart';
import 'store.dart';
import 'store_provider.dart';
import '_scope.dart';

/// A provider that defers the creation of a [Store] until it is first accessed.
///
/// Useful for memory-intensive stores or features that may not be visited
/// in every app session.
class LazyStoreProvider<T extends Store> extends StatefulWidget
    implements SingleChildWidget {
  /// Creates a [LazyStoreProvider] that only instantiates the store when needed.
  const LazyStoreProvider({
    super.key,
    required this.create,
    this.child,
  });

  /// The function called to create the store instance.
  final T Function(BuildContext context) create;

  /// The widget subtree.
  final Widget? child;

  @override
  Widget buildWithChild(BuildContext context, Widget child) {
    return LazyStoreProvider<T>(
      key: key,
      create: create,
      child: child,
    );
  }

  @override
  State<LazyStoreProvider<T>> createState() => _LazyStoreProviderState<T>();
}

class _LazyStoreProviderState<T extends Store>
    extends State<LazyStoreProvider<T>> {
  T? _store;
  Object? _stateSnapshot;
  int _revision = 0;

  T _getOrCreateStore() {
    if (_store == null) {
      _store = widget.create(context);
      _stateSnapshot = _store!.state;
      _store!.addListener(_handleStoreChanged);
    }
    return _store!;
  }

  @override
  void dispose() {
    _store?.removeListener(_handleStoreChanged);
    _store?.dispose();
    super.dispose();
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
    return LazyStoreScope<T>(
      getStore: _getOrCreateStore,
      stateSnapshot: _stateSnapshot,
      revision: _revision,
      child: widget.child ?? const SizedBox.shrink(),
    );
  }
}
