import 'package:counter/src/demos/observability_lab/models/lab_log_line.dart';
import 'package:jintent/jintent.dart';

/// An application-level observer that turns lifecycle notifications into log
/// lines. It lives next to the metrics and logging observers: registering one
/// observer never replaces another.
class LabLogObserver extends JObserverDelegate {
  LabLogObserver({this.maxLines = 12, this.onChanged});

  final int maxLines;
  final void Function()? onChanged;
  final lines = <LabLogLine>[];

  void _add(String text) {
    lines.insert(0, LabLogLine(text));
    if (lines.length > maxLines) lines.removeLast();
    onChanged?.call();
  }

  String _name(JIntent intent) => intent.runtimeType.toString();

  @override
  void onIntentStarted(JIntent intent) => _add('started ${_name(intent)}');

  @override
  void onIntentDispatched(JIntent intent) => _add('completed ${_name(intent)}');

  @override
  void onIntentFailed(JIntent intent, Object error, StackTrace stackTrace) =>
      _add('failed ${_name(intent)}: $error');

  @override
  void onIntentCancelled(JIntent intent) => _add('cancelled ${_name(intent)}');

  @override
  void onIntentDropped(JIntent intent) => _add('dropped ${_name(intent)}');
}
