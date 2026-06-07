import 'package:flutter/widgets.dart';
import 'package:state_forge/state_forge.dart';
import 'package:state_forge_shared_preferences/state_forge_shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await useSharedPreferencesStorage();

  final store = CounterStore();
  await store.hydrate();
  store.increment();
  await store.persist();
}

final class CounterStore extends Store<int> with PersistableStore<int> {
  CounterStore() : super(0);

  void increment() => emitSync(state + 1);

  @override
  String get storageKey => 'counter';

  @override
  int fromJson(Map<String, dynamic> json) => json['value'] as int? ?? 0;

  @override
  Map<String, dynamic> toJson(int state) => {'value': state};
}
