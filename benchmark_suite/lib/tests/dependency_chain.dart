import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart' as bloc;
import 'package:state_forge/state_forge.dart';
import 'dart:async';

// --- StateForge Implementation ---
class SFNodeStore extends Store<int> with CompositedStore<int> {
  SFNodeStore([super.initial = 0]);

  void init(Store<int> parent) {
    watchStore(parent, (p) => emit(p.state + 1));
  }

  void increment() => emitSync(state + 1);
}

// --- BLoC Implementation ---
class BlocNodeStore extends bloc.Cubit<int> {
  BlocNodeStore([super.initial = 0]);
  StreamSubscription? _sub;

  void init(bloc.Cubit<int> parent) {
    _sub?.cancel();
    _sub = parent.stream.listen((val) => emit(val + 1));
  }

  void increment() => emit(state + 1);

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}

class DependencyChainTest extends StatefulWidget {
  final String framework;
  const DependencyChainTest({super.key, required this.framework});

  @override
  State<DependencyChainTest> createState() => _DependencyChainTestState();
}

class _DependencyChainTestState extends State<DependencyChainTest> {
  List<SFNodeStore> sfStores = [];
  List<BlocNodeStore> blocStores = [];

  @override
  void initState() {
    super.initState();
    if (widget.framework == 'StateForge') {
      debugPrint('[Test 2] Building StateForge chain (20 nodes)...');
      sfStores = List.generate(20, (_) => SFNodeStore());
      for (int i = 1; i < 20; i++) {
        sfStores[i].init(sfStores[i - 1]);
      }
    } else if (widget.framework == 'BLoC') {
      debugPrint('[Test 2] Building BLoC chain (20 nodes)...');
      blocStores = List.generate(20, (_) => BlocNodeStore());
      for (int i = 1; i < 20; i++) {
        blocStores[i].init(blocStores[i - 1]);
      }
    }
  }

  @override
  void dispose() {
    for (var s in sfStores) {
      s.dispose();
    }
    for (var b in blocStores) {
      b.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text('Test 2: Chain of 20 Stores (${widget.framework})')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Updating Node 0. Ripple effect should reach Node 19.'),
            const SizedBox(height: 32),
            _buildDisplay(),
            const SizedBox(height: 32),
            if (widget.framework != 'Riverpod')
              ElevatedButton(
                onPressed: () {
                  debugPrint('[Test 2] Triggering node 0');
                  if (widget.framework == 'StateForge') {
                    sfStores[0].increment();
                  } else if (widget.framework == 'BLoC') {
                    blocStores[0].increment();
                  }
                },
                child: const Text('Increment Node 0'),
              ),
            if (widget.framework == 'Riverpod')
              const Text('Test 2 not implemented for Riverpod in this suite.'),
          ],
        ),
      ),
    );
  }

  Widget _buildDisplay() {
    if (widget.framework == 'StateForge') {
      return StoreProvider<SFNodeStore>.value(
        value: sfStores.last,
        child: ForgeBuilder<SFNodeStore, int>(
          builder: (_, val, __) {
            debugPrint('[Test 2] Node 19 rebuilt: value = $val');
            return Text('Final Node Value: $val',
                style: const TextStyle(fontSize: 24, color: Colors.green));
          },
        ),
      );
    } else if (widget.framework == 'BLoC') {
      return bloc.BlocProvider<BlocNodeStore>.value(
        value: blocStores.last,
        child: bloc.BlocBuilder<BlocNodeStore, int>(
          builder: (_, val) {
            debugPrint('[Test 2] Node 19 rebuilt: value = $val');
            return Text('Final Node Value: $val',
                style: const TextStyle(fontSize: 24, color: Colors.blue));
          },
        ),
      );
    } else {
      return const SizedBox();
    }
  }
}
