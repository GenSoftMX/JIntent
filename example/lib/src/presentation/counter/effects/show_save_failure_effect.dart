import 'package:jintent/jintent.dart';

/// Recoverable persistence failure, presented only by the effect handler.
class ShowSaveFailureEffect extends JFireAndForgetEffect
    with JCategorizableEffect {
  String get message => 'Could not save the counter. Please try again.';

  @override
  String get category => 'error';
}
