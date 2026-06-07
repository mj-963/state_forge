import 'package:flutter/material.dart';
import 'package:state_forge/state_forge.dart';
import '../../core/models/show.dart';
import '../cart/cart_store.dart';
import '../cart/cart_page.dart';
import '../details/details_page.dart';
import 'discovery_store.dart';

class DiscoveryPage extends StatefulWidget {
  const DiscoveryPage({super.key});

  @override
  State<DiscoveryPage> createState() => _DiscoveryPageState();
}

class _DiscoveryPageState extends State<DiscoveryPage> with ForgeEffectListener {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    listenToEffect<CartStore, String>((message) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 1)),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ForgeMovies'),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CartPage()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search movies...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => context.read<DiscoveryStore>().search(v),
            ),
          ),
          Expanded(
            child: ForgeBuilder<DiscoveryStore, AsyncState<List<Show>>>(
              builder: (context, state, store) {
                return state.when(
                  idle: () => const SizedBox(),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  failure: (e) => Center(child: Text('Error: $e')),
                  success: (shows) => GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.7,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: shows.length,
                    itemBuilder: (context, index) {
                      final show = shows[index];
                      return _MovieCard(show: show);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MovieCard extends StatelessWidget {
  const _MovieCard({required this.show});
  final Show show;

  @override
  Widget build(BuildContext context) {
    final isWishlisted = context.select<CartStore, CartState, bool>(
      (s) => s.contains(show.id)
    );

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DetailsPage(showId: show.id)),
      ),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (show.image != null)
              Image.network(show.image!, fit: BoxFit.cover)
            else
              const Center(child: Icon(Icons.movie, size: 50)),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.black54,
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      show.name,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      show.genres.join(', '),
                      style: const TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                icon: Icon(
                  isWishlisted ? Icons.favorite : Icons.favorite_border,
                  color: isWishlisted ? Colors.red : Colors.white,
                ),
                onPressed: () => context.read<CartStore>().toggle(show),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
