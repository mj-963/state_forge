import 'package:state_forge_core/state_forge_core.dart';

void main() async {
  StateForge.observer = ForgeObserver(
    onEmit: (store, previous, next) {
      print('${store.runtimeType}: $previous -> $next');
    },
  );

  final counter = CounterStore();
  counter.increment();

  await counter.loadLabel();
  counter.dispose();
}

final class CounterStore extends Store<AsyncState<int>> {
  CounterStore() : super(const Success(0));

  void increment() {
    final current = state.data ?? 0;
    emit(Success(current + 1));
  }

  Future<void> loadLabel() async {
    emit(const Loading());
    await guard(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      emit(const Success(42));
    });
  }
}
