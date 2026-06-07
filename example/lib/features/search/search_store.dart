import 'dart:async';
import 'package:state_forge/state_forge.dart';

class SearchStore extends Store<AsyncState<List<String>>> {
  SearchStore() : super(const Idle());

  Timer? _debounceTimer;

  void search(String query) {
    if (query.isEmpty) {
      emit(const Idle());
      return;
    }

    // Cancel existing timer
    _debounceTimer?.cancel();

    // Debounce for 500ms
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      emit(const Loading());

      try {
        await guard(() async {
          // Simulating search API
          await Future.delayed(const Duration(seconds: 1));

          final results =
              [
                    'StateForge',
                    'Flutter',
                    'Riverpod',
                    'BLoC',
                    'Signals',
                    'State Beacon',
                  ]
                  .where((s) => s.toLowerCase().contains(query.toLowerCase()))
                  .toList();

          emit(Success(results));
        });
      } catch (error) {
        emit(Failure(error));
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
