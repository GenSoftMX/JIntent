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