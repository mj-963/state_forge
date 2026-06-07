import 'package:flutter_test/flutter_test.dart';
import 'package:state_forge/state_forge.dart';

class TestObserver extends ForgeObserver {
  int creates = 0;
  int transitions = 0;
  int effects = 0;

  @override
  void handleCreate(Store store) => creates++;

  @override
  void handleEmit(Store store, Object? oldState, Object? newState) =>
      transitions++;

  @override
  void handleEffect(Store store, Object effect) => effects++;
}

class ObsStore extends Store<int> {
  ObsStore() : super(0);
  void inc() => emitSync(state + 1);
  void fire() => effect('hi');
}

class DependencyStore extends Store<int> {
  DependencyStore() : super(0);
  void inc() => emitSync(state + 1);
}

class DependentStore extends Store<int> with CompositedStore<int> {
  DependentStore(DependencyStore dep) : super(0) {
    watchStore(dep, (s) => emitSync(s.state));
  }
}

void main() {
  test('ForgeObserver tracks events', () {
    final obs = TestObserver();
    StateForge.observer = obs;

    final store = ObsStore();
    expect(obs.creates, 1);

    store.inc();
    expect(obs.transitions, 1);

    store.fire();
    expect(obs.effects, 1);

    StateForge.observer = null;
  });

  test('CompositedStore reacts to dependencies', () {
    final dep = DependencyStore();
    final dependent = DependentStore(dep);

    expect(dependent.state, 0);

    dep.inc();
    expect(dependent.state, 1);

    dep.inc();
    expect(dependent.state, 2);

    dependent.dispose();
    dep.inc();
    expect(dependent.state, 2); // Should not update after dispose
  });
}
