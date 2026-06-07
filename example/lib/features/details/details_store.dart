import 'package:state_forge/state_forge.dart';
import '../../core/api_client.dart';
import '../../core/models/show.dart';

typedef ShowDetails = (Show show, List<CastMember> cast);

class DetailsStore extends Store<AsyncState<ShowDetails>> {
  DetailsStore(this._api, this.showId) : super(const Idle());

  final ApiClient _api;
  final int showId;

  Future<void> load() async {
    emit(const Loading());
    await guard(() async {
      final details = await _api.getShowDetails(showId);
      emit(Success(details));
    });
  }
}
