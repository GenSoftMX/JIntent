import 'package:jintent/jintent.dart';

/// Success feedback effect - shows green snackbar
class ShowSuccessEffect extends JFireAndForgetEffect with JCategorizableEffect {
  final String message;

  ShowSuccessEffect({required this.message});

  @override
  String get category => 'success';
}
