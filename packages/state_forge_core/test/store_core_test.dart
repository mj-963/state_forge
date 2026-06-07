import 'dart:async';

import 'package:state_forge_core/state_forge_core.dart';
import 'package:test/test.dart';

class CounterStore extends Store<int> {
  CounterStore([super.initial = 0]);

  void increment() => emit(state + 1);

  void incrementSync() => emitSync(state + 1);

  void setValue(int value) => emitSync(value);

  Future<void> failGuarded() => guard<void>(() => throw StateError('failed'));

  void sendEffect(Object value) => effect(value);
}

class StringStore extends Store<String> {
  StringStore([super.initial = 'initial']);

  void setValue(String value) => emitSync(value);
}

class DependentStore extends Store<int> with CompositedStore<int> {
  DependentStore(CounterStore dependency) : super(dependency.state) {
    watchStore(dependency, (store) => emitSync(store.state));
  }
}

class UndoStore extends Store<int> with UndoableStore<int> {
  UndoStore() : super(0);

  void setValue(int value) => emitSync(value);
}

class PersistStore extends Store<int> with PersistableStore<int> {
  PersistStore([super.initial = 0]);

  @override
  String get storageKey => 'counter';

  void setValue(int value) => emitSync(value);

  @override
  int fromJson(Map<String, dynamic> json) => json['value'] as int;

  @override
  Map<String, dynamic> toJson(int state) => {'value': state};
}

class MemoryStorage implements ForgeStorageAdapter {
  final Map<String, Map<String, dynamic>> data = {};
  Object? readError;
  Object? writeError;
  Object? deleteError;

  @override
  Future<void> delete(String key) async {
    final error = deleteError;
    if (error != null) throw error;
    data.remove(key);
  }

  @override
  Future<Map<String, dynamic>?> read(String key) async {
    final error = readError;
    if (error != null) throw error;
    return data[key];
  }

  @override
  Future<void> write(String key, Map<String, dynamic> data) async {
    final error = writeError;
    if (error != null) throw error;
    this.data[key] = Map<String, dynamic>.from(data);
  }
}

class DisposableResource implements ForgeDisposable {
  var disposed = false;

  @override
  void dispose() {
    disposed = true;
  }
}

void main() {
  tearDown(() {
    StateForge.debugMode = false;
    StateForge.observer = null;
    StateForge.onError = null;
    StateForge.storage = null;
    StateForge.diagnostics = null;
  });

  test('emit coalesces listener notifications by microtask', () async {
    StateForge.debugMode = false;
    final store = CounterStore();
    final states = <int>[];
    store.addListener(() => states.add(store.state));

    store.increment();
    store.increment();

    expect(store.state, 2);
    expect(states, isEmpty);

    await Future<void>.delayed(Duration.zero);

    expect(states, [2]);
  });

  test('emitSync notifies immediately', () {
    final store = CounterStore();
    final states = <int>[];
    store.addListener(() => states.add(store.state));

    store.incrementSync();

    expect(states, [1]);
  });

  test('listeners can be removed', () {
    final store = CounterStore();
    var calls = 0;
    void listener() => calls++;

    store.addListener(listener);
    store.removeListener(listener);
    store.incrementSync();

    expect(calls, 0);
  });

  test('duplicate listeners are called once per registration', () {
    final store = CounterStore();
    var calls = 0;
    void listener() => calls++;

    store
      ..addListener(listener)
      ..addListener(listener);

    store.incrementSync();

    expect(calls, 2);

    store.removeListener(listener);
    store.incrementSync();

    expect(calls, 3);

    store.removeListener(listener);
    store.incrementSync();

    expect(calls, 3);
  });

  test('listener removed during notification is skipped later in same pass',
      () {
    final store = CounterStore();
    final calls = <String>[];

    void second() => calls.add('second');

    void first() {
      calls.add('first');
      store.removeListener(second);
    }

    store
      ..addListener(first)
      ..addListener(second);

    store.incrementSync();

    expect(calls, ['first']);
  });

  test('listener added during notification waits until next notification', () {
    final store = CounterStore();
    final calls = <String>[];

    void second() => calls.add('second');

    void first() {
      calls.add('first');
      store.addListener(second);
    }

    store.addListener(first);

    store.incrementSync();
    expect(calls, ['first']);

    store.incrementSync();
    expect(calls, ['first', 'first', 'second']);
  });

  test('listener can dispose store during notification', () {
    final store = CounterStore();
    final calls = <String>[];

    store
      ..addListener(() {
        calls.add('first');
        store.dispose();
      })
      ..addListener(() => calls.add('second'));

    store.incrementSync();
    store.incrementSync();

    expect(calls, ['first']);
    expect(store.isDisposed, isTrue);
  });

  test('large synchronous notification fanout is deterministic', () {
    final store = CounterStore();
    var calls = 0;

    for (var i = 0; i < 1000; i++) {
      store.addListener(() => calls++);
    }

    store.incrementSync();

    expect(calls, 1000);
  });

  test('large async emit storm coalesces to one listener notification',
      () async {
    final store = CounterStore();
    var calls = 0;
    store.addListener(() => calls++);

    for (var i = 0; i < 1000; i++) {
      store.increment();
    }

    expect(store.state, 1000);
    expect(calls, 0);

    await Future<void>.delayed(Duration.zero);

    expect(calls, 1);
  });

  test('queued emit notification is swallowed after disposal', () async {
    final store = CounterStore();
    var calls = 0;
    store.addListener(() => calls++);

    store.increment();
    store.dispose();
    await Future<void>.delayed(Duration.zero);

    expect(calls, 0);
    expect(store.state, 1);
  });

  test('emitting identical state is a no-op', () async {
    final store = CounterStore(7);
    var calls = 0;
    store.addListener(() => calls++);

    store.setValue(7);
    store.setValue(7);
    await Future<void>.delayed(Duration.zero);

    expect(calls, 0);
    expect(store.state, 7);
  });

  test('disposed store ignores future state changes', () async {
    final store = CounterStore();
    store.dispose();
    store.incrementSync();
    store.increment();
    await Future<void>.delayed(Duration.zero);

    expect(store.state, 0);
    expect(store.isDisposed, isTrue);
  });

  test('effect stream emits effects', () async {
    final store = CounterStore();

    expectLater(store.effectStream, emits('saved'));
    store.sendEffect('saved');
  });

  test('effect after disposal is ignored and stream is closed', () async {
    final store = CounterStore();
    final events = <Object>[];
    var closed = false;
    store.effectStream.listen(events.add, onDone: () => closed = true);

    store.dispose();
    store.sendEffect('late');

    await Future<void>.delayed(Duration.zero);

    expect(events, isEmpty);
    expect(closed, isTrue);
  });

  test('guard reports errors to observer and global handler', () async {
    Object? observedError;
    Object? handledError;
    StateForge.observer = ForgeObserver(
      onError: (store, error, stackTrace) => observedError = error,
    );
    StateForge.onError = (error, stackTrace) => handledError = error;

    final store = CounterStore();

    await expectLater(store.failGuarded(), throwsStateError);
    expect(observedError, isA<StateError>());
    expect(handledError, isA<StateError>());
  });

  test('optimistic returns action result and keeps successful optimistic state',
      () async {
    final store = _OptimisticStore();

    final result = await store.saveSuccess();

    expect(result, 'ok');
    expect(store.state, 'saving');
  });

  test('optimistic rolls back on failure and reports through onError',
      () async {
    Object? capturedError;
    StateForge.onError = (error, stackTrace) => capturedError = error;
    final store = _OptimisticStore();

    await expectLater(store.saveFailure(), throwsStateError);

    expect(store.state, 'initial');
    expect(capturedError, isA<StateError>());
  });

  test('keep disposes resources on store disposal', () {
    final store = CounterStore();
    final disposable = store.keep(DisposableResource());
    final timer = store.keep(Timer(const Duration(days: 1), () {}));
    final controller = store.keep(StreamController<int>());

    store.dispose();

    expect(disposable.disposed, isTrue);
    expect(timer.isActive, isFalse);
    expect(controller.isClosed, isTrue);
  });

  test('disposing twice is idempotent', () {
    final store = CounterStore();
    final disposable = store.keep(DisposableResource());

    store
      ..dispose()
      ..dispose();

    expect(disposable.disposed, isTrue);
    expect(store.isDisposed, isTrue);
  });

  test('observer tracks lifecycle and transitions', () {
    final events = <String>[];
    StateForge.observer = ForgeObserver(
      onCreate: (store) => events.add('create'),
      onEmit: (store, oldState, newState) => events.add('$oldState->$newState'),
      onDispose: (store) => events.add('dispose'),
    );

    final store = CounterStore();
    store.incrementSync();
    store.dispose();

    expect(events, ['create', '0->1', 'dispose']);
  });

  test('CompositedStore reacts to dependency changes', () {
    final dependency = CounterStore();
    final dependent = DependentStore(dependency);

    dependency.setValue(5);

    expect(dependent.state, 5);

    dependent.dispose();
    dependency.setValue(9);

    expect(dependent.state, 5);
  });

  test('UndoableStore tracks undo and redo', () async {
    final store = UndoStore();

    store.setValue(1);
    store.setValue(2);
    store.undo();
    await Future<void>.delayed(Duration.zero);

    expect(store.state, 1);
    expect(store.canRedo, isTrue);

    store.redo();
    await Future<void>.delayed(Duration.zero);

    expect(store.state, 2);
  });

  test('UndoableStore ignores duplicate states and respects maxHistory',
      () async {
    final store = UndoStore()..maxHistory = 2;

    store
      ..setValue(1)
      ..setValue(1)
      ..setValue(2)
      ..setValue(3);

    store.undo();
    await Future<void>.delayed(Duration.zero);
    expect(store.state, 2);

    store.undo();
    await Future<void>.delayed(Duration.zero);
    expect(store.state, 1);

    expect(store.canUndo, isFalse);
  });

  test('PersistableStore hydrates and persists through storage adapter',
      () async {
    final storage = MemoryStorage();
    storage.data['counter'] = {'value': 7};
    StateForge.storage = storage;

    final store = PersistStore();
    await store.hydrate();

    expect(store.state, 7);

    store.setValue(8);
    await store.persist();

    expect(storage.data['counter'], {'value': 8});
  });

  test('PersistableStore reports parse errors during hydrate', () async {
    Object? capturedError;
    StateForge.onError = (error, stackTrace) => capturedError = error;
    final storage = MemoryStorage();
    storage.data['counter'] = {'value': 'not-an-int'};
    StateForge.storage = storage;

    final store = PersistStore();
    await store.hydrate();

    expect(store.state, 0);
    expect(capturedError, isA<TypeError>());
  });

  test('PersistableStore throws when storage adapter is missing', () async {
    final store = PersistStore();

    await expectLater(store.hydrate(), throwsStateError);
    await expectLater(store.persist(), throwsStateError);
    await expectLater(store.clearPersisted(), throwsStateError);
  });

  test('persistOnChange routes write failures to Zone without handler',
      () async {
    final storage = MemoryStorage()..writeError = StateError('write failed');
    StateForge.storage = storage;
    final errors = <Object>[];

    await runZonedGuarded(
      () async {
        final store = PersistStore()..persistOnChange();
        store.setValue(4);
        await Future<void>.delayed(Duration.zero);
      },
      (error, stackTrace) => errors.add(error),
    );

    expect(errors.single, isA<StateError>());
  });

  test('AsyncState exposes helpers and equality', () {
    const idle = Idle<int>();
    const loading = Loading<int>();
    const success = Success(3);
    const failure = Failure<int>('nope');

    expect(idle.isIdle, isTrue);
    expect(loading.isLoading, isTrue);
    expect(success.data, 3);
    expect(failure.error, 'nope');
    expect(const Success(3), const Success(3));
    expect(
        success.when(
          idle: () => 0,
          loading: () => 1,
          success: (value) => value,
          failure: (error) => -1,
        ),
        3);
  });

  test('AsyncState maybeWhen and maybeMap use fallbacks', () {
    const state = Loading<int>();

    expect(
      state.maybeWhen(
        success: (value) => value,
        orElse: () => -1,
      ),
      -1,
    );
    expect(
      state.maybeMap(
        success: (success) => success.value,
        orElse: () => -2,
      ),
      -2,
    );
  });
}

class _OptimisticStore extends StringStore {
  Future<String?> saveSuccess() => optimistic(
        'saving',
        Future<String>.value('ok'),
      );

  Future<String?> saveFailure() => optimistic(
        'saving',
        Future<String>.error(StateError('failed')),
      );
}
