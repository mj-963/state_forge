import 'package:flutter/material.dart';
import 'package:state_forge/state_forge.dart';
import '../../core/api_client.dart';
import 'details_store.dart';
import '../watchlist/watchlist_store.dart';

class DetailsPage extends StatelessWidget {
  const DetailsPage({super.key, required this.showId});
  final int showId;

  @override
  Widget build(BuildContext context) {
    // Providing a screen-scoped store that auto-disposes
    return StoreProvider<DetailsStore>(
      create: (context) => DetailsStore(ApiClient(), showId)..load(),
      child: const _DetailsView(),
    );
  }
}

class _DetailsView extends StatelessWidget {
  const _DetailsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ForgeBuilder<DetailsStore, AsyncState<ShowDetails>>(
        builder: (context, state, store) {
          return state.when(
            idle: () => const SizedBox(),
            loading: () => const Center(child: CircularProgressIndicator()),
            failure: (e) => Center(child: Text('Error: $e')),
            success: (details) {
              final (show, cast) = details;
              return CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 300,
                    pinned: true,
                    flexibleSpace: FlexibleSpaceBar(
                      title: Text(show.name),
                      background: show.image != null
                          ? Image.network(show.image!, fit: BoxFit.cover)
                          : const Center(child: Icon(Icons.movie)),
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.favorite_border),
                        onPressed: () =>
                            context.read<WatchlistStore>().toggle(show),
                      ),
                    ],
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber),
                              const SizedBox(width: 4),
                              Text(
                                '${show.rating}/10',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Summary',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(show.summary),
                          const SizedBox(height: 24),
                          Text(
                            'Cast',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final member = cast[index];
                      return ListTile(
                        leading: member.image != null
                            ? CircleAvatar(
                                backgroundImage: NetworkImage(member.image!),
                              )
                            : const CircleAvatar(child: Icon(Icons.person)),
                        title: Text(member.personName),
                        subtitle: Text('as ${member.characterName}'),
                      );
                    }, childCount: cast.length),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
