import 'package:flutter/widgets.dart';
import 'store.dart';
import '_scope.dart';

/// A widget that rebuilds whenever the [Store] notifies listeners.
///
/// Use [ForgeBuilder] when you want to subscribe to every change in a store
/// without manually using [context.watch].
///
/// Example:
/// ```dart
/// ForgeBuilder<AuthStore, AsyncState<String>>(
///   builder: (context, state, store) => Text(state.data ?? ''),
/// )
/// ```
class ForgeBuilder<T extends Store<S>, S> extends StatefulWidget {
  /// Creates a [ForgeBuilder] that rebuilds on every store update.
  const ForgeBuilder({
    super.key,
    required this.builder,
  });

  /// A function that builds a widget based on the current state [S] and store [T].
  final Widget Function(BuildContext context, S state, T store) builder;

  @override
  State<ForgeBuilder<T, S>> createState() => _ForgeBuilderState<T, S>();
}

class _ForgeBuilderState<T extends Store<S>, S>
    extends State<ForgeBuilder<T, S>> {
  T? _store;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newStore = StoreScope.of<T>(context, listen: false);
    if (newStore == null) {
      throw StateError(
        'No StoreProvider<$T> found above this ForgeBuilder.',
      );
    }

    if (_store != newStore) {
      _store?.removeListener(_handleUpdate);
      _store = newStore;
      newStore.addListener(_handleUpdate);
    }
  }

  @override
  void dispose() {
    _store?.removeListener(_handleUpdate);
    super.dispose();
  }

  void _handleUpdate() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _store!.state, _store!);
  }
}
