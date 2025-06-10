
# jintent

`jintent` is a Flutter package that provides an architecture for managing state changes in your application using the concept of intents. This architecture promotes a structured and modular approach to handling specific actions or events, allowing for a clean separation of concerns.

I created this library because I had difficulty organizing complex projects for a long time, I was not able to completely decouple the different events within the application, through this library we clearly manage the different events and states of the application.

## Features

- **Intent Handling:** Introduce the concept of intents, encapsulating actions that can modify the state of your Flutter application.
- **State Management:** `JController` class for managing states and emitting updates.
- **Dependency Injection:** Leverages GetIt for efficient dependency injection.
- **Common Functionalities:** `JCommonsMixin` provides convenient access to common functionalities in Flutter.
- **ProgressDialogManager:** `JProgressDialogManagerController` for showing and hiding progress dialogs.

## Getting Started

To get started with `jintent`, follow these steps:

1. Add the `jintent` package to your `pubspec.yaml` file:

   ```yaml
   dependencies:
     jintent: ^1.0.1
   ```

   Replace `^1.0.1` with the latest version.

2. Import the package in your Dart code:

   ```dart
   import 'package:jintent/jintent.dart';
   ```

3. Implement the `JController` and `JIntent` classes to manage state changes in your application.

4. Leverage the common functionalities provided by `JCommonsMixin` in your Flutter widgets.

5. For showing and hiding progress dialogs, use `JProgressDialogManagerController`.

## Example

Here's a simple example demonstrating how to use:


Full example:

* `AuthenticationState`
* `AuthenticationController`
* `AuthenticationIntent`
* Y un uso típico en UI con `emitSideEffect`, `setState`, y `intent`.

---

### 📦 1. `AuthenticationState`

```dart
import 'package:jintent/jstate.dart';

class AuthenticationState extends JState {
  final String email;
  final String password;
  final bool isLoading;

  AuthenticationState({
    this.email = '',
    this.password = ''
  });

  AuthenticationState copyWith({
    String? email,
    String? password,
    bool? isLoading,
  }) {
    return AuthenticationState(
      email: email ?? this.email,
      password: password ?? this.password,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [email, password, isLoading];
}
```

---

### ⚙️ 2. `AuthenticationController`

```dart
import 'package:jintent/jcontroller.dart';
import 'authentication_state.dart';
import 'authentication_intent.dart';

class AuthenticationController extends JController<AuthenticationState> {
  AuthenticationController() : super(AuthenticationState());

  @override
  void onInit() {
    super.onInit();
    // You could load saved credentials or something else here.
  }
}
```

---

### 🚀 3. `AuthenticationIntent`

```dart
import 'package:jintent/jintent.dart';
import 'authentication_state.dart';
import 'authentication_controller.dart';
import 'package:jintent/jeffect.dart';

class SubmitLoginIntent extends JIntent<AuthenticationState> {
  final String email;
  final String password;

  SubmitLoginIntent({
    required this.email,
    required this.password,
  });

  @override
  Future<void> invoke(JController<AuthenticationState> controller) async {
    final c = controller as AuthenticationController;

    // Set loading state
    c.setState(c.currentState.copyWith(isLoading: true));

    await Future.delayed(const Duration(seconds: 2)); // Simulate API call

    if (email == 'admin@test.com' && password == '123456') {
      // Emit a navigation or success effect
      c.emitSideEffect(SuccessLoginEffect());
    } else {
      c.emitSideEffect(
        ShowErrorDialogEffect(message: 'Invalid credentials'),
      );
    }

    // Remove loading
    c.setState(c.currentState.copyWith(isLoading: false));
  }
}
```

---

### 💥 4. `SideEffects`

```dart
class ShowErrorDialogEffect extends JEffect<void> {
  final String message;
  ShowErrorDialogEffect({required this.message});
}

class SuccessLoginEffect extends JEffect<void> {}
```

---

### 🧩 5. UI Handler Example (Flutter)

```dart
void setupEffectHandler(
  AuthenticationController controller,
  BuildContext context,
) {
  final handler = JSideEffectHandler<AuthenticationState>(controller, context);

  handler.register<ShowErrorDialogEffect>((effect, _) async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Login Failed'),
        content: Text(effect.message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              effect.complete(null);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  });

  handler.register<SuccessLoginEffect>((effect, _) async {
    Navigator.of(context).pushReplacementNamed('/home');
    effect.complete(null);
  });

  controller.sideEffects.listen((e) => handler.handle(e, controller));
}
```

---

### 🧪 6. Ejemplo en UI (`onPressed` o similar)

```dart
final controller = AuthenticationController();

// Somewhere in your button:
onPressed: () {
  controller.intent(
    SubmitLoginIntent(email: 'admin@test.com', password: '123456'),
  );
}
```

---

¿Te gustaría que también te genere esto como una mini app de ejemplo o que lo exporte a archivos organizados para copiar y pegar?


## Documentation

![My Image](assets/jintent.svg)

## Contributing

Not allow by the moment(working on a big feature)

## Author

- [Jesus Donaldo Sanchez Inzunza](https://www.linkedin.com/in/jdsanchez94/)

## License

MIT License

Copyright (c) 2020 Remi Rousselet

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
