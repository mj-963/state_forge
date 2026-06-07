import 'dart:convert';
import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';
import 'package:state_forge_core/state_forge_core.dart';

/// Internal helper for Flutter DevTools integration.
class ForgeDevTools implements StateForgeDiagnostics {
  static final ForgeDevTools instance = ForgeDevTools._();

  ForgeDevTools._();

  final Map<String, Store> _activeStores = {};
  final List<Map<String, dynamic>> _history = [];

  @override
  void registerStore(Store store) {
    if (!kDebugMode) return;
    _activeStores[store.hashCode.toString()] = store;
    _postEvent('store_created', {
      'id': store.hashCode.toString(),
      'type': store.runtimeType.toString(),
      'state': store.state.toString(),
    });
  }

  @override
  void unregisterStore(Store store) {
    if (!kDebugMode) return;
    _activeStores.remove(store.hashCode.toString());
    _postEvent('store_disposed', {
      'id': store.hashCode.toString(),
    });
  }

  @override
  void recordTransition(Store store, Object? oldState, Object? newState) {
    if (!kDebugMode) return;
    final event = {
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'storeId': store.hashCode.toString(),
      'storeType': store.runtimeType.toString(),
      'oldState': oldState.toString(),
      'newState': newState.toString(),
    };
    _history.add(event);
    if (_history.length > 100) _history.removeAt(0);

    _postEvent('transition', event);
  }

  @override
  void recordEffect(Store store, Object effect) {
    if (!kDebugMode) return;
    final event = {
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'storeId': store.hashCode.toString(),
      'storeType': store.runtimeType.toString(),
      'effect': effect.toString(),
    };
    _postEvent('effect', event);
  }

  @override
  void init() {
    if (!kDebugMode) return;

    dev.registerExtension(
      'ext.state_forge.getStores',
      (method, parameters) async {
        final data = _activeStores.values
            .map(
              (store) => {
                'id': store.hashCode.toString(),
                'type': store.runtimeType.toString(),
                'state': store.state.toString(),
              },
            )
            .toList();

        return dev.ServiceExtensionResponse.result(
          jsonEncode({'stores': data}),
        );
      },
    );

    dev.registerExtension(
      'ext.state_forge.getHistory',
      (method, parameters) async {
        return dev.ServiceExtensionResponse.result(
          jsonEncode({'history': _history}),
        );
      },
    );
  }

  void _postEvent(String kind, Map<String, dynamic> data) {
    dev.postEvent('state_forge.$kind', data);
  }
}
