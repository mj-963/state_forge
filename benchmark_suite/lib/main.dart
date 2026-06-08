import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as rp;
import 'tests/massive_list.dart';
import 'tests/dependency_chain.dart';
import 'tests/async_chaos.dart';

void main() {
  runApp(const rp.ProviderScope(child: BenchmarkApp()));
}

class BenchmarkApp extends StatefulWidget {
  const BenchmarkApp({super.key});

  @override
  State<BenchmarkApp> createState() => _BenchmarkAppState();
}

class _BenchmarkAppState extends State<BenchmarkApp> {
  String _currentFramework = 'StateForge';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('StateForge Benchmark Suite'),
          actions: [
            PopupMenuButton<String>(
              onSelected: (v) => setState(() => _currentFramework = v),
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                    value: 'StateForge', child: Text('StateForge')),
                const PopupMenuItem(value: 'Riverpod', child: Text('Riverpod')),
                const PopupMenuItem(value: 'BLoC', child: Text('BLoC')),
              ],
            ),
          ],
        ),
        body: _Dashboard(framework: _currentFramework),
      ),
    );
  }
}

class _Dashboard extends StatelessWidget {
  final String framework;
  const _Dashboard({required this.framework});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Active Framework: $framework',
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.cyan)),
        const Divider(height: 40),
        _TestCard(
          title: 'Test 1: Massive List (5,000 Items)',
          subtitle: 'Selective rebuild stress with 5,000 list rows.',
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => MassiveListTest(framework: framework))),
        ),
        _TestCard(
          title: 'Test 2: Dependency Chain (20 Nodes)',
          subtitle: 'Propagation through a 20-store dependency chain.',
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => DependencyChainTest(framework: framework))),
        ),
        _TestCard(
          title: 'Test 3: Async Chaos & Disposal',
          subtitle: 'Rapid navigation while stores run async work.',
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AsyncChaosTest())),
        ),
        const SizedBox(height: 40),
        const Text('Instructions:',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const Text('1. Pick a framework from the top-right menu.'),
        const Text('2. Run a test.'),
        const Text('3. Compare the UI smoothness and console logs.'),
      ],
    );
  }
}

class _TestCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _TestCard(
      {required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}
