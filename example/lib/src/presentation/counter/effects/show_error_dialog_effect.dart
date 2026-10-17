import 'package:jintent/jintent.dart';

/// Critical error dialog effect - shows dialog for important errors
class ShowErrorDialogEffect extends JDialogEffect<bool>
    with JCategorizableEffect {
  final String title;
  final String message;
  final String? actionLabel;

  ShowErrorDialogEffect({
    required this.title,
    required this.message,
    this.actionLabel,
  });

  @override
  String get category => 'error_dialog';
}
