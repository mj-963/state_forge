import '../store.dart';

/// A mixin that allows a [Store] to reactively depend on other [Store]s.
///
/// It provides the [watchStore] method which manages the internal listener
/// and ensures it is properly cleaned up when this store is disposed.
mixin CompositedStore<S> on Store<S> {
  final List<void Function()> _compositedSubs = [];

  /// Listens to another [store] and calls the [listener] whenever it changes.
  ///
  /// The subscription is automatically cancelled when this store is disposed.
  void watchStore<T extends Store>(T store, void Function(T store) listener) {
    void handleUpdate() => listener(store);
    store.addListener(handleUpdate);
    _compositedSubs.add(() => store.removeListener(handleUpdate));
  }

  @override
  void dispose() {
    for (final cancel in _compositedSubs) {
      cancel();
    }
    _compositedSubs.clear();
    super.dispose();
  }
}
