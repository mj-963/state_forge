import '../store.dart';

/// A mixin that adds history management (Undo/Redo) to a [Store].
///
/// It automatically tracks every state change and provides [undo] and [redo]
/// methods. The history depth can be configured via [maxHistory].
mixin UndoableStore<S> on Store<S> {
  final List<S> _history = [];
  final List<S> _redoStack = [];
  int _maxHistory = 100;

  /// Sets the maximum number of history states to keep. Defaults to 100.
  set maxHistory(int value) => _maxHistory = value;

  /// Whether there is a previous state to revert to.
  bool get canUndo => _history.isNotEmpty;

  /// Whether there is a future state to re-apply.
  bool get canRedo => _redoStack.isNotEmpty;

  @override
  void emit(S newState) {
    _recordHistory(newState);
    super.emit(newState);
  }

  @override
  void emitSync(S newState) {
    _recordHistory(newState);
    super.emitSync(newState);
  }

  /// Reverts the store to its previous state.
  void undo() {
    if (!canUndo) return;
    _redoStack.add(state);
    final previousState = _history.removeLast();
    super.emit(previousState);
  }

  /// Re-applies a previously undone state.
  void redo() {
    if (!canRedo) return;
    _history.add(state);
    final nextState = _redoStack.removeLast();
    super.emit(nextState);
  }

  void _recordHistory(S newState) {
    if (state == newState) return;
    _history.add(state);
    if (_history.length > _maxHistory) {
      _history.removeAt(0);
    }
    _redoStack.clear();
  }
}
