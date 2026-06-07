import 'package:flutter/widgets.dart';
import 'store.dart';
import 'forge_builder.dart';
import 'forge_listener.dart';

/// A widget that combines [ForgeBuilder] and [ForgeListener].
class ForgeConsumer<T extends Store<S>, S, E> extends StatelessWidget {
  const ForgeConsumer({
    super.key,
    required this.onEffect,
    required this.builder,
  });

  /// Callback triggered when an effect of type [E] is emitted.
  final void Function(BuildContext context, E effect) onEffect;

  /// A function that builds a widget based on the current state.
  final Widget Function(BuildContext context, S state, T store) builder;

  @override
  Widget build(BuildContext context) {
    return ForgeListener<T, E>(
      onEffect: onEffect,
      child: ForgeBuilder<T, S>(
        builder: builder,
      ),
    );
  }
}
