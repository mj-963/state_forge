import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as rp;
import 'package:flutter_bloc/flutter_bloc.dart' as bloc;
import 'package:state_forge/state_forge.dart';
import 'dart:async';

// --- Models ---
class MassiveState {
  final List<int> values;
  const MassiveState(this.values);
}

// --- StateForge ---
class SFMassiveStore extends Store<MassiveState> {
  SFMassiveStore() : super(MassiveState(List.generate(5000, (i) => 0)));

  void updateIndex(int index) {
    final newValues = List<int>.from(state.values);
    newValues[index]++;
    emitSync(MassiveState(newValues));
  }
}

// --- BLoC ---
class BlocMassiveStore extends bloc.Cubit<MassiveState> {
  BlocMassiveStore() : super(MassiveState(List.generate(5000, (i) => 0)));

  void updateIndex(int index) {
    final newValues = List<int>.from(state.values);
    newValues[index]++;
    emit(MassiveState(newValues));
  }
}

// --- Riverpod ---
final rpMassiveProvider =
    rp.NotifierProvider<RPMassive, MassiveState>(RPMassive.new);

class RPMassive extends rp.Notifier<MassiveState> {
  @override
  MassiveState build() => MassiveState(List.generate(5000, (i) => 0));

  void updateIndex(int index) {
    final newValues = List<int>.from(state.values);
    newValues[index]++;
    state = MassiveState(newValues);
  }
}

class MassiveListTest extends StatefulWidget {
  final String framework;
  const MassiveListTest({super.key, required this.framework});

  @override
  State<MassiveListTest> createState() => _MassiveListTestState();
}

class _MassiveListTestState extends State<MassiveListTest> {
  bool _isRunning = false;
  Timer? _timer;
  int _totalIterations = 0;

  void _toggle() {
    setState(() {
      _isRunning = !_isRunning;
      if (_isRunning) {
        _totalIterations = 0;
        debugPrint(
            '[Test 1] Massive list stress started (${widget.framework})');
        _timer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
          _totalIterations++;
          const index = 4999;
          _triggerUpdate(index);
        });
      } else {
        debugPrint(
            '[Test 1] Massive list stress stopped. Total: $_totalIterations updates');
        _timer?.cancel();
      }
    });
  }

  void _triggerUpdate(int index) {
    if (widget.framework == 'StateForge') {
      _sfStore.updateIndex(index);
    } else if (widget.framework == 'BLoC') {
      _blocStore.updateIndex(index);
    }
  }

  late SFMassiveStore _sfStore;
  late BlocMassiveStore _blocStore;

  @override
  void initState() {
    super.initState();
    _sfStore = SFMassiveStore();
    _blocStore = BlocMassiveStore();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sfStore.dispose();
    _blocStore.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _wrapWithProvider(
      child: Scaffold(
        appBar:
            AppBar(title: Text('Test 1: Massive List (${widget.framework})')),
        body: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                  'Optimized with RepaintBoundaries. Scroll should be smooth even during stress.'),
            ),
            Expanded(
              child: _buildList(),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _toggle,
                style: ElevatedButton.styleFrom(
                    backgroundColor: _isRunning ? Colors.red : Colors.green),
                child:
                    Text(_isRunning ? 'Stop Stress Test' : 'Start Stress Test'),
              ),
            ),
            if (widget.framework == 'Riverpod')
              _RPTrigger(isRunning: _isRunning),
          ],
        ),
      ),
    );
  }

  Widget _wrapWithProvider({required Widget child}) {
    if (widget.framework == 'StateForge') {
      return StoreProvider<SFMassiveStore>.value(value: _sfStore, child: child);
    } else if (widget.framework == 'BLoC') {
      return bloc.BlocProvider<BlocMassiveStore>.value(
          value: _blocStore, child: child);
    }
    return child;
  }

  Widget _buildList() {
    return ListView.builder(
      itemCount: 5000,
      itemExtent: 50, // Added itemExtent to optimize ListView layout math
      itemBuilder: (context, index) {
        // Wrap every item in a RepaintBoundary to isolate graphics updates
        return RepaintBoundary(
          child: _buildFrameworkSelector(index),
        );
      },
    );
  }

  Widget _buildFrameworkSelector(int index) {
    if (widget.framework == 'StateForge') {
      return ForgeSelector<SFMassiveStore, MassiveState, int>(
        key: ValueKey('sf_$index'),
        select: (s) => s.values[index],
        builder: (ctx, val, _) => _ItemTile(index: index, value: val),
      );
    } else if (widget.framework == 'BLoC') {
      return bloc.BlocSelector<BlocMassiveStore, MassiveState, int>(
        key: ValueKey('bloc_$index'),
        selector: (s) => s.values[index],
        builder: (ctx, val) => _ItemTile(index: index, value: val),
      );
    } else {
      return rp.Consumer(
        key: ValueKey('rp_$index'),
        builder: (context, ref, _) {
          final val =
              ref.watch(rpMassiveProvider.select((s) => s.values[index]));
          return _ItemTile(index: index, value: val);
        },
      );
    }
  }
}

class _RPTrigger extends rp.ConsumerStatefulWidget {
  final bool isRunning;
  const _RPTrigger({required this.isRunning});
  @override
  rp.ConsumerState<_RPTrigger> createState() => _RPTriggerState();
}

class _RPTriggerState extends rp.ConsumerState<_RPTrigger> {
  Timer? _timer;
  @override
  void didUpdateWidget(_RPTrigger old) {
    super.didUpdateWidget(old);
    if (widget.isRunning != old.isRunning) {
      if (widget.isRunning) {
        _timer = Timer.periodic(const Duration(milliseconds: 16), (_) {
          ref.read(rpMassiveProvider.notifier).updateIndex(4999);
        });
      } else {
        _timer?.cancel();
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _ItemTile extends StatelessWidget {
  final int index;
  final int value;
  const _ItemTile({required this.index, required this.value});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      title: Text('Item $index'),
      trailing: Text('Value: $value',
          style:
              const TextStyle(fontWeight: FontWeight.bold, color: Colors.cyan)),
    );
  }
}
