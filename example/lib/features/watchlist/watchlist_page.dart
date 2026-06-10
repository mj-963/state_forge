import 'package:flutter/material.dart';
import 'package:state_forge/state_forge.dart';
import 'watchlist_store.dart';

class WatchlistPage extends StatelessWidget {
  const WatchlistPage({super.key});

  @override
  Widget build(BuildContext context) {
    final watchlistStore = context.watch<WatchlistStore>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Watchlist'),
        actions: [
          if (watchlistStore.canUndo)
            IconButton(
              icon: const Icon(Icons.undo),
              onPressed: watchlistStore.undo,
            ),
          if (watchlistStore.canRedo)
            IconButton(
              icon: const Icon(Icons.redo),
              onPressed: watchlistStore.redo,
            ),
        ],
      ),
      body: ForgeBuilder<WatchlistStore, WatchlistState>(
        builder: (context, state, store) {
          if (state.items.isEmpty) {
            return const Center(child: Text('Your watchlist is empty'));
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
