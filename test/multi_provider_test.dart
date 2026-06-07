import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:state_forge/state_forge.dart';

class StoreA extends Store<int> {
  StoreA() : super(0);
}

class StoreB extends Store<int> {
  StoreB() : super(0);
}

void main() {
  testWidgets('ForgeMultiProvider preserves generic types', (tester) async {
    await tester.pumpWidget(
      ForgeMultiProvider(
        providers: [
          StoreProvider<StoreA>(create: (_) => StoreA()),
          StoreProvider<StoreB>(create: (_) => StoreB()),
        ],
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: ForgeBuilder<StoreA, int>(
            builder: (context, state, store) {
              // This will throw if StoreProvider<StoreB> is not found
              context.watch<StoreB>();
              return const Text('Found both');
            },
          ),
        ),
      ),
    );

    expect(find.text('Found both'), findsOneWidget);
  });
}
