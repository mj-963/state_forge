import 'dart:async';
import 'package:state_forge/state_forge.dart';
import '../../core/api_client.dart';
import '../../core/models/show.dart';

class DiscoveryStore extends Store<AsyncState<List<Show>>> {
  DiscoveryStore(this._api) : super(const Idle());

  final ApiClient _api;
  Timer? _debounce;

  Future<void> load() async {
    emit(const Loading());
    try {
      await guard(() async {
        final shows = await _api.getShows();
        emit(Success(shows));
      });
    } catch (error) {
      emit(Failure(error));
    }
  }

  void search(String query) {
    if (query.isEmpty) {
      load();
      return;
    }

    _debounce?.cancel();
    _debounce = keep(
      Timer(const Duration(milliseconds: 500), () async {
        emit(const Loading());
        try {
          await guard(() async {
            final results = await _api.searchShows(query);
            emit(Success(results));
          });
        } catch (error) {
          emit(Failure(error));
        }
      }),
    );
  }
}
