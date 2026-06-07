import 'dart:async';
import 'package:flutter_test/flutter_test.dart' as ft;
import 'package:meta/meta.dart';
import 'store.dart';

/// A utility function for testing [Store] state transitions in a
/// declarative and expressive way.
///
/// [forgeTest] captures every state change emitted by the store during
/// the execution of the [act] function and compares it to the [expect] list.
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
    final states = <S>[];

    void listener() {
      states.add(store.state);
    }

    store.addListener(listener);

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
      store.removeListener(listener);
      store.dispose();
    }
  });
}
