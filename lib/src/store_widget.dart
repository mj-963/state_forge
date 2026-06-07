import 'package:flutter/widgets.dart';
import 'store.dart';
import '_scope.dart';

/// An abstract widget that provides convenient access to a [Store].
///
/// Extend [StoreWidget] instead of [StatelessWidget] for widgets that
/// primarily depend on a single store. It injects the [store] and its
/// current [state] directly into the [buildStore] method.
///
/// Example:
/// ```dart
/// class MyPage extends StoreWidget<AuthStore, AsyncState<String>> {
///   @override
///   Widget buildStore(BuildContext context, AuthStore store, AsyncState<String> state) {
///     return Text(state.data ?? '');
///   }
/// }
/// ```
abstract class StoreWidget<T extends Store<S>, S> extends StatefulWidget {
  /// Base constructor for [StoreWidget].
  const StoreWidget({super.key});

  /// The build method, which receives both the [store] and its current [state].
  Widget buildStore(BuildContext context, T store, S state);

  @override
  State<StoreWidget<T, S>> createState() => _StoreWidgetState<T, S>();
}

class _StoreWidgetState<T extends Store<S>, S>
    extends State<StoreWidget<T, S>> {
  T? _store;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newStore = StoreScope.of<T>(context, listen: false);
    assert(
        newStore != null, 'No StoreProvider<$T> found above this StoreWidget');

    if (_store != newStore) {
      _store?.removeListener(_handleUpdate);
      _store = newStore;
      _store!.addListener(_handleUpdate);
    }
  }

  @override
  void dispose() {
    _store?.removeListener(_handleUpdate);
    super.dispose();
  }

  void _handleUpdate() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return widget.buildStore(context, _store!, _store!.state);
  }
}
