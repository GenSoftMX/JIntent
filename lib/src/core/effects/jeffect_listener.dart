import 'dart:async';
import 'package:flutter/material.dart';
import 'package:jintent/jintent.dart';

/// Listens to side effects emitted by the [JController] and handles them
/// using the provided [JSideEffectHandler].
/// This widget is useful for reacting to one-time UI events such as navigation,
/// dialogs, or snackbars.
/// Handler failures complete pending effect results with the original error
/// and are reported through [FlutterError.reportError]. Changing controllers
/// replaces the subscription; already running handlers are not cancelled.
/// Removing this widget does not complete or cancel in-flight effect results.
/// Their handler must complete them; callers can set a timeout, and controller
/// disposal fails any results that remain pending. Queued broadcast events may
/// be dropped when the subscription is cancelled before delivery.
class JEffectListener<T extends JState> extends StatefulWidget {
  final JController<T> controller;
  final JSideEffectHandler<T> handler;
  final Widget child;

  const JEffectListener({
    super.key,
    required this.controller,
    required this.handler,
    required this.child,
  });

  @override
  State<JEffectListener<T>> createState() => _JEffectListenerState<T>();
}

class _JEffectListenerState<T extends JState>
    extends State<JEffectListener<T>> {
  /// Subscription to the side effects stream of the controller.
  /// This subscription listens for side effects and handles them using the
  /// provided [JSideEffectHandler].
  StreamSubscription<JEffect>? _sub;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  @override
  void didUpdateWidget(covariant JEffectListener<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      _sub?.cancel();
      _subscribe();
    }
  }

  void _subscribe() {
    final controller = widget.controller;
    _sub = controller.sideEffects.listen((effect) {
      if (!mounted || !identical(controller, widget.controller)) return;
      // Each event keeps its original controller even if the widget changes
      // while the handler is awaiting UI work. Effects remain concurrent.
      unawaited(_handleEffect(effect, controller));
    });
  }

  Future<void> _handleEffect(JEffect effect, JController<T> controller) async {
    try {
      await widget.handler.handle(effect, controller, context);
    } catch (error, stackTrace) {
      // A fire-and-forget caller may never await result. Mark that future as
      // observed without changing what callers awaiting it will receive.
      effect.result.ignore();
      if (!effect.isCompleted) effect.completeError(error, stackTrace);
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'jintent',
          context: ErrorDescription('while handling ${effect.runtimeType}'),
        ),
      );
    }
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
