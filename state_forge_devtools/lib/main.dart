import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:flutter/material.dart';
import 'dart:async';

void main() {
  runApp(const StateForgeDevToolsApp());
}

class StateForgeDevToolsApp extends StatelessWidget {
  const StateForgeDevToolsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const DevToolsExtension(
      child: StateForgeDashboard(),
    );
  }
}

class StateForgeDashboard extends StatefulWidget {
  const StateForgeDashboard({super.key});

  @override
  State<StateForgeDashboard> createState() => _StateForgeDashboardState();
}

class _StateForgeDashboardState extends State<StateForgeDashboard> {
  List<dynamic> _stores = [];
  List<dynamic> _history = [];
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refresh();
    _refreshTimer =
        Timer.periodic(const Duration(seconds: 1), (_) => _refresh());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final storesResponse =
          await serviceManager.callServiceExtensionOnMainIsolate(
        'ext.state_forge.getStores',
      );
      final historyResponse =
          await serviceManager.callServiceExtensionOnMainIsolate(
        'ext.state_forge.getHistory',
      );

      setState(() {
        _stores = storesResponse.json?['stores'] ?? [];
        _history = historyResponse.json?['history'] ?? [];
      });
    } catch (e) {
      // App might not be running or extension not registered yet
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: const TabBar(
          tabs: [
            Tab(text: 'Active Stores', icon: Icon(Icons.storage)),
            Tab(text: 'Event History', icon: Icon(Icons.history)),
          ],
        ),
        body: TabBarView(
          children: [
            _StoresTab(stores: _stores),
            _HistoryTab(history: _history),
          ],
        ),
      ),
    );
  }
}

class _StoresTab extends StatelessWidget {
  final List<dynamic> stores;
  const _StoresTab({required this.stores});

  @override
  Widget build(BuildContext context) {
    if (stores.isEmpty) {
      return const Center(child: Text('No active stores found.'));
    }

    return ListView.builder(
      itemCount: stores.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final store = stores[index];
        return Card(
          child: ExpansionTile(
            leading:
                const Icon(Icons.settings_input_component, color: Colors.blue),
            title: Text(store['type'] ?? 'Unknown Store',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('ID: ${store['id']}'),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Current State:',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      color: Colors.black12,
                      child: Text(store['state'] ?? 'null',
                          style: const TextStyle(fontFamily: 'monospace')),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HistoryTab extends StatelessWidget {
  final List<dynamic> history;
  const _HistoryTab({required this.history});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const Center(child: Text('No events recorded yet.'));
    }

    return ListView.separated(
      itemCount: history.length,
      padding: const EdgeInsets.all(16),
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final event = history[history.length - 1 - index]; // Show newest first
        final isEffect = event.containsKey('effect');
        final time =
            DateTime.fromMillisecondsSinceEpoch(event['timestamp'] ?? 0);

        return ListTile(
          leading: Icon(
            isEffect ? Icons.bolt : Icons.sync,
            color: isEffect ? Colors.orange : Colors.green,
          ),
          title: Text(
            isEffect
                ? '${event['storeType']} → Effect: ${event['effect']}'
                : '${event['storeType']} → Transition',
            style: const TextStyle(fontSize: 13),
          ),
          subtitle: isEffect
              ? Text('${time.hour}:${time.minute}:${time.second}')
              : Text('${event['oldState']} → ${event['newState']}',
                  maxLines: 2, overflow: TextOverflow.ellipsis),
        );
      },
    );
  }
}
