import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:state_forge/state_forge.dart';

class CounterLabelState {
  const CounterLabelState({this.count = 0, this.label = 'idle'});

  final int count;
  final String label;

  CounterLabelState copyWith({int? count, String? label}) {
    return CounterLabelState(
      count: count ?? this.count,
      label: label ?? this.label,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CounterLabelState &&
          other.count == count &&
          other.label == label;

  @override
  int get hashCode => Object.hash(count, label);
}

class CounterLabelStore extends Store<CounterLabelState> {
  CounterLabelStore() : super(const CounterLabelState());

  void increment() => emit(state.copyWith(count: state.count + 1));

  void rename(String value) => emit(state.copyWith(label: value));
}

class LazyCounterStore extends Store<int> {
  LazyCounterStore() : super(0);

  void increment() => emitSync(state + 1);
}

class UndoCounterStore extends Store<int> with UndoableStore<int> {
  UndoCounterStore() : super(0);

  void incrementSync() => emitSync(state + 1);
}

class ParentIdentityStore extends Store<String> {
  ParentIdentityStore(super.initial, [this.identity]);

  final String? identity;

  String get label => identity ?? state;

  void rename(String value) => emitSync(value);
}

class ChildWithParentStore extends Store<String> {
  ChildWithParentStore(this.parent) : super(parent.state);

  final ParentIdentityStore parent;

  String get parentIdentity => parent.label;
}

class RebindableChildStore extends Store<String> {
  RebindableChildStore(this.parent) : super(parent.label);

  ParentIdentityStore parent;
  int rebinds = 0;

  void rebind(ParentIdentityStore nextParent) {
    parent = nextParent;
    rebinds++;
    emitSync(nextParent.label);
  }
}

class HydratingCounterStore extends Store<int> with PersistableStore<int> {
  HydratingCounterStore([super.initial = 0]);

  @override
  String get storageKey => 'counter';

  void setValue(int value) => emitSync(value);

  @override
  int fromJson(Map<String, dynamic> json) => json['value'] as int;

  @override
  Map<String, dynamic> toJson(int state) => {'value': state};
}

class MemoryForgeStorage implements ForgeStorageAdapter {
  final Map<String, Map<String, dynamic>> data = {};
  int writes = 0;

  @override
  Future<void> delete(String key) async {
    data.remove(key);
  }

  @override
  Future<Map<String, dynamic>?> read(String key) async {
    return data[key];
  }

  @override
  Future<void> write(String key, Map<String, dynamic> data) async {
    writes++;
    this.data[key] = Map<String, dynamic>.from(data);
  }
}

class DelayedMemoryForgeStorage extends MemoryForgeStorage {
  DelayedMemoryForgeStorage(this.delay);

  final Duration delay;

  @override
  Future<Map<String, dynamic>?> read(String key) async {
    await Future<void>.delayed(delay);
    return super.read(key);
  }
}

void main() {
  tearDown(() {
    StateForge.storage = null;
    StateForge.onError = null;
  });

  testWidgets('context.select only rebuilds when selected value changes', (
    tester,
  ) async {
    var watchBuilds = 0;
    var selectBuilds = 0;

    await tester.pumpWidget(
      StoreProvider<CounterLabelStore>(
        create: (_) => CounterLabelStore(),
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              return Column(
                children: [
                  Builder(
                    builder: (context) {
                      watchBuilds++;
                      final state = context.watch<CounterLabelStore>().state;
                      return Text('Watch ${state.count} ${state.label}');
                    },
                  ),
                  Builder(
                    builder: (context) {
                      selectBuilds++;
                      final count = context.select<CounterLabelStore,
                          CounterLabelState, int>((state) => state.count);
                      return Text('Selected $count');
                    },
                  ),
                  TextButton(
                    onPressed: () =>
                        context.read<CounterLabelStore>().rename('renamed'),
                    child: const Text('Rename'),
                  ),
                  TextButton(
                    onPressed: () =>
                        context.read<CounterLabelStore>().increment(),
                    child: const Text('Increment'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );

    expect(watchBuilds, 1);
    expect(selectBuilds, 1);

    await tester.tap(find.text('Rename'));
    await tester.pump();

    expect(find.text('Watch 0 renamed'), findsOneWidget);
    expect(find.text('Selected 0'), findsOneWidget);
    expect(watchBuilds, 2);
    expect(selectBuilds, 1);

    await tester.tap(find.text('Increment'));
    await tester.pump();

    expect(find.text('Watch 1 renamed'), findsOneWidget);
    expect(find.text('Selected 1'), findsOneWidget);
    expect(watchBuilds, 3);
    expect(selectBuilds, 2);
  });

  testWidgets('LazyStoreProvider does not create the store until first access',
      (
    tester,
  ) async {
    var createCount = 0;

    await tester.pumpWidget(
      LazyStoreProvider<LazyCounterStore>(
        create: (_) {
          createCount++;
          return LazyCounterStore();
        },
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () => context.read<LazyCounterStore>().increment(),
                child: const Text('Create lazy store'),
              );
            },
          ),
        ),
      ),
    );

    expect(createCount, 0);

    await tester.tap(find.text('Create lazy store'));
    await tester.pump();

    expect(createCount, 1);
  });

  testWidgets('constructor-injected store dependency keeps original instance', (
    tester,
  ) async {
    final firstParent = ParentIdentityStore('first');
    final secondParent = ParentIdentityStore('second');

    Widget buildTree(ParentIdentityStore parent) {
      return StoreProvider<ParentIdentityStore>.value(
        value: parent,
        child: StoreProvider<ChildWithParentStore>(
          create: (context) =>
              ChildWithParentStore(context.read<ParentIdentityStore>()),
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                final visibleParent =
                    context.watch<ParentIdentityStore>().state;
                final childParent =
                    context.read<ChildWithParentStore>().parentIdentity;
                return Text('parent:$visibleParent child:$childParent');
              },
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildTree(firstParent));

    expect(find.text('parent:first child:first'), findsOneWidget);

    await tester.pumpWidget(buildTree(secondParent));
    await tester.pump();

    expect(find.text('parent:second child:first'), findsOneWidget);

    firstParent.dispose();
    secondParent.dispose();
  });

  testWidgets('StoreProxyProvider recreates store when dependency is replaced',
      (
    tester,
  ) async {
    final firstParent = ParentIdentityStore('same', 'first');
    final secondParent = ParentIdentityStore('same', 'second');
    final createdStores = <ChildWithParentStore>[];

    Widget buildTree(ParentIdentityStore parent) {
      return StoreProvider<ParentIdentityStore>.value(
        value: parent,
        child: StoreProxyProvider<ParentIdentityStore, ChildWithParentStore>(
          create: (context, dependency) {
            final store = ChildWithParentStore(dependency);
            createdStores.add(store);
            return store;
          },
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Builder(
              builder: (context) {
                final child = context.watch<ChildWithParentStore>();
                return Text('child:${child.parentIdentity}');
              },
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildTree(firstParent));

    expect(find.text('child:first'), findsOneWidget);
    expect(createdStores, hasLength(1));

    await tester.pumpWidget(buildTree(secondParent));
    await tester.pump();

    expect(find.text('child:second'), findsOneWidget);
    expect(createdStores, hasLength(2));
    expect(createdStores.first.isDisposed, isTrue);
    expect(createdStores.last.isDisposed, isFalse);

    firstParent.dispose();
    secondParent.dispose();
  });

  testWidgets('StoreProxyProvider can update store when dependency is replaced',
      (
    tester,
  ) async {
    final firstParent = ParentIdentityStore('same', 'first');
    final secondParent = ParentIdentityStore('same', 'second');
    RebindableChildStore? createdStore;

    Widget buildTree(ParentIdentityStore parent) {
      return StoreProvider<ParentIdentityStore>.value(
        value: parent,
        child: StoreProxyProvider<ParentIdentityStore, RebindableChildStore>(
          create: (context, dependency) {
            createdStore = RebindableChildStore(dependency);
            return createdStore!;
          },
          update: (context, dependency, store) => store.rebind(dependency),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Builder(
              builder: (context) {
                final child = context.watch<RebindableChildStore>();
                return Text('child:${child.state} rebinds:${child.rebinds}');
              },
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildTree(firstParent));

    expect(find.text('child:first rebinds:0'), findsOneWidget);
    final originalStore = createdStore;

    firstParent.rename('changed');
    await tester.pump();

    expect(find.text('child:first rebinds:0'), findsOneWidget);

    await tester.pumpWidget(buildTree(secondParent));
    await tester.pump();

    expect(find.text('child:second rebinds:1'), findsOneWidget);
    expect(identical(createdStore, originalStore), isTrue);
    expect(createdStore!.isDisposed, isFalse);

    firstParent.dispose();
    secondParent.dispose();
  });

  test('StoreListenableAdapter forwards notifications and detaches', () {
    final store = LazyCounterStore();
    final listenable = store.asListenable();
    var calls = 0;

    void listener() => calls++;

    listenable.addListener(listener);
    store.increment();

    expect(calls, 1);

    listenable.removeListener(listener);
    store.increment();

    expect(calls, 1);

    listenable.addListener(listener);
    listenable.dispose();
    store.increment();

    expect(calls, 1);
    store.dispose();
  });

  test('PersistableStore writes, hydrates, and clears through storage adapter',
      () async {
    final storage = MemoryForgeStorage();
    StateForge.storage = storage;

    final writer = HydratingCounterStore();
    writer.setValue(42);
    await writer.persist();

    final reader = HydratingCounterStore();
    await reader.hydrate();

    expect(reader.state, 42);
    expect(storage.data['counter'], {'value': 42});

    await reader.clearPersisted();
    expect(storage.data.containsKey('counter'), isFalse);
  });

  test('persistOnChange writes after state changes', () async {
    final storage = MemoryForgeStorage();
    StateForge.storage = storage;

    final store = HydratingCounterStore()..persistOnChange();

    store.setValue(7);
    await Future<void>.delayed(Duration.zero);

    expect(storage.data['counter'], {'value': 7});
  });

  test('persistOnChange supports debounce and disposal cleanup', () async {
    final storage = MemoryForgeStorage();
    StateForge.storage = storage;

    final store = HydratingCounterStore()
      ..persistOnChange(debounce: const Duration(milliseconds: 20));

    store
      ..setValue(1)
      ..setValue(2);

    await Future<void>.delayed(Duration.zero);
    expect(storage.data.containsKey('counter'), isFalse);

    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(storage.data['counter'], {'value': 2});

    final disposedStore = HydratingCounterStore()
      ..persistOnChange(debounce: const Duration(milliseconds: 20));
    disposedStore.setValue(9);
    disposedStore.dispose();

    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(storage.data['counter'], {'value': 2});
  });

  test('persistOnChange reports persistence failures', () async {
    Object? capturedError;
    StateForge.onError = (error, _) => capturedError = error;

    final store = HydratingCounterStore()..persistOnChange();

    store.setValue(5);
    await Future<void>.delayed(Duration.zero);

    expect(capturedError, isA<StateError>());
  });

  test('hydrateOnCreate hydrates before attaching auto-persistence', () async {
    final storage = MemoryForgeStorage();
    storage.data['counter'] = {'value': 11};
    StateForge.storage = storage;

    final store = HydratingCounterStore();

    await store.hydrateOnCreate();
    await Future<void>.delayed(Duration.zero);

    expect(store.state, 11);
    expect(storage.writes, 0);

    store.setValue(12);
    await Future<void>.delayed(Duration.zero);

    expect(storage.data['counter'], {'value': 12});
    expect(storage.writes, 1);
  });

  test('hydrateOnCreate can persist the initial state when storage is empty',
      () async {
    final storage = MemoryForgeStorage();
    StateForge.storage = storage;

    final store = HydratingCounterStore(5);

    await store.hydrateOnCreate(persistInitialState: true);
    await Future<void>.delayed(Duration.zero);

    expect(storage.data['counter'], {'value': 5});
  });

  test('hydrateOnCreate does not attach persistence after disposal', () async {
    final storage = DelayedMemoryForgeStorage(
      const Duration(milliseconds: 20),
    );
    storage.data['counter'] = {'value': 8};
    StateForge.storage = storage;

    final store = HydratingCounterStore();
    final hydration = store.hydrateOnCreate();

    store.dispose();
    await hydration;

    expect(storage.writes, 0);
  });

  test('UndoableStore records emitSync transitions', () {
    final store = UndoCounterStore();

    store.incrementSync();

    expect(store.state, 1);
    expect(store.canUndo, isTrue);

    store.undo();

    expect(store.state, 0);
    expect(store.canRedo, isTrue);
  });

  testWidgets('ForgeMultiProvider rejects unsupported provider widgets', (
    tester,
  ) async {
    await tester.pumpWidget(
      ForgeMultiProvider(
        providers: const [SizedBox.shrink()],
        child: const SizedBox.shrink(),
      ),
    );

    expect(tester.takeException(), isA<FlutterError>());
  });
}
