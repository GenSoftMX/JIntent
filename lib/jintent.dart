/// Intents, state and effects for Flutter.
///
/// This entry point holds the core contracts: [JState], [JIntent],
/// [JController], effects, dispatchers, [JObserver] and the domain helpers.
/// Optional pieces live in their own entry points:
/// - `package:jintent/devtools.dart`: logging, metrics, correlation, overlay.
/// - `package:jintent/undo_redo.dart`: undo/redo and observable history.
/// - `package:jintent/navigation.dart`: a thin `Navigator` abstraction.
/// - `package:jintent/utils.dart`: throttler and small helpers.
/// - `package:jintent/testing.dart`: test helpers.
/// - `package:jintent/widgets.dart`: controller builder and selector.
library;

export './src/core/core.dart';
export './src/domain/domain.dart';
export './src/devtools/jobserver.dart';
export './src/extensions/logging_dispatcher.dart';
