import 'package:state_forge_core/state_forge_core.dart' as core;

import 'devtools.dart';
import 'forge_observer.dart';

export 'package:state_forge_core/state_forge_core.dart'
    show ForgeStorageAdapter, StateForgeDiagnostics;

/// Global configuration and hooks for the StateForge Flutter package.
class StateForge {
  /// Whether to print debug information (transitions, effects) to the console.
  static bool get debugMode => core.StateForge.debugMode;
  static set debugMode(bool value) => core.StateForge.debugMode = value;

  /// Global error handler hook.
  static void Function(Object error, StackTrace stackTrace)? get onError =>
      core.StateForge.onError;
  static set onError(
      void Function(Object error, StackTrace stackTrace)? value) {
    core.StateForge.onError = value;
  }

  /// Global observer for monitoring store lifecycles and transitions.
  static ForgeObserver? get observer =>
      core.StateForge.observer as ForgeObserver?;
  static set observer(core.ForgeObserver? value) {
    core.StateForge.observer = value;
  }

  /// Optional global storage adapter used by [PersistableStore].
  static core.ForgeStorageAdapter? get storage => core.StateForge.storage;
  static set storage(core.ForgeStorageAdapter? value) {
    core.StateForge.storage = value;
  }

  /// Optional diagnostics adapter used by platform packages.
  static core.StateForgeDiagnostics? get diagnostics =>
      core.StateForge.diagnostics;
  static set diagnostics(core.StateForgeDiagnostics? value) {
    core.StateForge.diagnostics = value;
  }

  /// Initializes StateForge Flutter integrations.
  static void init() {
    core.StateForge.diagnostics ??= ForgeDevTools.instance;
    core.StateForge.init();
  }
}

// Keep the Flutter observer facade reachable from this library for typed users.
typedef FlutterForgeObserver = ForgeObserver;
