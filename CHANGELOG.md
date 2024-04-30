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