# state_forge_shared_preferences

SharedPreferencesAsync persistence adapter for StateForge.

Use this for lightweight JSON state such as onboarding, settings, theme mode,
and local feature flags. Keep `ForgeStorageAdapter` for advanced storage such as
Hive, Drift, encrypted storage, files, or cloud sync.

## Install

```yaml
dependencies:
  state_forge: ^0.1.2
  state_forge_shared_preferences: ^0.1.2
```

## Configure

```dart
import 'package:state_forge/state_forge.dart';
import 'package:state_forge_shared_preferences/state_forge_shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  StateForge.storage = await SharedPreferencesForgeStorage.create();
  // or:
  // await useSharedPreferencesStorage();

  runApp(const App());
}
```

Stores still opt in explicitly:

```dart
class SettingsStore extends Store<SettingsState>
    with PersistableStore<SettingsState> {
  SettingsStore() : super(SettingsState.defaults()) {
    hydrateOnCreate(debounce: const Duration(milliseconds: 250));
  }

  @override
  String get storageKey => 'settings';

  @override
  SettingsState fromJson(Map<String, dynamic> json) =>
      SettingsState.fromJson(json);

  @override
  Map<String, dynamic> toJson(SettingsState state) => state.toJson();
}
```
