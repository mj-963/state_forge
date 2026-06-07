import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:state_forge/state_forge.dart';
import 'package:state_forge_shared_preferences/state_forge_shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  tearDown(() {
    StateForge.storage = null;
  });

  test('writes, reads, and deletes JSON state', () async {
    final storage = await SharedPreferencesForgeStorage.create();

    await storage.write('settings', {
      'theme': 'dark',
      'count': 2,
    });

    expect(await storage.read('settings'), {
      'theme': 'dark',
      'count': 2,
    });

    await storage.delete('settings');
    expect(await storage.read('settings'), isNull);
  });

  test('respects custom prefixes', () async {
    final preferences = SharedPreferencesAsync();
    final storage = SharedPreferencesForgeStorage(
      preferences,
      prefix: 'custom.',
    );

    await storage.write('counter', {'value': 3});

    expect(
      jsonDecode((await preferences.getString('custom.counter'))!),
      {'value': 3},
    );
    expect(await preferences.getString('state_forge.counter'), isNull);
  });

  test('returns null for missing keys and deleting missing keys is harmless',
      () async {
    final storage = await SharedPreferencesForgeStorage.create();

    expect(await storage.read('missing'), isNull);

    await storage.delete('missing');

    expect(await storage.read('missing'), isNull);
  });

  test('round-trips nested JSON objects and lists', () async {
    final storage = await SharedPreferencesForgeStorage.create();
    final state = {
      'profile': {
        'name': 'Ada',
        'flags': ['admin', 'beta'],
      },
      'count': 4,
      'enabled': true,
    };

    await storage.write('nested', state);

    expect(await storage.read('nested'), state);
  });

  test('useSharedPreferencesStorage configures StateForge.storage', () async {
    final storage = await useSharedPreferencesStorage(prefix: 'app.');

    expect(StateForge.storage, same(storage));
  });

  test('throws a FormatException for non-object JSON values', () async {
    await SharedPreferencesAsync().setString('state_forge.bad', '[1, 2, 3]');
    final storage = await SharedPreferencesForgeStorage.create();

    expect(() => storage.read('bad'), throwsA(isA<FormatException>()));
  });

  test('throws a FormatException for malformed JSON', () async {
    await SharedPreferencesAsync().setString('state_forge.bad', '{nope');
    final storage = await SharedPreferencesForgeStorage.create();

    expect(() => storage.read('bad'), throwsA(isA<FormatException>()));
  });
}
