## [3.0.1] - 2026-10-16

### Changed
- Accepts `equatable` 2.x and 3.x (`>=2.0.5 <4.0.0`). State equality is
  unchanged. See [ADR-003](doc/adr/ADR-003-equatable-2-and-3.md).

### Documentation
- The README states the 3.0.0 requirements, summarizes what is new and links the
  interactive guide; the guides no longer describe 3.0.0 as unreleased.
- `pubspec.yaml` declares `repository` and `issue_tracker`.

## [3.0.0] - 2026-10-16

Upgrading from 2.2.0: read the [migration guide](doc/migration.md). Requires
Flutter 3.29.2 or newer.

### Breaking changes
- `package:jintent/jintent.dart` exports only the core, domain helpers,
  `JObserver` and the dispatcher contracts. Devtools, experimental, navigation
  and utilities moved to their own entry points. See
  [entry points](doc/migration.md#entry-points).
- `JController.update` and `setState` skip equal states (`==`), so no listener
  or observer is notified. Mutating state in place is no longer supported; this
  reverses the 2.0.1 behavior. See
  [state equality](doc/migration.md#immutable-state-and-equality).
- Effects: awaitable effects emitted without a listener, and unhandled awaitable
  effects, now complete with a `StateError` instead of being lost or completing
  with `null`. `warnAndCompleteError` replaces the deprecated
  `warnAndAutoComplete`. See
  [effects](doc/migration.md#effects-and-missing-handlers) and
  [listeners](doc/migration.md#listener-presence-is-not-acknowledgement).
- Lifecycle: invoking a running `JIntent` instance again, or dispatching or
  invoking against a disposed controller, fails with `StateError`. Disposal
  fails pending effect results, and the sequential dispatcher rejects that
  controller's queued intents immediately. See
  [disposal](doc/migration.md#controller-disposal-and-cancellation).
- `Either` is sealed and cannot be extended or implemented. See
  [Either](doc/migration.md#either-is-sealed).
- `JIntent.run` and `JIntent.invoke` are `@nonVirtual`, and `JIntent` gains
  `cancel()` and `isCancelled`. Mocks used with dispatchers must stub
  `isCancelled`. See [intent methods](doc/migration.md#intent-methods-are-not-overridable).
- Undo/redo capacities must be positive. See
  [undo/redo promotion](doc/migration.md#undoredo-promotion).

### Added
- `package:jintent/undo_redo.dart`: stable snapshot and command history with an
  observable `history`. History is preserved for equal, cancelled or disposed
  updates. The experimental import remains a compatibility export. See
  [undo/redo](doc/undo-redo.md).
- `package:jintent/widgets.dart`: `JControllerBuilder` and `JControllerSelector`.
  See [widgets](doc/widgets.md).
- `package:jintent/testing.dart`: `JStateRecorder`, `JEffectRecorder` and
  `resetJIntentGlobals`, plus `JEffectsConfig.reset()`. See
  [testing](doc/testing.md).
- `JDroppableIntentDispatcher`, `JRestartableIntentDispatcher` (grouped with
  `keyOf` / `JIntentKey`), cooperative
  cancellation through `JIntent.cancel`, and the optional
  `JPendingIntentCancellation` contract. See [concurrency](doc/concurrency.md).
- `package:jintent/jintent.dart` exports `JEffectsConfig` and
  `UnhandledEffectStrategy`; 2.x required importing them from `src`. See
  [effects](doc/effects.md).
- `JIntent.current`: `JController.update` inside an intent is attributed to it
  and ignored once it is cancelled, without passing `origin`.
- Composable observers: `JObserverDelegate`, `JObserver.addObserver` /
  `removeObserver` / `reset`, and `onIntentStarted`, `onIntentFailed`,
  `onIntentCancelled` and `onIntentDropped` notifications. See
  [observability](doc/observability.md).
- `JController(effectBufferSize: n)` buffers effects emitted before a listener
  attaches (opt-in; the default 0 keeps the previous behavior). See
  [effects](doc/effects.md).
- `Either`: exhaustive `switch`, destructurable `value`, value equality and
  `toString`; `Right` is `const`.
- `JMetrics`: `maxMetrics`, `detachFromObserver`, `intent.failed`,
  `intent.cancelled` and `intent.dropped` counters and a real
  `intent.execution.duration` timer.
- `JDevToolsOverlay` lists failed, cancelled and dropped intents.

### Changed
- Observer and callback failures no longer reach the observed code; they are
  reported through `FlutterError.reportError`.
- `enableLoggingObserver`, `JEffectsLogger.attach` and `JDevToolsOverlay`
  register observers instead of assigning the static callbacks, so they coexist.
- `LoggingDispatcher` forwards cancellation to compatible inner dispatchers, and
  shared sequential queues preserve other controllers' tasks and order.
- A cancelled intent is no longer reported as dispatched.
- Effect handlers must be registered for the concrete effect type; the
  superclass lookup never worked and was removed.

### Deprecated
- `UnhandledEffectStrategy.warnAndAutoComplete`: use `warnAndCompleteError`.

### Fixed
- `JController.update` printed `State updated.` in release builds, and the core
  imported `material.dart`.
- `JMetrics` left an intent timer running and doubled counts when attached twice.
- `Left` threw when its value was `null` and an error logger was set.
- `JColorUtils.blend` returned near-black colors, and `JThrottler.reset` left a
  pending timer that could release the throttle early.
- `JEffectListener` now replaces subscriptions when its controller changes, and
  handler failures complete pending effect results with the original error.
- Effect timeouts report `TimeoutException`.
- `setState` preserves the originating intent for observers, and accessing an
  intent's controller before invocation reports a descriptive error.
- Corrected the `JUseCaseVoid`, `JIntentHelpers` and `CorrelationContext` docs.

### Documentation
- New guides for concurrency, testing, widgets, undo/redo and migration, a
  rewritten observability guide, and ADR-001 and ADR-002.

## [2.2.0] - 2025-11-11
### Documentation
- **Data Layer Guide**: Added comprehensive `docs/DATA_LAYER_GUIDE.md` covering repository patterns, mappers, Either-based error handling, and validation pipelines
- **Mapper Tests**: Added `test/src/domain/mapper_test.dart` demonstrating ArgumentError handling and recovery patterns
- **Example Repository**: Added complete repository example in `example/lib/src/data/` showing:
  - Repository interface and implementations (in-memory, cached, failing mock)
  - Mapper patterns (JMapper and IBiMapper)
  - Either-based error handling
  - ArgumentError handling and recovery
  - Validation at multiple layers
- **Example Tests**: Added comprehensive tests for mappers and repositories demonstrating best practices

## [2.1.0] - 2025-08-09
### Added
- Sequential intent handling to guarantee ordered, one-at-a-time processing.
- Enhanced side effects system: effect IDs, completeError support, unhandledStrategy configurable y timeout.

### Improvements
- Mayor robustez y control operativo sobre la ejecución y diagnóstico de efectos.

## [2.0.1] Bug Fix - (2025-08-05)

### Fixed
- State changes are now always notified in `JController`, even for internal mutations (such as modifying items within a list or map).
- Removed equality check between previous and new state in the `setState` and `update` methods, ensuring that all state updates are propagated to listeners and debugging observers.

### Notes
- This update improves reactivity and observability for state changes that involve mutations within objects or collections.
- No breaking changes to the API.

## 2.0.0 - Side Effects, UI Decoupling, Dependency Cleanup (2024/06/10)
✨ **New Features: Side Effects**
- **Side Effect Stream:** Introduced a `Stream<JEffect>` inside `JController` to handle transient UI actions like navigation, dialogs, and snackbars. These are events that don't modify the application state but require a one-time reaction from the UI.
- **emitSideEffect():** You can now trigger a side effect from the controller using `emitSideEffect(effect)` or `emitAndWaitSideEffect(effect)` to optionally wait for a result.
- **JEffect:** A new abstract class to represent side effects. Can optionally return a result using a `Completer<T>`, useful for awaiting user input (e.g. confirmation dialogs).
- **JSideEffectHandler:** A centralized handler in the UI to react to emitted side effects by type, keeping business logic and UI logic cleanly separated.

🔄 **Architecture Improvements**
- **UI Decoupling:** The UI no longer directly interacts with the controller for triggering logic or responses. Instead, the UI listens to sideEffects and emits `JIntent` instances indirectly, promoting a fully decoupled flow.
- **Intent-Centric Workflow:** The communication between UI and logic is now entirely intent-driven. The controller receives intents and updates state or emits side effects, maintaining separation of concerns.

🧹 **Dependency Cleanup**
- **Removed get_it Dependency:** The package is no longer used internally. All dependency injection is now left to the user's implementation or application layer, giving you full control over your architecture and reducing tight coupling.

## 1.0.0 - Initial Release(2024/04/28)

Key Features
* Intent Handling: Introduces the concept of intents to encapsulate user actions and other events that can modify the state of a Flutter application. This approach promotes modularity and scalability.
* State Management: The JController class provides a way to manage application state and handle updates. It ensures a clean and organized process for handling state changes.
* Dependency Injection: Integration with the GetIt package for efficient dependency injection. This allows for easy registration and retrieval of services throughout the application.
* Common Functionalities: The JCommonsMixin mixin offers convenient access to common Flutter functionalities, such as navigation and progress dialog management.* 
* Progress Dialog Management: The JProgressDialogManagerController class allows for easy management of progress dialogs, facilitating the display and hiding of loading indicators.



## Version 1.0.0+1 - Dependency Injection Enhancement(2024/04/29)
- Dependency Injection: Implemented get_it as the dependency injection system for the project. This change was made because the previous implementation was suboptimal and not functioning as expected. With this enhancement, you can expect improved modularity and easier testing.
- Improved Documentation: Enhanced the documentation for key components, providing clearer explanations and detailed information about dependencies, including JNavigatorService, JState, and others. These updates aim to make the codebase more accessible and easier to understand for developers.


## Version 1.0.0+2 -OnInit and dispose events controller(2024/05/03)

### OnInit Event
Initialization method for the controller.
This method is called once when the controller is created.
It is used to set up the initial state of the controller,
subscribe to events, configure services, or perform any
necessary setup at the beginning of the controller's lifecycle.

This method can be overridden by subclasses to implement
their own initialization logic.

Examples of usage for `onInit()`:
- Subscribing to data providers or services.
- Setting default values for the controller's state.
- Registering listeners for events that affect the controller.

Ensure that any resources used in `onInit()`
are properly released when the controller is deactivated or removed.
For this purpose, you can use a `dispose()` method or another
mechanism to clean up resources when the controller's lifecycle ends.

### Dispose event
Cleans up resources and performs necessary teardown operations.

This method is called when the controller is being disposed of, usually
at the end of its lifecycle. It is crucial to override this method to
ensure proper cleanup of resources, like unsubscribing from providers,
removing listeners, or releasing references to large objects.

When overriding this method, always call `super.dispose()` to ensure
that the base class's disposal logic is also executed.

Common cleanup tasks include:
- Unsubscribing from event listeners or streams.
- Releasing references to large objects or services.
- Closing resources like file handles, database connections, or network sockets.
  
**Important:** Failing to clean up resources can lead to memory leaks
and other unpredictable behavior, so always ensure proper disposal.

## Version 1.0.0+3 call OnInit in contracutor(to get expected behavior with OnInit Event) (2024/05/03)
- call OnInit JController contructor as default.


## Version 1.0.1 - Side Effects System & Decoupling UI from Controller (2024/06/10)
✨ New Features: Side Effects
Side Effect Stream: Introduced a Stream<JEffect> inside JController to handle transient UI actions like navigation, dialogs, and snackbars. These are events that don't modify the application state but require a one-time reaction from the UI.

emitSideEffect(): You can now trigger a side effect from the controller using emitSideEffect(effect) or emitAndWaitSideEffect(effect) to optionally wait for a result.

JEffect: A new abstract class to represent side effects. Can optionally return a result using a Completer<T>, useful for awaiting user input (e.g. confirmation dialogs).

JSideEffectHandler: A centralized handler in the UI to react to emitted side effects by type, keeping business logic and UI logic cleanly separated.

🔄 Architecture Improvements
UI Decoupling: The UI no longer directly interacts with the controller for triggering logic or responses. Instead, the UI listens to sideEffects and emits JIntent instances indirectly, promoting a fully decoupled flow.

Intent-Centric Workflow: The communication between UI and logic is now entirely intent-driven. The controller receives intents and updates state or emits side effects, maintaining separation of concerns.

🧹 Dependency Cleanup
Removed get_it Dependency: The package is no longer used internally. All dependency injection is now left to the user's implementation or application layer, giving you full control over your architecture and reducing tight coupling.
