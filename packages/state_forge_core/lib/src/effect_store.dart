import 'package:meta/meta.dart';

import 'store.dart';

/// A [Store] that declares the type of one-time effect it emits.
///
/// [Store.effect] accepts any [Object]. That is flexible, but it means a typo,
/// a stale effect class, or an effect from the wrong feature is only caught at
/// runtime — and usually not even then, because an effect nothing listens for
/// fails silently. Declaring [E] moves those to compile time:
///
/// ```dart
/// sealed class CartEffect {}
///
/// final class OrderPlaced extends CartEffect {
///   const OrderPlaced(this.orderId);
///   final String orderId;
/// }
///
/// class CartStore extends EffectStore<CartState, CartEffect> {
///   CartStore(this._repo) : super(const CartState());
///   final CartRepository _repo;
///
///   Future<void> checkout() async {
///     await guard(() async {
///       final order = await _repo.place(state.items);
///       emit(state.cleared());
///       effect(OrderPlaced(order.id)); // ok
///       effect('order_placed');        // compile error
///     });
///   }
/// }
/// ```
///
/// Everything else behaves exactly as [Store]. Use [Store] directly when a
/// feature emits no effects, or when you genuinely want an untyped channel.
abstract class EffectStore<S, E extends Object> extends Store<S> {
  /// Initializes the store with its initial state.
  EffectStore(super.initialState);

  /// Emits a one-time effect.
  ///
  /// Narrowed to [E], so the compiler rejects anything this store has not
  /// declared it can emit.
  @protected
  @override
  void effect(covariant E effect) => super.effect(effect);

  /// This store's effects, typed as [E].
  ///
  /// Prefer this over [Store.effectStream] when listening manually; the
  /// widget-level listeners already filter by type.
  Stream<E> get effects => effectStream.cast<E>();
}
