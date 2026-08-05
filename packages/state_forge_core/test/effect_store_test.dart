import 'package:state_forge_core/state_forge_core.dart';
import 'package:test/test.dart';

sealed class CartEffect {}

final class OrderPlaced extends CartEffect {
  OrderPlaced(this.orderId);
  final String orderId;
}

final class CartCleared extends CartEffect {}

class CartStore extends EffectStore<int, CartEffect> {
  CartStore() : super(0);

  void place(String id) {
    emitSync(state + 1);
    effect(OrderPlaced(id));
  }

  void clear() => effect(CartCleared());
}

/// A second store with an unrelated effect type, to prove the typed stream on
/// one store never surfaces another's effects.
sealed class AuthEffect {}

final class LoggedOut extends AuthEffect {}

class AuthStore extends EffectStore<bool, AuthEffect> {
  AuthStore() : super(false);

  void signOut() => effect(LoggedOut());
}

void main() {
  test('effects stream is typed and carries payloads', () async {
    final store = CartStore();
    addTearDown(store.dispose);

    final seen = <CartEffect>[];
    final sub = store.effects.listen(seen.add);
    addTearDown(sub.cancel);

    store.place('a1');
    store.clear();
    await Future<void>.delayed(Duration.zero);

    expect(seen, hasLength(2));
    // The element type is CartEffect, so this destructures without a cast.
    expect((seen.first as OrderPlaced).orderId, 'a1');
    expect(seen.last, isA<CartCleared>());
  });

  test('state still emits independently of effects', () async {
    final store = CartStore();
    addTearDown(store.dispose);

    final states = <int>[];
    store.addListener(() => states.add(store.state));

    store.place('a1');
    store.place('a2');
    await Future<void>.delayed(Duration.zero);

    expect(store.state, 2);
    expect(states, isNotEmpty);
  });

  test('a store only sees its own effects', () async {
    final cart = CartStore();
    final auth = AuthStore();
    addTearDown(cart.dispose);
    addTearDown(auth.dispose);

    final cartSeen = <CartEffect>[];
    final authSeen = <AuthEffect>[];
    final cartSub = cart.effects.listen(cartSeen.add);
    final authSub = auth.effects.listen(authSeen.add);
    addTearDown(cartSub.cancel);
    addTearDown(authSub.cancel);

    cart.place('a1');
    auth.signOut();
    await Future<void>.delayed(Duration.zero);

    expect(cartSeen, hasLength(1));
    expect(authSeen, hasLength(1));
    expect(authSeen.single, isA<LoggedOut>());
  });

  test('effects are not replayed to late listeners', () async {
    final store = CartStore();
    addTearDown(store.dispose);

    store.place('a1');
    await Future<void>.delayed(Duration.zero);

    final late = <CartEffect>[];
    final sub = store.effects.listen(late.add);
    addTearDown(sub.cancel);
    await Future<void>.delayed(Duration.zero);

    expect(late, isEmpty);
  });

  test('a disposed store emits nothing further', () async {
    final store = CartStore();
    final seen = <CartEffect>[];
    final sub = store.effects.listen(seen.add);
    addTearDown(sub.cancel);

    store.place('a1');
    await Future<void>.delayed(Duration.zero);
    store.dispose();
    store.clear();
    await Future<void>.delayed(Duration.zero);

    expect(seen, hasLength(1));
  });

  test('an optimistic rollback reports to the observer', () async {
    final errors = <Object>[];
    StateForge.observer = ForgeObserver(
      onError: (store, error, stack) => errors.add(error),
    );
    addTearDown(() => StateForge.observer = null);

    final store = FlakyStore();
    addTearDown(store.dispose);

    await expectLater(
      store.save(Future<void>.error(StateError('boom'))),
      throwsA(isA<StateError>()),
    );

    expect(store.state, 0, reason: 'rolled back');
    expect(errors, hasLength(1));
  });

  test('untyped effectStream still observes the same effects', () async {
    final store = CartStore();
    addTearDown(store.dispose);

    final raw = <Object>[];
    final sub = store.effectStream.listen(raw.add);
    addTearDown(sub.cancel);

    store.place('a1');
    await Future<void>.delayed(Duration.zero);

    expect(raw.single, isA<OrderPlaced>());
  });
}

// Regression: a rolled-back optimistic update must reach ForgeObserver, the
// same as an error caught by guard().
class FlakyStore extends Store<int> {
  FlakyStore() : super(0);
  Future<void> save(Future<void> action) => optimistic(1, action);
}
