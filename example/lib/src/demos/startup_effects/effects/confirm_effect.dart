import 'package:jintent/jintent.dart';

/// Asks the user a yes/no question and carries the answer back.
class ConfirmEffect extends JDialogEffect<bool> {
  ConfirmEffect(this.question);

  final String question;
}
