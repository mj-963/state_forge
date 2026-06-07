import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:state_forge/state_forge.dart';

class CounterStore extends Store<int> {
  CounterStore([super.initial = 0]);
  void increment() => emit(state + 1);
  void fireEffect() => effect('ping');
}

void main() {
  group('Store', () {
    test('initial state is set', () {
      final store = CounterStore(10);
      expect(store.state, 10);
    });

    testWidgets('emit updates state and notifies after microtask',
        (tester) async {
      final store = CounterStore(0);
      var notified = 0;
      store.addListener(() => notified++);

      store.increment();
      expect(store.state, 1);
      expect(notified, 0);

      await tester.pump(Duration.zero);
      expect(notified, 1);
    });
  });

  group('AsyncState', () {
    test('standard variants work correctly', () {
      const state = Success<int>(42);
      expect(state.isLoading, false);
      expect(state.isSuccess, true);
      expect(state.data, 42);

      const errorState = Failure<int>('error');
      expect(errorState.isFailure, true);
      expect(errorState.error, 'error');
    });
  });

  group('Extensions', () {
    testWidgets('context.watch/read/select work', (tester) async {
      final store = CounterStore(0);

      await tester.pumpWidget(
        StoreProvider<CounterStore>.value(
          value: store,
          child: MaterialApp(
            home: ForgeBuilder<CounterStore, int>(
              builder: (context, state, _) {
                final watchState = context.watch<CounterStore>().state;
                final readStore = context.read<CounterStore>();
                final selectEven =
                    context.select<CounterStore, int, bool>((s) => s % 2 == 0);

                return Scaffold(
                  body: Column(
                    children: [
                      Text('Watch: $watchState'),
                      Text('Select: $selectEven'),
                      ElevatedButton(
                          onPressed: () => readStore.increment(),
                          child: const Text('Add')),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Watch: 0'), findsOneWidget);
      expect(find.text('Select: true'), findsOneWidget);

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump(Duration.zero);

      expect(find.text('Watch: 1'), findsOneWidget);
      expect(find.text('Select: false'), findsOneWidget);
    });
  });
}
