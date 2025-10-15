## [Unreleased]
### Documentation
- **Validation Guide**: Added comprehensive `docs/VALIDATION_GUIDE.md` covering UseCaseInputValidator patterns, fail-fast validation chains, and best practices
- **Example Validators**: Added reusable validator examples in `example/lib/src/domain/validators/`:
  - Common validators (string, numeric, collection validation)
  - Email validators (format, length, domain validation)
  - Password validators (security requirements, complexity checks)
  - Counter validators (range checks, increment/decrement validation)
- **Example Use Cases**: Added validated use case examples demonstrating fail-fast validation:
  - `ValidatedIncrementUseCase` - Counter increment with validation
  - `ValidatedDecrementUseCase` - Counter decrement with validation
  - `ValidateUserRegistrationUseCase` - Complex multi-field validation
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