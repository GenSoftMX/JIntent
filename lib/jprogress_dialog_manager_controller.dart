import 'package:flutter/foundation.dart';

/// An abstract class for managing the display and hiding of a progress dialog.
///
/// The `JProgressDialogManagerController` provides a contract for showing and
/// hiding a progress dialog. This class is typically used to manage the visibility
/// of progress dialogs in a consistent manner across the application, allowing
/// developers to indicate that a background task or a process is ongoing.
///
/// This is an abstract class, meaning that it must be extended with concrete
/// implementations to define the actual behavior of showing and hiding the dialog.
///
/// - [T]: The type of the result returned by the progress dialog when it is closed.
@immutable
abstract class JProgressDialogManagerController<T> {
  /// Shows the progress dialog with an optional message.
  ///
  /// This method is used to display the progress dialog, optionally providing
  /// a message to explain what process is ongoing.
  ///
  /// - [msg]: An optional message to display in the progress dialog.
  ///
  /// Returns a `Future` of type [T], which completes when the dialog is hidden.
  Future<T> show({String? msg});

  /// Hides the progress dialog.
  ///
  /// This method is used to hide the progress dialog when the ongoing process
  /// is complete or when it's no longer needed.
  ///
  /// Returns a `Future` of type [T], indicating that the dialog has been closed.
  Future<T> hide();
}
