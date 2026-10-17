import 'package:jintent/jintent.dart';

/// Warning feedback effect - shows orange snackbar
class ShowWarningEffect extends JFireAndForgetEffect with JCategorizableEffect {
  final String message;

  ShowWarningEffect({required this.message});

  @override
  String get category => 'warning';
}
