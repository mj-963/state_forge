import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:state_forge/state_forge.dart';

/// A lightweight [ForgeStorageAdapter] backed by SharedPreferencesAsync.
///
/// This adapter is designed for small JSON state such as onboarding flags,
/// settings, theme preferences, and other app-local state. Use a database or
/// encrypted adapter for large, relational, or sensitive data.
final class SharedPreferencesForgeStorage implements ForgeStorageAdapter {
  /// Creates an adapter with an existing [SharedPreferencesAsync] instance.
  const SharedPreferencesForgeStorage(
    this._preferences, {
    this.prefix = 'state_forge.',
  });

  final SharedPreferencesAsync _preferences;

  /// Prefix applied to every persisted StateForge key.
  final String prefix;

  /// Creates an adapter using the non-legacy [SharedPreferencesAsync] API.
  static Future<SharedPreferencesForgeStorage> create({
    String prefix = 'state_forge.',
  }) async {
    final preferences = SharedPreferencesAsync();
    return SharedPreferencesForgeStorage(preferences, prefix: prefix);
  }

  @override
  Future<void> delete(String key) async {
    await _preferences.remove(_storageKey(key));
  }

  @override
  Future<Map<String, dynamic>?> read(String key) async {
    final raw = await _preferences.getString(_storageKey(key));
    if (raw == null) return null;

    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }

    throw FormatException(
      'Expected persisted StateForge value for "$key" to be a JSON object.',
    );
  }

  @override
  Future<void> write(String key, Map<String, dynamic> data) async {
    await _preferences.setString(_storageKey(key), jsonEncode(data));
  }

  String _storageKey(String key) => '$prefix$key';
}

/// Creates a [SharedPreferencesForgeStorage], assigns it to
/// [StateForge.storage], and returns it for inspection/testing.
Future<SharedPreferencesForgeStorage> useSharedPreferencesStorage({
  String prefix = 'state_forge.',
}) async {
  final storage = await SharedPreferencesForgeStorage.create(prefix: prefix);
  StateForge.storage = storage;
  return storage;
}
