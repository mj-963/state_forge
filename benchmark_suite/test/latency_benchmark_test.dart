import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:state_forge/state_forge.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as rp;
import 'package:flutter_bloc/flutter_bloc.dart' as bloc;

class LatencyState {
  final int count;
  const LatencyState(this.count);
}

class SFStore extends Store<LatencyState> {
  SFStore() : super(const LatencyState(0));
  void increment() => emitSync(LatencyState(state.count + 1));
}

class BlocStore extends bloc.Cubit<LatencyState> {
  BlocStore() : super(const LatencyState(0));
  void increment() => emit(LatencyState(state.count + 1));
}

final rpProvider =
    rp.NotifierProvider<RPNotifier, LatencyState>(RPNotifier.new);

class RPNotifier extends rp.Notifier<LatencyState> {
  @override
  LatencyState build() => const LatencyState(0);
  void increment() => state = LatencyState(state.count + 1);
}

void main() {
  const int iterations = 1000;

  // StateForge logs every transition when assertions are enabled, which is the
  // case under `flutter test`. BLoC and Riverpod log nothing, so leave it off
  // to compare like with like.
  setUp(() => StateForge.debugMode = false);
  tearDown(() => StateForge.debugMode = true);

  testWidgets('StateForge Latency Benchmark', (tester) async {
    final store = SFStore();
    await tester.pumpWidget(
      StoreProvider<SFStore>.value(
        value: store,
        child: Builder(builder: (context) {
          ForgeContext(context).watch<SFStore>();
          return const SizedBox();
        }),
      ),
    );

    final stopwatch = Stopwatch()..start();
    for (int i = 0; i < iterations; i++) {
      store.increment();
      await tester.pump(Duration.zero);
    }
    stopwatch.stop();
    // ignore: avoid_print
    print(
        '[StateForge] Time for $iterations updates: ${stopwatch.elapsedMilliseconds}ms');
  });

  // context.watch above rebuilds the provider itself, which is the heaviest
  // read path. ForgeBuilder subscribes at the leaf, which is the like-for-like
  // comparison against BlocBuilder and Consumer below.
  testWidgets('StateForge (ForgeBuilder) Latency Benchmark', (tester) async {
    final store = SFStore();
    await tester.pumpWidget(
      StoreProvider<SFStore>.value(
        value: store,
        child: ForgeBuilder<SFStore, LatencyState>(
          builder: (context, state, _) => const SizedBox(),
        ),
      ),
    );

    final stopwatch = Stopwatch()..start();
    for (int i = 0; i < iterations; i++) {
      store.increment();
      await tester.pump(Duration.zero);
    }
    stopwatch.stop();
    // ignore: avoid_print
    print(
        '[StateForge/ForgeBuilder] Time for $iterations updates: ${stopwatch.elapsedMilliseconds}ms');
  });

  testWidgets('Riverpod Latency Benchmark', (tester) async {
    final container = rp.ProviderContainer();
    await tester.pumpWidget(
      rp.UncontrolledProviderScope(
        container: container,
        child: rp.Consumer(builder: (context, ref, _) {
          ref.watch(rpProvider);
          return const SizedBox();
        }),
      ),
    );

    final stopwatch = Stopwatch()..start();
    for (int i = 0; i < iterations; i++) {
      container.read(rpProvider.notifier).increment();
      await tester.pump(Duration.zero);
    }
    stopwatch.stop();
    // ignore: avoid_print
    print(
        '[Riverpod] Time for $iterations updates: ${stopwatch.elapsedMilliseconds}ms');
  });

  testWidgets('BLoC Latency Benchmark', (tester) async {
    final cubit = BlocStore();
    await tester.pumpWidget(
      bloc.BlocProvider<BlocStore>.value(
        value: cubit,
        child: bloc.BlocBuilder<BlocStore, LatencyState>(
          builder: (context, state) => const SizedBox(),
        ),
      ),
    );

    final stopwatch = Stopwatch()..start();
    for (int i = 0; i < iterations; i++) {
      cubit.increment();
      await tester.pump(Duration.zero);
    }
    stopwatch.stop();
    // ignore: avoid_print
    print(
        '[BLoC] Time for $iterations updates: ${stopwatch.elapsedMilliseconds}ms');
  });
}
