import 'package:flutter/material.dart';
import 'package:state_forge/state_forge.dart';
import 'dart:async';
import 'dart:math';

class ChaosStore extends Store<int> {
  ChaosStore() : super(0);

  void startChaos() {
    debugPrint('[ChaosStore] Starting 100 parallel async calls...');
    for (int i = 0; i < 100; i++) {
      _runAsync(i);
    }
  }

  Future<void> _runAsync(int id) async {
    await guard(() async {
      await Future.delayed(Duration(milliseconds: Random().nextInt(500)));
      emit(state + 1);
      effect('Effect from $id');
    });
  }
}

class AsyncChaosTest extends StatefulWidget {
  const AsyncChaosTest({super.key});

  @override
  State<AsyncChaosTest> createState() => _AsyncChaosTestState();
}

class _AsyncChaosTestState extends State<AsyncChaosTest> {
  bool _isBotRunning = false;
  Timer? _botTimer;
  int _cycleCount = 0;

  void _toggleBot() {
    setState(() {
      _isBotRunning = !_isBotRunning;
      if (_isBotRunning) {
        debugPrint('[Test 3] Navigation stress started');
        _botTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
          _cycleCount++;
          if (mounted) {
            if (_cycleCount % 2 == 1) {
              debugPrint('[Test 3] Navigating in (cycle $_cycleCount)');
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const _ChaosContainer()));
            } else {
              debugPrint('[Test 3] Navigating out (cycle $_cycleCount)');
              Navigator.pop(context);
            }
          }
        });
      } else {
        debugPrint(
            '[Test 3] Navigation stress stopped. Total cycles: $_cycleCount');
        _botTimer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _botTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test 3: Async Chaos & Disposal')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
                'Bot will navigate IN and OUT of a heavy page every 300ms.'),
            const Text('Each page entry fires 100 async calls.'),
            const SizedBox(height: 32),
            Text('Cycles: $_cycleCount',
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _toggleBot,
              style: ElevatedButton.styleFrom(
                  backgroundColor: _isBotRunning ? Colors.red : Colors.blue),
              child: Text(_isBotRunning
                  ? 'Stop Navigation Stress'
                  : 'Start Navigation Stress'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChaosContainer extends StatelessWidget {
  const _ChaosContainer();

  @override
  Widget build(BuildContext context) {
    // PROVIDER IS NOW ABOVE THE VIEW
    return StoreProvider<ChaosStore>(
      create: (context) => ChaosStore()..startChaos(),
      child: const _ChaosView(),
    );
  }
}

class _ChaosView extends StatefulWidget {
  const _ChaosView();

  @override
  State<_ChaosView> createState() => _ChaosViewState();
}

class _ChaosViewState extends State<_ChaosView> with ForgeEffectListener {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    listenToEffect<ChaosStore, String>((e) {
      // Listening to chaos effects
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Async Work Page')),
      body: ForgeBuilder<ChaosStore, int>(
        builder: (_, count, __) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('Updates in this session: $count'),
            ],
          ),
        ),
      ),
    );
  }
}
