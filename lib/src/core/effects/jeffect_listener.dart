import 'dart:async';
import 'package:flutter/material.dart';
import 'package:jintent/jintent.dart';

/// Listens to side effects emitted by the [JController] and handles them
/// using the provided [JSideEffectHandler].
/// This widget is useful for reacting to one-time UI events such as navigation,
/// dialogs, or snackbars.
class JEffectListener<T extends JState> extends StatefulWidget {
  final JController<T> controller;
  final JSideEffectHandler<T> handler;
  final Widget child;

  const JEffectListener({
    Key? key,
    required this.controller,
    required this.handler,
    required this.child,
  }) : super(key: key);

  @override
  State<JEffectListener<T>> createState() => _JEffectListenerState<T>();
} 

class _JEffectListenerState<T extends JState>
    extends State<JEffectListener<T>> {
  /// Subscription to the side effects stream of the controller.
  /// This subscription listens for side effects and handles them using the
  /// provided [JSideEffectHandler].
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _sub = widget.controller.sideEffects.listen((effect) {
      if (mounted) {
        widget.handler.handle(effect, widget.controller, context);
      } else {
        // If the widget is not mounted, we cannot handle the effect
        // This prevents memory leaks or exceptions when the widget is disposed
        effect.complete(null);
      }
    });
  }

  /// Cancels the subscription to the side effects stream when the widget is disposed.
  /// This ensures that we do not leak memory by keeping the subscription alive
  /// after the widget is no longer in the widget tree.
  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  /// Builds the widget tree with the provided child.
  /// This widget will listen for side effects and handle them using the
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}