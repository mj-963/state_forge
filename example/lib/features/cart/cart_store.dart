import 'dart:async';

import 'package:state_forge/state_forge.dart';
import '../../core/models/show.dart';

class CartState {
  const CartState({this.items = const []});
  final List<Show> items;

  bool contains(int id) => items.any((i) => i.id == id);
}

class CartStore extends Store<CartState>
    with UndoableStore<CartState>, PersistableStore<CartState> {
  CartStore() : super(const CartState()) {
    unawaited(hydrateOnCreate(debounce: const Duration(milliseconds: 250)));
  }

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
  }

  @override
  CartState fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    if (rawItems is! List) return const CartState();

    return CartState(
      items: rawItems
          .whereType<Map>()
          .map((item) => Show.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }

  @override
  Map<String, dynamic> toJson(CartState state) {
    return {'items': state.items.map((show) => show.toJson()).toList()};
  }
}
