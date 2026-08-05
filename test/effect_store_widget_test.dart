import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:state_forge/state_forge.dart';

sealed class CheckoutEffect {}

final class OrderPlaced extends CheckoutEffect {
  OrderPlaced(this.orderId);
  final String orderId;
}

final class CheckoutFailed extends CheckoutEffect {}

class CheckoutStore extends EffectStore<int, CheckoutEffect> {
  CheckoutStore() : super(0);

  void place(String id) {
    emit(state + 1);
    effect(OrderPlaced(id));
  }

  void fail() => effect(CheckoutFailed());
}

void main() {
  testWidgets('ForgeListener receives typed effects from an EffectStore', (
    tester,
  ) async {
    final store = CheckoutStore();
    addTearDown(store.dispose);
    final seen = <CheckoutEffect>[];

    await tester.pumpWidget(
      StoreProvider<CheckoutStore>.value(
        value: store,
        child: MaterialApp(
          home: ForgeListener<CheckoutStore, CheckoutEffect>(
            onEffect: (context, effect) => seen.add(effect),
            child: const SizedBox(),
          ),
        ),
      ),
    );

    store.place('a1');
    store.fail();
    await tester.pump();

    expect(seen, hasLength(2));
    expect((seen.first as OrderPlaced).orderId, 'a1');
    expect(seen.last, isA<CheckoutFailed>());
  });

  testWidgets('a listener for one variant ignores the others', (tester) async {
    final store = CheckoutStore();
    addTearDown(store.dispose);
    final placed = <OrderPlaced>[];

    await tester.pumpWidget(
      StoreProvider<CheckoutStore>.value(
        value: store,
        child: MaterialApp(
          home: ForgeListener<CheckoutStore, OrderPlaced>(
            onEffect: (context, effect) => placed.add(effect),
            child: const SizedBox(),
          ),
        ),
      ),
    );

    store.fail();
    store.place('a2');
    await tester.pump();

    expect(placed.single.orderId, 'a2');
  });

  testWidgets('state updates drive rebuilds independently of effects', (
    tester,
  ) async {
    final store = CheckoutStore();
    addTearDown(store.dispose);

    await tester.pumpWidget(
      StoreProvider<CheckoutStore>.value(
        value: store,
        child: MaterialApp(
          home: ForgeBuilder<CheckoutStore, int>(
            builder: (context, count, _) =>
                Text('$count', textDirection: TextDirection.ltr),
          ),
        ),
      ),
    );

    expect(find.text('0'), findsOneWidget);

    store.place('a1');
    await tester.pump();

    expect(find.text('1'), findsOneWidget);
  });
}
