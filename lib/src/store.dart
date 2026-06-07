import 'package:state_forge_core/state_forge_core.dart' as core;

import 'devtools.dart';

export 'package:state_forge_core/state_forge_core.dart'
    show ForgeDisposable, StoreListener;

/// The Flutter-facing StateForge store base class.
///
/// It preserves the public `Store<S>` API while delegating the implementation to
/// the pure Dart core package.
abstract class Store<S> extends core.Store<S> {
  /// Initializes the store with its initial state.
  Store(S initial) : super(_installFlutterDiagnostics(initial));
}

S _installFlutterDiagnostics<S>(S initial) {
  core.StateForge.diagnostics ??= ForgeDevTools.instance;
  return initial;
}
