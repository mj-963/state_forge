import 'dart:async';
import 'package:flutter/widgets.dart';
import 'store.dart';
import '_scope.dart';

/// A widget that listens to side effects emitted by a [Store].
///
/// [ForgeListener] does NOT rebuild when the store state changes.
/// It is designed for one-time events like navigation, showing snackbars,
/// or firing analytics.
///
/// Example:
/// ```dart
/// ForgeListener<AuthStore, String>(
///   onEffect: (context, effect) => Navigator.push(...),
///   child: const LoginPage(),
/// )
/// ```
class ForgeListener<T extends Store, E> extends StatefulWidget {
  /// Creates a [ForgeListener] to respond to effects of type [E].
  const ForgeListener({
    super.key,
    required this.onEffect,
    required this.child,
  });

  /// A callback triggered whenever the store emits an effect of type [E].
  final void Function(BuildContext context, E effect) onEffect;

  /// The widget subtree.
  final Widget child;

  @override
  State<ForgeListener<T, E>> createState() => _ForgeListenerState<T, E>();
}

class _ForgeListenerState<T extends Store, E>
    extends State<ForgeListener<T, E>> {
  StreamSubscription? _subscription;
  T? _store;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // We don't listen to state changes, only provide O(1) lookup
    final newStore = StoreScope.of<T>(context, listen: false);
    if (newStore == null) {
      throw StateError(
        'No StoreProvider<$T> found above this ForgeListener.',
      );
    }

    if (_store != newStore) {
      _subscription?.cancel();
      _store = newStore;
      _subscription =
          _store!.effectStream.where((e) => e is E).cast<E>().listen((e) {
        if (!mounted) return;
        widget.onEffect(context, e);
      });
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// A mixin for [StatefulWidget] states to listen to side effects without
/// adding extra widgets to the tree.
///
/// Example:
/// ```dart
/// class _MyState extends State<MyPage> with ForgeEffectListener {
///   @override
///   void didChangeDependencies() {
///     super.didChangeDependencies();
///     listenToEffect<AuthStore, String>((e) => print(e));
///   }
/// }
/// ```
mixin ForgeEffectListener<T extends StatefulWidget> on State<T> {
  final List<StreamSubscription> _forgeSubscriptions = [];

  /// Subscribes to side effects of type [E] from a [Store] of type [S].
  ///
  /// The subscription is automatically cancelled when the state is disposed.
  void listenToEffect<S extends Store, E>(void Function(E effect) onEffect) {
    final store = StoreScope.of<S>(context, listen: false);
    if (store == null) {
      throw StateError(
        'No StoreProvider<$S> found above this context.',
      );
    }

    final sub = store.effectStream.where((e) => e is E).cast<E>().listen((e) {
      if (mounted) onEffect(e);
    });
    _forgeSubscriptions.add(sub);
  }

  @override
  void dispose() {
    for (final sub in _forgeSubscriptions) {
      sub.cancel();
    }
    super.dispose();
  }
}
