import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:state_forge/state_forge.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as rp;
import 'package:flutter_bloc/flutter_bloc.dart' as bloc;

class BenchmarkState {
  final int counter;
  final int unrelated;
  const BenchmarkState(this.counter, this.unrelated);
}

// StateForge
class SFStore extends Store<BenchmarkState> {
  SFStore() : super(const BenchmarkState(0, 0));
  void update() => emit(BenchmarkState(state.counter, state.unrelated + 1));
}

// BLoC
class BlocStore extends bloc.Cubit<BenchmarkState> {
  BlocStore() : super(const BenchmarkState(0, 0));
  void update() => emit(BenchmarkState(state.counter, state.unrelated + 1));
}

// Riverpod
final rpProvider =
    rp.NotifierProvider<RPNotifier, BenchmarkState>(RPNotifier.new);

class RPNotifier extends rp.Notifier<BenchmarkState> {
  @override
  BenchmarkState build() => const BenchmarkState(0, 0);
  void update() => state = BenchmarkState(state.counter, state.unrelated + 1);
}

void main() {
  const int iterations = 1000;

  testWidgets('StateForge Rebuild Efficiency Benchmark', (tester) async {
    int rebuilds = 0;
    final store = SFStore();

    await tester.pumpWidget(
      StoreProvider<SFStore>.value(
        value: store,
        child: Builder(builder: (context) {
          ForgeContext(context)
              .select<SFStore, BenchmarkState, int>((s) => s.counter);
          rebuilds++;
          return const SizedBox();
        }),
      ),
    );

    expect(rebuilds, 1);

    for (int i = 0; i < iterations; i++) {
      store.update();
    }
    await tester.pump(Duration.zero);

    // ignore: avoid_print
    print(
        '[StateForge] Rebuilds after $iterations unrelated updates: $rebuilds');
    expect(rebuilds, 1);
  });

  testWidgets('Riverpod Rebuild Efficiency Benchmark', (tester) async {
    int rebuilds = 0;
    final container = rp.ProviderContainer();

    await tester.pumpWidget(
      rp.UncontrolledProviderScope(
        container: container,
        child: rp.Consumer(builder: (context, ref, _) {
          ref.watch(rpProvider.select((s) => s.counter));
          rebuilds++;
          return const SizedBox();
        }),
      ),
    );

    expect(rebuilds, 1);

    for (int i = 0; i < iterations; i++) {
      container.read(rpProvider.notifier).update();
    }
    await tester.pump(Duration.zero);

    // ignore: avoid_print
    print('[Riverpod] Rebuilds after $iterations unrelated updates: $rebuilds');
    expect(rebuilds, 1);
  });

  testWidgets('BLoC Rebuild Efficiency Benchmark', (tester) async {
    int rebuilds = 0;
    final cubit = BlocStore();

    await tester.pumpWidget(
      bloc.BlocProvider<BlocStore>.value(
        value: cubit,
        child: bloc.BlocSelector<BlocStore, BenchmarkState, int>(
          selector: (s) => s.counter,
          builder: (context, state) {
            rebuilds++;
            return const SizedBox();
          },
        ),
      ),
    );

    expect(rebuilds, 1);

    for (int i = 0; i < iterations; i++) {
      cubit.update();
    }
    await tester.pump(Duration.zero);

    // ignore: avoid_print
    print('[BLoC] Rebuilds after $iterations unrelated updates: $rebuilds');
    expect(rebuilds, 1);
  });
}
