import 'package:jintent/jintent.dart';

/// Info feedback effect - shows blue snackbar
class ShowInfoEffect extends JFireAndForgetEffect with JCategorizableEffect {
  final String message;

  ShowInfoEffect({required this.message});

  @override
  String get category => 'info';
}
