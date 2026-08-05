import 'package:meta/meta.dart';
import 'package:state_forge_core/state_forge_core.dart' as core;

import 'devtools.dart';

export 'package:state_forge_core/state_forge_core.dart'
    show ForgeDisposable, StoreListener;

/// The Flutter-facing StateForge store base class.
///
/// It preserves the public `Store<S>` API while delegating the implementation to
/// the pure Dart core package.
abstract class Store<S> extends core.Store<S> {
  /// Initializes the store with its initial state.
  Store(S initial) : super(_installFlutterDiagnostics(initial));
}

/// A [Store] that declares the type of one-time effect it emits.
///
/// [Store.effect] accepts any [Object], so a typo or a stale effect class is
/// only caught at runtime — usually not at all, since an effect nothing listens
/// for fails silently. Declaring [E] makes that a compile error:
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
///   CartStore() : super(const CartState());
///
///   void checkout() {
///     effect(const OrderPlaced('a1')); // ok
///     effect('order_placed');          // compile error
///   }
/// }
/// ```
///
/// Pair it with [ForgeListener], which already filters by effect type. Use
/// [Store] directly when a feature emits no effects.
abstract class EffectStore<S, E extends Object> extends Store<S> {
  /// Initializes the store with its initial state.
  EffectStore(super.initial);

  /// Emits a one-time effect.
  ///
  /// Narrowed to [E], so the compiler rejects anything this store has not
  /// declared it can emit.
  @protected
  @override
  void effect(covariant E effect) => super.effect(effect);

  /// This store's effects, typed as [E].
  Stream<E> get effects => effectStream.cast<E>();
}

S _installFlutterDiagnostics<S>(S initial) {
  core.StateForge.diagnostics ??= ForgeDevTools.instance;
  return initial;
}
