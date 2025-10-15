# Input Validation Examples

This document provides practical examples of input validation patterns using JIntent's `UseCaseInputValidator`.

## Table of Contents

1. [Basic Validation](#basic-validation)
2. [Reusable Validators](#reusable-validators)
3. [Complex Validation](#complex-validation)
4. [Cross-Field Validation](#cross-field-validation)
5. [Async Validation](#async-validation)
6. [Error Aggregation](#error-aggregation)

---

## Basic Validation

### Example 1: Simple Email Validation

```dart
import 'package:jintent/jintent.dart';

class SendEmailUseCase extends JUseCase<SendEmailInput, EmailResult> {
  SendEmailUseCase() {
    addValidator(_validateEmail);
  }

  Either<Exception, SendEmailInput> _validateEmail(SendEmailInput input) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    
    if (input.email.trim().isEmpty) {
      return Left(Exception('Email address is required'));
    }
    
    if (!emailRegex.hasMatch(input.email)) {
      return Left(Exception('Invalid email format'));
    }
    
    return Right(input);
  }

  @override
  Future<Either<Exception, EmailResult>> run(SendEmailInput input) async {
    // Email is already validated, proceed with business logic
    return await _emailService.send(input.email, input.subject, input.body);
  }
}

class SendEmailInput {
  final String email;
  final String subject;
  final String body;

  SendEmailInput({
    required this.email,
    required this.subject,
    required this.body,
  });
}
```

### Example 2: Age Validation

```dart
class RegisterUserUseCase extends JUseCase<RegisterInput, User> {
  RegisterUserUseCase() {
    addValidator(_validateAge);
  }

  Either<Exception, RegisterInput> _validateAge(RegisterInput input) {
    if (input.age < 13) {
      return Left(Exception('You must be at least 13 years old to register'));
    }
    
    if (input.age > 120) {
      return Left(Exception('Please enter a valid age'));
    }
    
    return Right(input);
  }

  @override
  Future<Either<Exception, User>> run(RegisterInput input) async {
    // Age validated, proceed with registration
    return await _userRepository.register(input);
  }
}
```

### Example 3: String Length Validation

```dart
class CreatePostUseCase extends JUseCase<CreatePostInput, Post> {
  CreatePostUseCase() {
    addValidator(_validateTitle);
    addValidator(_validateContent);
  }

  Either<Exception, CreatePostInput> _validateTitle(CreatePostInput input) {
    final title = input.title.trim();
    
    if (title.isEmpty) {
      return Left(Exception('Post title is required'));
    }
    
    if (title.length < 5) {
      return Left(Exception('Title must be at least 5 characters'));
    }
    
    if (title.length > 100) {
      return Left(Exception('Title must be less than 100 characters'));
    }
    
    return Right(input);
  }

  Either<Exception, CreatePostInput> _validateContent(CreatePostInput input) {
    final content = input.content.trim();
    
    if (content.isEmpty) {
      return Left(Exception('Post content is required'));
    }
    
    if (content.length > 10000) {
      return Left(Exception('Content must be less than 10,000 characters'));
    }
    
    return Right(input);
  }

  @override
  Future<Either<Exception, Post>> run(CreatePostInput input) async {
    return await _postRepository.create(input);
  }
}
```

---

## Reusable Validators

### Generic Validator Library

```dart
// lib/validators/common_validators.dart

/// Validates that a string field is not empty
Either<Exception, T> notEmptyValidator<T>(
  T input,
  String Function(T) extractor,
  String fieldName,
) {
  final value = extractor(input);
  if (value.trim().isEmpty) {
    return Left(Exception('$fieldName is required'));
  }
  return Right(input);
}

/// Validates string length within range
Either<Exception, T> lengthValidator<T>(
  T input,
  String Function(T) extractor,
  int minLength,
  int maxLength,
  String fieldName,
) {
  final value = extractor(input);
  final length = value.length;
  
  if (length < minLength || length > maxLength) {
    return Left(Exception(
      '$fieldName must be between $minLength and $maxLength characters',
    ));
  }
  
  return Right(input);
}

/// Validates numeric range
Either<Exception, T> rangeValidator<T>(
  T input,
  num Function(T) extractor,
  num min,
  num max,
  String fieldName,
) {
  final value = extractor(input);
  
  if (value < min || value > max) {
    return Left(Exception(
      '$fieldName must be between $min and $max',
    ));
  }
  
  return Right(input);
}

/// Validates email format
Either<Exception, T> emailValidator<T>(
  T input,
  String Function(T) extractor,
) {
  final email = extractor(input);
  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  
  if (!emailRegex.hasMatch(email)) {
    return Left(Exception('Invalid email format'));
  }
  
  return Right(input);
}

/// Validates phone number format (simple)
Either<Exception, T> phoneValidator<T>(
  T input,
  String Function(T) extractor,
) {
  final phone = extractor(input).replaceAll(RegExp(r'[\s\-\(\)]'), '');
  final phoneRegex = RegExp(r'^\+?[1-9]\d{9,14}$');
  
  if (!phoneRegex.hasMatch(phone)) {
    return Left(Exception('Invalid phone number format'));
  }
  
  return Right(input);
}

/// Validates URL format
Either<Exception, T> urlValidator<T>(
  T input,
  String Function(T) extractor,
) {
  final url = extractor(input);
  
  try {
    final uri = Uri.parse(url);
    if (!uri.hasScheme || !uri.hasAuthority) {
      return Left(Exception('Invalid URL format'));
    }
    return Right(input);
  } catch (e) {
    return Left(Exception('Invalid URL format'));
  }
}

/// Validates that a value matches a pattern
Either<Exception, T> patternValidator<T>(
  T input,
  String Function(T) extractor,
  RegExp pattern,
  String fieldName,
  String errorMessage,
) {
  final value = extractor(input);
  
  if (!pattern.hasMatch(value)) {
    return Left(Exception('$fieldName $errorMessage'));
  }
  
  return Right(input);
}
```

### Using Reusable Validators

```dart
class UpdateProfileUseCase extends JUseCase<UpdateProfileInput, Profile> {
  UpdateProfileUseCase() {
    // Use reusable validators
    addValidator((input) => 
      notEmptyValidator(input, (i) => i.name, 'Name'));
    
    addValidator((input) => 
      lengthValidator(input, (i) => i.name, 2, 50, 'Name'));
    
    addValidator((input) => 
      emailValidator(input, (i) => i.email));
    
    addValidator((input) => 
      rangeValidator(input, (i) => i.age, 13, 120, 'Age'));
  }

  @override
  Future<Either<Exception, Profile>> run(UpdateProfileInput input) async {
    return await _profileRepository.update(input);
  }
}
```

---

## Complex Validation

### Password Strength Validation

```dart
class ChangePasswordUseCase extends JUseCase<ChangePasswordInput, void> {
  ChangePasswordUseCase() {
    addValidator(_validatePassword);
  }

  Either<Exception, ChangePasswordInput> _validatePassword(
    ChangePasswordInput input,
  ) {
    final password = input.newPassword;
    
    // Check length
    if (password.length < 8) {
      return Left(Exception('Password must be at least 8 characters'));
    }
    
    if (password.length > 128) {
      return Left(Exception('Password must be less than 128 characters'));
    }
    
    // Check complexity
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return Left(Exception('Password must contain at least one uppercase letter'));
    }
    
    if (!password.contains(RegExp(r'[a-z]'))) {
      return Left(Exception('Password must contain at least one lowercase letter'));
    }
    
    if (!password.contains(RegExp(r'[0-9]'))) {
      return Left(Exception('Password must contain at least one number'));
    }
    
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return Left(Exception('Password must contain at least one special character'));
    }
    
    // Check for common passwords
    const commonPasswords = ['Password123!', 'Admin123!', 'User123!'];
    if (commonPasswords.contains(password)) {
      return Left(Exception('Please choose a less common password'));
    }
    
    return Right(input);
  }

  @override
  Future<Either<Exception, void>> run(ChangePasswordInput input) async {
    return await _authRepository.changePassword(
      input.currentPassword,
      input.newPassword,
    );
  }
}
```

### Credit Card Validation

```dart
class AddPaymentMethodUseCase extends JUseCase<PaymentMethodInput, PaymentMethod> {
  AddPaymentMethodUseCase() {
    addValidator(_validateCardNumber);
    addValidator(_validateExpiryDate);
    addValidator(_validateCVV);
  }

  Either<Exception, PaymentMethodInput> _validateCardNumber(
    PaymentMethodInput input,
  ) {
    final cardNumber = input.cardNumber.replaceAll(' ', '');
    
    // Check length (13-19 digits for most cards)
    if (cardNumber.length < 13 || cardNumber.length > 19) {
      return Left(Exception('Invalid card number length'));
    }
    
    // Check if all digits
    if (!RegExp(r'^\d+$').hasMatch(cardNumber)) {
      return Left(Exception('Card number must contain only digits'));
    }
    
    // Luhn algorithm check
    if (!_isValidLuhn(cardNumber)) {
      return Left(Exception('Invalid card number'));
    }
    
    return Right(input);
  }

  Either<Exception, PaymentMethodInput> _validateExpiryDate(
    PaymentMethodInput input,
  ) {
    final now = DateTime.now();
    
    if (input.expiryYear < now.year) {
      return Left(Exception('Card has expired'));
    }
    
    if (input.expiryYear == now.year && input.expiryMonth < now.month) {
      return Left(Exception('Card has expired'));
    }
    
    if (input.expiryMonth < 1 || input.expiryMonth > 12) {
      return Left(Exception('Invalid expiry month'));
    }
    
    return Right(input);
  }

  Either<Exception, PaymentMethodInput> _validateCVV(
    PaymentMethodInput input,
  ) {
    final cvv = input.cvv;
    
    if (cvv.length < 3 || cvv.length > 4) {
      return Left(Exception('CVV must be 3 or 4 digits'));
    }
    
    if (!RegExp(r'^\d+$').hasMatch(cvv)) {
      return Left(Exception('CVV must contain only digits'));
    }
    
    return Right(input);
  }

  bool _isValidLuhn(String cardNumber) {
    int sum = 0;
    bool alternate = false;
    
    for (int i = cardNumber.length - 1; i >= 0; i--) {
      int n = int.parse(cardNumber[i]);
      
      if (alternate) {
        n *= 2;
        if (n > 9) {
          n -= 9;
        }
      }
      
      sum += n;
      alternate = !alternate;
    }
    
    return (sum % 10) == 0;
  }

  @override
  Future<Either<Exception, PaymentMethod>> run(PaymentMethodInput input) async {
    return await _paymentRepository.addPaymentMethod(input);
  }
}
```

---

## Cross-Field Validation

### Date Range Validation

```dart
class CreateEventUseCase extends JUseCase<CreateEventInput, Event> {
  CreateEventUseCase() {
    addValidator(_validateDates);
  }

  Either<Exception, CreateEventInput> _validateDates(CreateEventInput input) {
    // End date must be after start date
    if (input.endDate.isBefore(input.startDate)) {
      return Left(Exception('End date must be after start date'));
    }
    
    // Event must be in the future
    if (input.startDate.isBefore(DateTime.now())) {
      return Left(Exception('Event cannot be scheduled in the past'));
    }
    
    // Event duration check
    final duration = input.endDate.difference(input.startDate);
    if (duration.inHours > 48) {
      return Left(Exception('Event cannot exceed 48 hours'));
    }
    
    if (duration.inMinutes < 30) {
      return Left(Exception('Event must be at least 30 minutes long'));
    }
    
    return Right(input);
  }

  @override
  Future<Either<Exception, Event>> run(CreateEventInput input) async {
    return await _eventRepository.create(input);
  }
}
```

### Password Confirmation

```dart
class RegisterUseCase extends JUseCase<RegisterInput, User> {
  RegisterUseCase() {
    addValidator(_validatePasswordMatch);
  }

  Either<Exception, RegisterInput> _validatePasswordMatch(
    RegisterInput input,
  ) {
    if (input.password != input.confirmPassword) {
      return Left(Exception('Passwords do not match'));
    }
    
    return Right(input);
  }

  @override
  Future<Either<Exception, User>> run(RegisterInput input) async {
    return await _userRepository.register(input);
  }
}
```

---

## Async Validation

### Username Availability Check

```dart
class CheckUsernameUseCase extends JUseCase<String, bool> {
  final UserRepository _repository;

  CheckUsernameUseCase(this._repository) {
    addValidator(_validateFormat);
  }

  // Synchronous format validation
  Either<Exception, String> _validateFormat(String username) {
    if (username.length < 3) {
      return Left(Exception('Username must be at least 3 characters'));
    }
    
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
      return Left(Exception('Username can only contain letters, numbers, and underscores'));
    }
    
    return Right(username);
  }

  @override
  Future<Either<Exception, bool>> run(String username) async {
    // Async availability check
    try {
      final isAvailable = await _repository.isUsernameAvailable(username);
      
      if (!isAvailable) {
        return Left(Exception('Username is already taken'));
      }
      
      return Right(true);
    } catch (e) {
      return Left(Exception('Failed to check username availability'));
    }
  }
}

// Usage in intent
class CheckUsernameIntent extends JIntent<RegistrationState> {
  final String username;
  final CheckUsernameUseCase _useCase;

  CheckUsernameIntent(this.username, this._useCase);

  @override
  Future<void> onInvoke() async {
    controller.update((state) => state.copyWith(
      isCheckingUsername: true,
    ));

    final result = await _useCase(username);

    result.fold(
      (error) {
        controller.update((state) => state.copyWith(
          isCheckingUsername: false,
          usernameError: error.toString(),
          isUsernameAvailable: false,
        ));
      },
      (isAvailable) {
        controller.update((state) => state.copyWith(
          isCheckingUsername: false,
          usernameError: null,
          isUsernameAvailable: true,
        ));
      },
    );
  }
}
```

---

## Error Aggregation

### Form Validation with Multiple Errors

```dart
class ValidateProfileFormUseCase extends JUseCase<ProfileFormInput, ValidatedProfile> {
  @override
  Future<Either<Exception, ValidatedProfile>> run(ProfileFormInput input) async {
    final errors = <String>[];

    // Collect all validation errors
    if (input.firstName.trim().isEmpty) {
      errors.add('First name is required');
    }

    if (input.lastName.trim().isEmpty) {
      errors.add('Last name is required');
    }

    if (input.email.trim().isEmpty) {
      errors.add('Email is required');
    } else if (!_isValidEmail(input.email)) {
      errors.add('Email format is invalid');
    }

    if (input.phone.trim().isEmpty) {
      errors.add('Phone number is required');
    } else if (!_isValidPhone(input.phone)) {
      errors.add('Phone number format is invalid');
    }

    if (input.age < 18) {
      errors.add('Must be 18 years or older');
    }

    if (input.bio.length > 500) {
      errors.add('Bio must be less than 500 characters');
    }

    // Return all errors if any
    if (errors.isNotEmpty) {
      return Left(ValidationException(
        errors.join('\n'),
        errors,  // Pass as details
      ));
    }

    // All valid
    return Right(ValidatedProfile.from(input));
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _isValidPhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    return RegExp(r'^\+?[1-9]\d{9,14}$').hasMatch(cleaned);
  }
}

// Custom exception for validation
class ValidationException implements Exception {
  final String message;
  final List<String> errors;

  ValidationException(this.message, this.errors);

  @override
  String toString() => message;
}

// Usage in UI
class ProfileFormIntent extends JIntent<ProfileState> {
  final ProfileFormInput input;

  ProfileFormIntent(this.input);

  @override
  Future<void> onInvoke() async {
    final result = await _validateUseCase(input);

    result.fold(
      (error) {
        if (error is ValidationException) {
          // Show all errors
          controller.update((state) => state.copyWith(
            validationErrors: error.errors,
          ));
          
          // Show error effect
          controller.emitSideEffect(
            ShowValidationErrorsEffect(errors: error.errors),
          );
        } else {
          controller.update((state) => state.copyWith(
            validationErrors: [error.toString()],
          ));
        }
      },
      (validatedProfile) {
        controller.update((state) => state.copyWith(
          validationErrors: [],
          validatedProfile: validatedProfile,
        ));
        
        // Proceed to next step
        controller.emitSideEffect(NavigateToConfirmationEffect());
      },
    );
  }
}
```

---

## Best Practices

### 1. Fail Fast
Add validators in order of cost (cheap validation first):
```dart
CreateUserUseCase() {
  addValidator(_validateRequired);    // Cheapest: null/empty check
  addValidator(_validateFormat);      // Medium: regex
  addValidator(_validateBusinessRules); // Medium: logic
  // Async checks in run(), not validators
}
```

### 2. Clear Error Messages
```dart
// ❌ Bad
return Left(Exception('Invalid'));

// ✅ Good
return Left(Exception('Email format is invalid. Example: user@example.com'));
```

### 3. Sanitize Input
```dart
Either<Exception, CreatePostInput> _validateAndSanitize(CreatePostInput input) {
  // Sanitize
  final sanitizedTitle = input.title.trim();
  final sanitizedContent = input.content.trim();
  
  // Validate after sanitization
  if (sanitizedTitle.isEmpty) {
    return Left(Exception('Title cannot be empty'));
  }
  
  // Return sanitized input
  return Right(CreatePostInput(
    title: sanitizedTitle,
    content: sanitizedContent,
  ));
}
```

### 4. Compose Validators
```dart
// Create validator composition helper
Either<Exception, T> composeValidators<T>(
  T input,
  List<Either<Exception, T> Function(T)> validators,
) {
  for (final validator in validators) {
    final result = validator(input);
    if (result.isLeft) return result;
  }
  return Right(input);
}

// Use it
addValidator((input) => composeValidators(input, [
  _validateNotEmpty,
  _validateLength,
  _validateFormat,
]));
```

---

## Summary

Key takeaways:
- Use `UseCaseInputValidator` for synchronous validation
- Perform async validation in `run()` method
- Create reusable validators for common patterns
- Aggregate errors for better UX
- Fail fast with clear error messages
- Sanitize input before validation

For more information, see:
- [Security Guide](../SECURITY_GUIDE.md)
- [Error Handling Guide](../ERROR_HANDLING_GUIDE.md)
