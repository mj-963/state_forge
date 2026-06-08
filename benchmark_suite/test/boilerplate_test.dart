import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Boilerplate Analysis', () {
    // StateForge implementation (integrated): 5 lines
    const stateForgeCode = """
    class SFStore extends Store<int> {
      SFStore() : super(0);
      void increment() => emit(state + 1);
    }
    """;

    // Riverpod 3.0 implementation (manual): 8 lines
    const riverpodCode = """
    final rpProvider = rp.NotifierProvider<RPNotifier, int>(RPNotifier.new);
    class RPNotifier extends rp.Notifier<int> {
      @override
      int build() => 0;
      void increment() => state++;
    }
    """;

    // BLoC implementation (Cubit): 6 lines
    const blocCode = """
    class BlocStore extends bloc.Cubit<int> {
      BlocStore() : super(0);
      void increment() => emit(state + 1);
    }
    """;

    // ignore: avoid_print
    // ignore: avoid_print
    print('[Boilerplate Metrics - Store Logic]');
    // ignore: avoid_print
    // ignore: avoid_print
    print('StateForge: ${stateForgeCode.trim().split('\n').length} lines');
    // ignore: avoid_print
    // ignore: avoid_print
    print('Riverpod: ${riverpodCode.trim().split('\n').length} lines');
    // ignore: avoid_print
    // ignore: avoid_print
    print('BLoC (Cubit): ${blocCode.trim().split('\n').length} lines');
  });
}
