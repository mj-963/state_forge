import 'package:flutter/widgets.dart';
import 'store.dart';
import '_scope.dart';

/// A widget that rebuilds only when a specific part of a [Store]'s state changes.
///
/// [T] is the type of the Store.
/// [S] is the type of the Store's State.
/// [R] is the type of the value returned by the [select] function.
///
/// Example:
/// ```dart
/// ForgeSelector<AuthStore, AsyncState<String>, String>(
///   select: (state) => state.data ?? 'Guest',
///   builder: (context, name, store) => Text(name),
/// )
/// ```
class ForgeSelector<T extends Store<S>, S, R> extends StatefulWidget {
  /// Creates a [ForgeSelector] that rebuilds only when [select] result changes.
  const ForgeSelector({
    super.key,
    required this.select,
    required this.builder,
  });

  /// A function that selects a sub-part or derived value from the store's state.
  final R Function(S state) select;

  /// A function that builds a widget based on the selected value [R].
  final Widget Function(BuildContext context, R value, T store) builder;

  @override
  State<ForgeSelector<T, S, R>> createState() => _ForgeSelectorState<T, S, R>();
}

class _ForgeSelectorState<T extends Store<S>, S, R>
    extends State<ForgeSelector<T, S, R>> {
  T? _store;
  late R _selectedValue;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newStore = StoreScope.of<T>(context, listen: false);
    if (newStore == null) {
      throw StateError(
        'No StoreProvider<$T> found above this ForgeSelector.',
      );
    }

    if (_store != newStore) {
      _store?.removeListener(_handleUpdate);
      _store = newStore;
      newStore.addListener(_handleUpdate);
      _selectedValue = widget.select(newStore.state);
    }
  }

  @override
  void dispose() {
    _store?.removeListener(_handleUpdate);
    super.dispose();
  }

  void _handleUpdate() {
    if (!mounted) return;
    final newValue = widget.select(_store!.state);
    if (newValue != _selectedValue) {
      setState(() {
        _selectedValue = newValue;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _selectedValue, _store!);
  }
}
