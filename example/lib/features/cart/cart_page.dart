import 'package:flutter/material.dart';
import 'package:state_forge/state_forge.dart';
import 'cart_store.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cartStore = context.watch<CartStore>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wishlist'),
        actions: [
          if (cartStore.canUndo)
            IconButton(icon: const Icon(Icons.undo), onPressed: cartStore.undo),
          if (cartStore.canRedo)
            IconButton(icon: const Icon(Icons.redo), onPressed: cartStore.redo),
        ],
      ),
      body: ForgeBuilder<CartStore, CartState>(
        builder: (context, state, store) {
          if (state.items.isEmpty) {
            return const Center(child: Text('Your wishlist is empty'));
          }
          return ListView.builder(
            itemCount: state.items.length,
            itemBuilder: (context, index) {
              final show = state.items[index];
              return ListTile(
                leading: show.image != null 
                  ? Image.network(show.image!) 
                  : const Icon(Icons.movie),
                title: Text(show.name),
                subtitle: Text(show.genres.join(', ')),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => store.toggle(show),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
