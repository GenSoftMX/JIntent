import 'package:flutter/widgets.dart';
import 'package:jintent/jintent.dart';

/// Builds from the initial state and every subsequent distinct controller state.
///
/// Owns only its subscription, never the controller. Replacing [controller]
/// detaches the old listener and immediately uses the new controller's state.
class JControllerBuilder<S extends JState> extends StatelessWidget {
  const JControllerBuilder({
    super.key,
    required this.controller,
    required this.builder,
  });

  final JController<S> controller;
  final Widget Function(BuildContext context, S state) builder;

  @override
  Widget build(BuildContext context) => JControllerSelector<S, S>(
    controller: controller,
    selector: (state) => state,
    builder: builder,
  );
}

/// Rebuilds on controller notifications only when the selected value changes.
///
/// Values are compared with `==`; select immutable values with meaningful
/// equality. Parent rebuilds still rebuild this widget normally. Changing the
/// controller or selector immediately recomputes the selection. The caller
/// owns the controller and must keep it alive while this widget uses it.
class JControllerSelector<S extends JState, V> extends StatefulWidget {
  const JControllerSelector({
    super.key,
    required this.controller,
    required this.selector,
    required this.builder,
  });

  final JController<S> controller;
  final V Function(S state) selector;
  final Widget Function(BuildContext context, V value) builder;

  @override
  State<JControllerSelector<S, V>> createState() =>
      _JControllerSelectorState<S, V>();
}

class _JControllerSelectorState<S extends JState, V>
    extends State<JControllerSelector<S, V>> {
  late V _value;
  late void Function() _removeListener;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  void _subscribe() {
    _value = widget.selector(widget.controller.currentState);
    _removeListener = widget.controller.addListener((state) {
      final next = widget.selector(state);
      if (next != _value) setState(() => _value = next);
    }, fireImmediately: false);
  }

  @override
  void didUpdateWidget(covariant JControllerSelector<S, V> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      _removeListener();
      _subscribe();
    } else {
      _value = widget.selector(widget.controller.currentState);
    }
  }

  @override
  void dispose() {
    _removeListener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _value);
}
