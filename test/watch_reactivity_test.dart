import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:state_forge/state_forge.dart';

class CounterStore extends Store<int> {
  CounterStore() : super(0);

  void increment() => emit(state + 1);
}

void main() {
  testWidgets('context.watch rebuilds when the store emits', (tester) async {
    await tester.pumpWidget(
      StoreProvider<CounterStore>(
        create: (_) => CounterStore(),
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              final count = context.watch<CounterStore>().state;
              return Scaffold(
                body: Column(
                  children: [
                    Text('Count: $count'),
                    ElevatedButton(
                      onPressed: () => context.read<CounterStore>().increment(),
                      child: const Text('Increment'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('Count: 0'), findsOneWidget);

    await tester.tap(find.text('Increment'));
    await tester.pump();

    expect(find.text('Count: 1'), findsOneWidget);
  });
}
