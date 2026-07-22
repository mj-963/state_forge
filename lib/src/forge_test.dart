import 'dart:async';
import 'package:flutter_test/flutter_test.dart' as ft;
import 'package:meta/meta.dart';
import 'package:state_forge_core/state_forge_core.dart' as core;
import 'store.dart';

/// A utility function for testing [Store] state transitions in a
/// declarative and expressive way.
///
/// [forgeTest] captures **every** state change emitted by the store during the
/// execution of the [act] function and compares it to the [expect] list.
///
/// Transitions are captured through the global observer hook, which fires
/// synchronously on each `emit`/`emitSync`. This means intermediate states are
/// captured even when several emits happen in the same synchronous turn (the
/// UI still coalesces those into a single rebuild — only test observation is
/// per-emit). This matches the documented "captures every state change"
/// contract and mirrors `bloc_test` semantics.
///
/// Example:
/// ```dart
/// forgeTest<AuthStore, AsyncState<String>>(
///   'emits [Loading, Success] when login is called',
///   build: () => AuthStore(),
///   act: (store) => store.login('user', 'pw'),
///   expect: () => [isA<Loading>(), isA<Success>()],
/// );
/// ```
@isTest
void forgeTest<T extends Store<S>, S>(
  String description, {
  /// A function that returns a fresh instance of the store to test.
  required T Function() build,

  /// A function where the actual interaction with the store happens.
  dynamic Function(T store)? act,

  /// An optional duration to wait before checking expectations.
  /// Useful for complex async logic or debounce timers.
  Duration? wait,

  /// A function that returns a list of expected states or matchers.
  Iterable<dynamic> Function()? expect,

  /// An optional callback for additional assertions using the store instance.
  void Function(T store)? verify,
}) {
  ft.test(description, () async {
    final store = build();
    final target = store;
    final states = <S>[];

    // Capture every emit synchronously via the observer hook (fires before
    // microtask coalescing) so intermediate states are never dropped. Any
    // previously installed observer is preserved and restored afterwards.
    final previousObserver = core.StateForge.observer;
    core.StateForge.observer = core.ForgeObserver(
      onCreate: previousObserver?.handleCreate,
      onDispose: previousObserver?.handleDispose,
      onEmit: (emittingStore, oldState, newState) {
        if (identical(emittingStore, target)) {
          states.add(newState as S);
        }
        previousObserver?.handleEmit(emittingStore, oldState, newState);
      },
      onEffect: previousObserver?.handleEffect,
      onError: previousObserver?.handleError,
    );

    try {
      final dynamic result = act?.call(store);
      if (result is Future) {
        await result;
      }

      if (wait != null) {
        await Future.delayed(wait);
      } else {
        await Future.delayed(Duration.zero);
      }

      if (expect != null) {
        final expected = expect();
        final actual = states;

        if (expected.length != actual.length) {
          ft.fail(
              'Expected ${expected.length} states, but got ${actual.length}.\n'
              'Actual states: $actual\n'
              'Expected states: $expected');
        }

        for (int i = 0; i < expected.length; i++) {
          final matcher = expected.elementAt(i);
          if (matcher is ft.Matcher) {
            ft.expect(actual[i], matcher,
                reason: 'State at index $i does not match');
          } else {
            ft.expect(actual[i], ft.equals(matcher),
                reason: 'State at index $i does not match');
          }
        }
      }

      verify?.call(store);
    } finally {
      core.StateForge.observer = previousObserver;
      store.dispose();
    }
  });
}
