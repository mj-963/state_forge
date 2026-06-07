import 'package:state_forge/state_forge.dart';
import '../../core/models/show.dart';

class CartState {
  const CartState({this.items = const []});
  final List<Show> items;

  bool contains(int id) => items.any((i) => i.id == id);
}

class CartStore extends Store<CartState> with UndoableStore<CartState>, PersistableStore<CartState> {
  CartStore() : super(const CartState());

  @override
  String get storageKey => 'wishlist';

  void toggle(Show show) {
    final newItems = List<Show>.from(state.items);
    if (state.contains(show.id)) {
      newItems.removeWhere((i) => i.id == show.id);
      effect('Removed ${show.name} from Wishlist');
    } else {
      newItems.add(show);
      effect('Added ${show.name} to Wishlist');
    }
    emit(CartState(items: newItems));
    persist();
  }

  @override
  CartState fromJson(Map<String, dynamic> json) {
    // Basic implementation for demo
    return const CartState();
  }

  @override
  Map<String, dynamic> toJson(CartState state) {
    return {};
  }
}
