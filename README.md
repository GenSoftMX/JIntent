
# jintent

`jintent` is a Flutter package that provides an architecture for managing state changes in your application using the concept of intents. This architecture promotes a structured and modular approach to handling specific actions or events, allowing for a clean separation of concerns.

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
     jintent: ^1.0.0
   ```

   Replace `^1.0.0` with the latest version.

2. Import the package in your Dart code:

   ```dart
   import 'package:jintent/jintent.dart';
   ```

3. Implement the `JController` and `JIntent` classes to manage state changes in your application.

4. Leverage the common functionalities provided by `JCommonsMixin` in your Flutter widgets.

5. For showing and hiding progress dialogs, use `JProgressDialogManagerController`.

## Example

Here's a simple example demonstrating how to use `jintent`:


* Definition and authentication with federal google provider intent.
```dart

class AuthWihFederalGooogleProviderIntent extends JIntent<AuthenticationState> {
  final AuthType authType;

  AuthWihFederalGooogleProviderIntent({required this.authType});
  @override
  Future<AuthenticationState> invoke(AuthenticationState state) async {
    pd.show();
    try {
      await signInWithGoogle();

      goTo.home();
      
      await Future.delayed($styles.times.fast);
      
      pd.hide();
      
      return state;
    } catch (e) {
      pd.hide();
    }

    return state;
  }

  Future<UserCredential> signInWithGoogle() async {
    // Trigger the authentication flow
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

    // Obtain the auth details from the request
    final GoogleSignInAuthentication? googleAuth =
        await googleUser?.authentication;

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );

    // Once signed in, return the UserCredential
    return await FirebaseAuth.instance.signInWithCredential(credential);
  }
}

```

## Documentation

working on

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
