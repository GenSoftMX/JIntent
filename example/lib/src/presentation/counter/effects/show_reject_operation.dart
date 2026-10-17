import 'package:jintent/jintent.dart';

/// Base error effect - shows error snackbar (backward compatible)
class ShowRejectOperation extends JEffect<bool> with JCategorizableEffect {
  final String message;

  ShowRejectOperation({required this.message});

  /// Builds the effect from a failure, without the `Exception: ` prefix that
  /// `Exception.toString()` adds, so the user reads only the reason.
  factory ShowRejectOperation.fromException(Exception error) =>
      ShowRejectOperation(
        message: error.toString().replaceFirst(RegExp(r'^Exception: '), ''),
      );

  @override
  String get category => 'error';
}
