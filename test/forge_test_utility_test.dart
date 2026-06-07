import 'package:flutter_test/flutter_test.dart';
import 'package:state_forge/state_forge.dart';

class CounterStore extends Store<int> {
  CounterStore() : super(0);
  void increment() => emit(state + 1);
  Future<void> asyncIncrement() async {
    emit(1);
    await Future.delayed(const Duration(milliseconds: 10));
    emit(2);
  }
}

void main() {
  group('forgeTest', () {
    forgeTest<CounterStore, int>(
      'captures synchronous increment',
      build: () => CounterStore(),
      act: (store) => store.increment(),
      expect: () => [1],
    );

    forgeTest<CounterStore, int>(
      'captures multiple increments',
      build: () => CounterStore(),
      act: (store) {
        store.increment();
        store.increment();
      },
      expect: () => [2], // Coalesced into one update because it's sync
    );

    forgeTest<CounterStore, int>(
      'captures async increments',
      build: () => CounterStore(),
      act: (store) => store.asyncIncrement(),
      wait: const Duration(milliseconds: 50),
      expect: () => [1, 2],
    );

    forgeTest<CounterStore, int>(
      'works with AsyncState and matchers',
      build: () => CounterStore(),
      act: (store) => store.increment(),
      verify: (store) {
        expect(store.state, 1);
      },
    );
  });
}
