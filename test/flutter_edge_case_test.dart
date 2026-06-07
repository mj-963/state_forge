import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:state_forge/state_forge.dart';

class EdgeCounterStore extends Store<int> {
  EdgeCounterStore([super.initial = 0]);

  void increment() => emitSync(state + 1);

  void incrementAsync() => emit(state + 1);

  void send(Object effect) => this.effect(effect);
}

class EdgeLabelStore extends Store<String> {
  EdgeLabelStore(super.initial);

  void rename(String value) => emitSync(value);
}

class EdgeDependentStore extends Store<String> {
  EdgeDependentStore(EdgeLabelStore dependency) : super(dependency.state);
}

class EdgeRebindStore extends Store<String> {
  EdgeRebindStore(EdgeLabelStore dependency) : super(dependency.state);

  var updates = 0;

  void rebind(EdgeLabelStore dependency) {
    updates++;
    emitSync(dependency.state);
  }
}

class DisposableStore extends Store<int> {
  DisposableStore() : super(0);
}

Widget ltr(Widget child) {
  return Directionality(textDirection: TextDirection.ltr, child: child);
}

void main() {
  testWidgets('context.read throws StateError after BuildContext unmount', (
    tester,
  ) async {
    late BuildContext capturedContext;

    await tester.pumpWidget(
      StoreProvider<EdgeCounterStore>(
        create: (_) => EdgeCounterStore(),
        child: Builder(
          builder: (context) {
            capturedContext = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    await tester.pumpWidget(const SizedBox.shrink());

    expect(
      () => capturedContext.read<EdgeCounterStore>(),
      throwsA(isA<StateError>()),
    );
    expect(capturedContext.maybeRead<EdgeCounterStore>(), isNull);
  });

  testWidgets('context methods throw StateError when provider is missing', (
    tester,
  ) async {
    Object? readError;
    Object? watchError;
    Object? selectError;

    await tester.pumpWidget(
      Builder(
        builder: (context) {
          try {
            context.read<EdgeCounterStore>();
          } catch (error) {
            readError = error;
          }
          try {
            context.watch<EdgeCounterStore>();
          } catch (error) {
            watchError = error;
          }
          try {
            context.select<EdgeCounterStore, int, int>((state) => state);
          } catch (error) {
            selectError = error;
          }
          return const SizedBox.shrink();
        },
      ),
    );

    expect(readError, isA<StateError>());
    expect(watchError, isA<StateError>());
    expect(selectError, isA<StateError>());
  });

  testWidgets('builder selector and listener throw StateError without provider',
      (
    tester,
  ) async {
    await tester.pumpWidget(
      ForgeBuilder<EdgeCounterStore, int>(
        builder: (context, state, store) => const SizedBox.shrink(),
      ),
    );
    expect(tester.takeException(), isA<StateError>());

    await tester.pumpWidget(
      ForgeSelector<EdgeCounterStore, int, int>(
        select: (state) => state,
        builder: (context, value, store) => const SizedBox.shrink(),
      ),
    );
    expect(tester.takeException(), isA<StateError>());

    await tester.pumpWidget(
      ForgeListener<EdgeCounterStore, String>(
        onEffect: (context, effect) {},
        child: const SizedBox.shrink(),
      ),
    );
    expect(tester.takeException(), isA<StateError>());
  });

  testWidgets('StoreProvider create owns and disposes store on unmount', (
    tester,
  ) async {
    DisposableStore? store;

    await tester.pumpWidget(
      StoreProvider<DisposableStore>(
        create: (_) {
          store = DisposableStore();
          return store!;
        },
        child: const SizedBox.shrink(),
      ),
    );

    expect(store, isNotNull);
    expect(store!.isDisposed, isFalse);

    await tester.pumpWidget(const SizedBox.shrink());

    expect(store!.isDisposed, isTrue);
  });

  testWidgets('StoreProvider.value swaps listeners without disposing old value',
      (
    tester,
  ) async {
    final first = EdgeCounterStore();
    final second = EdgeCounterStore();
    var builds = 0;

    Widget buildTree(EdgeCounterStore store) {
      return ltr(
        StoreProvider<EdgeCounterStore>.value(
          value: store,
          child: Builder(
            builder: (context) {
              builds++;
              return Text('${context.watch<EdgeCounterStore>().state}');
            },
          ),
        ),
      );
    }

    await tester.pumpWidget(buildTree(first));
    expect(find.text('0'), findsOneWidget);

    await tester.pumpWidget(buildTree(second));
    second.increment();
    await tester.pump();

    expect(find.text('1'), findsOneWidget);
    expect(first.isDisposed, isFalse);
    expect(second.isDisposed, isFalse);

    final buildsAfterSecondIncrement = builds;
    first.increment();
    await tester.pump();

    expect(builds, buildsAfterSecondIncrement);

    first.dispose();
    second.dispose();
  });

  testWidgets('LazyStoreProvider does not create or dispose an unused store', (
    tester,
  ) async {
    var creates = 0;

    await tester.pumpWidget(
      LazyStoreProvider<DisposableStore>(
        create: (_) {
          creates++;
          return DisposableStore();
        },
        child: const SizedBox.shrink(),
      ),
    );

    await tester.pumpWidget(const SizedBox.shrink());

    expect(creates, 0);
  });

  testWidgets('StoreProxyProvider throws when dependency is missing', (
    tester,
  ) async {
    await tester.pumpWidget(
      StoreProxyProvider<EdgeLabelStore, EdgeDependentStore>(
        create: (context, dependency) => EdgeDependentStore(dependency),
        child: const SizedBox.shrink(),
      ),
    );

    expect(tester.takeException(), isA<StateError>());
  });

  testWidgets('StoreProxyProvider default replacement disposes old child', (
    tester,
  ) async {
    final first = EdgeLabelStore('first');
    final second = EdgeLabelStore('second');
    final children = <EdgeDependentStore>[];

    Widget buildTree(EdgeLabelStore parent) {
      return ltr(
        StoreProvider<EdgeLabelStore>.value(
          value: parent,
          child: StoreProxyProvider<EdgeLabelStore, EdgeDependentStore>(
            create: (context, dependency) {
              final child = EdgeDependentStore(dependency);
              children.add(child);
              return child;
            },
            child: Builder(
              builder: (context) {
                return Text(context.watch<EdgeDependentStore>().state);
              },
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildTree(first));
    await tester.pumpWidget(buildTree(second));
    await tester.pump();

    expect(children, hasLength(2));
    expect(children.first.isDisposed, isTrue);
    expect(children.last.isDisposed, isFalse);
    expect(find.text('second'), findsOneWidget);

    first.dispose();
    second.dispose();
  });

  testWidgets(
      'StoreProxyProvider update does not run on dependency state change', (
    tester,
  ) async {
    final first = EdgeLabelStore('first');
    final second = EdgeLabelStore('second');
    EdgeRebindStore? child;

    Widget buildTree(EdgeLabelStore parent) {
      return ltr(
        StoreProvider<EdgeLabelStore>.value(
          value: parent,
          child: StoreProxyProvider<EdgeLabelStore, EdgeRebindStore>(
            create: (context, dependency) {
              child = EdgeRebindStore(dependency);
              return child!;
            },
            update: (context, dependency, store) => store.rebind(dependency),
            child: Builder(
              builder: (context) => Text(
                '${context.watch<EdgeRebindStore>().state}:${child!.updates}',
              ),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildTree(first));
    first.rename('renamed');
    await tester.pump();

    expect(find.text('first:0'), findsOneWidget);

    await tester.pumpWidget(buildTree(second));
    await tester.pump();

    expect(find.text('second:1'), findsOneWidget);

    first.dispose();
    second.dispose();
  });

  testWidgets('ForgeListener filters effects by type and stops after dispose', (
    tester,
  ) async {
    final store = EdgeCounterStore();
    final effects = <String>[];

    await tester.pumpWidget(
      StoreProvider<EdgeCounterStore>.value(
        value: store,
        child: ForgeListener<EdgeCounterStore, String>(
          onEffect: (context, effect) => effects.add(effect),
          child: const SizedBox.shrink(),
        ),
      ),
    );

    store
      ..send(1)
      ..send('ok');
    await tester.pump();

    expect(effects, ['ok']);

    await tester.pumpWidget(const SizedBox.shrink());

    store.send('late');
    await tester.pump();

    expect(effects, ['ok']);
    store.dispose();
  });

  testWidgets('ForgeBuilder ignores queued store update after widget disposal',
      (
    tester,
  ) async {
    final store = EdgeCounterStore();

    await tester.pumpWidget(
      ltr(
        StoreProvider<EdgeCounterStore>.value(
          value: store,
          child: ForgeBuilder<EdgeCounterStore, int>(
            builder: (context, state, store) => Text('$state'),
          ),
        ),
      ),
    );

    store.incrementAsync();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    expect(tester.takeException(), isNull);
    store.dispose();
  });

  test('StoreListenableAdapter supports duplicate listeners independently', () {
    final store = EdgeCounterStore();
    final listenable = store.asListenable();
    var calls = 0;
    void listener() => calls++;

    listenable
      ..addListener(listener)
      ..addListener(listener);

    store.increment();

    expect(calls, 2);

    listenable.removeListener(listener);
    store.increment();

    expect(calls, 3);

    listenable.dispose();
    store.increment();

    expect(calls, 3);
    store.dispose();
  });
}
