# JIntent API Inventory

**Version:** 2.1.0  
**Date:** 2025-10-14  
**Purpose:** Complete catalog of public API surface for stability tracking

---

## Overview

This document catalogs all publicly exported symbols in the JIntent library. Any changes to this surface require:
- **Additions (minor):** Documentation + tests
- **Modifications (major):** ADR + deprecation + migration guide
- **Removals (major):** ADR + deprecation period + migration guide

---

## 1. Core API (`lib/src/core/core.dart`)

### 1.1 Base Classes

#### `JController<T extends JState>`
**Status:** ✅ Stable (since 1.0.0)

**Public API:**
```dart
abstract class JController<T extends JState> extends StateNotifier<T> {
  // Constructor
  JController(T initialState, {JIntentDispatcher? dispatcher});
  
  // Lifecycle
  void onInit();
  @override void dispose();
  
  // State Management
  T get currentState;
  void update(T Function(T state) reducer, {JIntent? origin});
  
  @Deprecated('Use update() instead')
  void setState(T newState, {JIntent? origin});
  
  // Intent Handling
  Future<void> intent(JIntent<T> intent);
  
  // Side Effects
  Stream<JEffect> get sideEffects;
  void emitSideEffect(JEffect effect);
  Future<V> emitAndWaitSideEffect<V>(JEffect<V> effect, {Duration? timeout});
}
```

**Breaking Change Risk:** 🟢 Low (core contract stable)

---

#### `JIntent<T extends JState>`
**Status:** ✅ Stable (since 1.0.0)

**Public API:**
```dart
abstract class JIntent<T extends JState> {
  // Public execution (DO NOT override)
  Future<void> run(JController<T> controller);
  
  // Internal execution (DO NOT override)
  @protected
  Future<void> invoke(JController<T> controller);
  
  // Implementation point
  @visibleForOverriding
  Future<void> onInvoke();
  
  // Accessors
  T get state;
  JController<T> get controller;
}
```

**Breaking Change Risk:** 🟢 Low (core contract stable)

---

#### `JState`
**Status:** ✅ Stable (since 1.0.0)

**Public API:**
```dart
@immutable
abstract class JState extends Equatable {
  const JState();
  
  // Required overrides
  JState copyWith();
  
  @override
  List<Object?> get props;
}
```

**Breaking Change Risk:** 🟢 Low (core contract stable)

---

#### `JEffect<T>`
**Status:** ✅ Stable (added 2.0.0, enhanced 2.1.0)

**Public API:**
```dart
abstract class JEffect<T> {
  // Tracing (added 2.1.0)
  final String id;
  final DateTime createdAt;
  
  // Result handling
  Future<T> get result;
  void complete(T value);
  void completeError(Object error, [StackTrace? st]); // Added 2.1.0
  bool get isCompleted;
  
  // Metadata
  String? get resolvedCategory;
  
  @override
  String toString();
}
```

**Subclasses:**
```dart
abstract class JFireAndForgetEffect extends JEffect<void> {}
abstract class JResultEffect<T> extends JEffect<T> {}
abstract class JDialogEffect<T> extends JResultEffect<T> {}
```

**Breaking Change Risk:** 🟡 Medium (new methods in 2.1.0, monitor for adoption)

---

### 1.2 Dispatchers

#### `JIntentDispatcher` (Interface)
**Status:** ✅ Stable (since 2.0.0)

**Public API:**
```dart
abstract class JIntentDispatcher {
  Future<void> dispatch<T extends JState>(
    JIntent<T> intent,
    JController<T> controller,
  );
}
```

**Breaking Change Risk:** 🟢 Low (interface contract)

---

#### `JDefaultIntentDispatcher`
**Status:** ✅ Stable (since 2.0.0)

**Public API:**
```dart
class JDefaultIntentDispatcher implements JIntentDispatcher {
  @override
  Future<void> dispatch<T extends JState>(
    JIntent<T> intent,
    JController<T> controller,
  );
}
```

**Behavior:** Executes intents immediately (no queue, parallel possible)

**Breaking Change Risk:** 🟢 Low (simple implementation)

---

#### `JSequentialIntentDispatcher`
**Status:** ✅ Stable (added 2.1.0, now default)

**Public API:**
```dart
class JSequentialIntentDispatcher implements JIntentDispatcher {
  @override
  Future<void> dispatch<T extends JState>(
    JIntent<T> intent,
    JController<T> controller,
  );
}
```

**Behavior:** Queues intents, executes FIFO, errors don't break queue

**Breaking Change Risk:** 🟡 Medium (default changed in 2.1.0, monitor feedback)

---

### 1.3 Helpers & Metadata

#### `JMetaData` (Mixin)
**Status:** ✅ Stable (since 2.0.0)

**Public API:**
```dart
mixin JMetaData {
  String get name;
  String get type;
  Map<String, dynamic> get metadata;
}
```

**Usage:** Optional mixin for intents to provide debugging metadata

**Breaking Change Risk:** 🟢 Low (optional feature)

---

## 2. Dev Tools API (`lib/src/devtools/dev_tools.dart`)

### 2.1 Observer

#### `JObserver`
**Status:** ⚠️ Stable but design concern (global static state)

**Public API:**
```dart
class JObserver {
  // Callbacks (static, mutable)
  static void Function(JIntent intent)? onIntentDispatched;
  static void Function(JState prev, JState next, JIntent? origin)? onStateChanged;
  static void Function(JEffect effect)? onEffectEmitted;
  
  // Notification methods (called by framework)
  static void notifyIntentDispatched(JIntent intent);
  static void notifyStateChanged(JState prev, JState next, [JIntent? origin]);
  static void notifyEffectEmitted(JEffect effect);
}
```

**Breaking Change Risk:** 🔴 High (global state, potential refactor needed)  
**Deprecation Candidate:** Consider instance-based observer in 3.0.0

---

#### `enableLoggingObserver()`
**Status:** ✅ Stable (since 2.0.0)

**Public API:**
```dart
void enableLoggingObserver();
```

**Behavior:** Sets `JObserver` callbacks to `debugPrint` logs

**Breaking Change Risk:** 🟢 Low (convenience function)

---

### 2.2 Extensions

#### `LoggingDispatcher`
**Status:** ✅ Stable (since 2.0.0)

**Public API:**
```dart
class LoggingDispatcher implements JIntentDispatcher {
  LoggingDispatcher(this.inner);
  
  final JIntentDispatcher inner;
  
  @override
  Future<void> dispatch<T extends JState>(
    JIntent<T> intent,
    JController<T> controller,
  );
}
```

**Behavior:** Decorator pattern, logs before/after inner dispatcher

**Breaking Change Risk:** 🟢 Low (decorator implementation)

---

## 3. Effects API (`lib/src/core/effects/effects.dart`)

### 3.1 Configuration

#### `JEffectsConfig`
**Status:** ⚠️ Stable but global (added 2.1.0)

**Public API:**
```dart
class JEffectsConfig {
  Duration? defaultTimeout;
  String Function()? idGenerator;
  String? Function(JEffect)? categoryResolver;
  
  // Singleton access
  factory JEffectsConfig();
}
```

**Breaking Change Risk:** 🟡 Medium (global mutable config, Isolate safety unknown)

---

### 3.2 Mixins

#### `JCategorizableEffect`
**Status:** ✅ Stable (added 2.1.0)

**Public API:**
```dart
mixin JCategorizableEffect {
  String get category;
}
```

**Breaking Change Risk:** 🟢 Low (optional mixin)

---

### 3.3 Handlers

#### `EffectHandler<E, S>` (Type Alias)
**Status:** ✅ Stable (since 2.0.0)

**Public API:**
```dart
typedef EffectHandler<E extends JEffect, S extends JState> = Future<void> Function(
  E effect,
  JController<S> controller,
  BuildContext context,
);
```

**Breaking Change Risk:** 🟢 Low (type alias)

---

#### `JSideEffectHandler` (Widget)
**Status:** ✅ Stable (since 2.0.0)

**Public API:**
```dart
class JSideEffectHandler<S extends JState> extends StatefulWidget {
  const JSideEffectHandler({
    required this.controller,
    required this.handlers,
    required this.child,
  });
  
  final JController<S> controller;
  final Map<Type, EffectHandler> handlers;
  final Widget child;
}
```

**Breaking Change Risk:** 🟢 Low (stable widget pattern)

---

## 4. Domain API (`lib/src/domain/domain.dart`)

**Note:** These are optional patterns, not core to JIntent architecture.

### 4.1 Functional Types

#### `Either<L, R>`
**Status:** ✅ Stable (since 1.0.0)

**Public API:**
```dart
abstract class Either<L, R> {
  bool get isLeft;
  bool get isRight;
  
  L get left;
  R get right;
  
  T fold<T>(T Function(L) leftFn, T Function(R) rightFn);
}

class Left<L, R> extends Either<L, R> { ... }
class Right<L, R> extends Either<L, R> { ... }
```

**Breaking Change Risk:** 🟢 Low (standard functional pattern)

---

#### `UseCase<Type, Params>`
**Status:** ✅ Stable (since 1.0.0)

**Public API:**
```dart
abstract class UseCase<Type, Params> {
  Future<Either<Exception, Type>> call(Params params);
}

abstract class JSyncUseCase<Type, Params> {
  Either<Exception, Type> run(Params params);
}
```

**Breaking Change Risk:** 🟢 Low (optional pattern)

---

#### `Mapper<From, To>`
**Status:** ✅ Stable (since 1.0.0)

**Public API:**
```dart
abstract class Mapper<From, To> {
  To map(From from);
  From reverseMap(To to);
}
```

**Breaking Change Risk:** 🟢 Low (optional pattern)

---

## 5. Navigation API (`lib/src/navigation/`)

**Note:** Platform-specific abstractions, may be moved to separate package.

#### `JNavigator`
**Status:** ⚠️ Experimental (consider separate package)

**Public API:**
```dart
abstract class JNavigator {
  Future<T?> push<T>(BuildContext context, Route<T> route);
  Future<T?> pushNamed<T>(BuildContext context, String routeName, {Object? arguments});
  void pop<T>(BuildContext context, [T? result]);
  // ... other navigation methods
}
```

**Breaking Change Risk:** 🟡 Medium (may be deprecated/moved in 3.0.0)

---

## 6. Utils API (`lib/src/utils/main.dart`)

**Note:** General utilities, may be moved to separate package.

### `PlatformInfo`
**Status:** ⚠️ Experimental

**Public API:**
```dart
class PlatformInfo {
  static bool get isWeb;
  static bool get isAndroid;
  static bool get isIOS;
  // ... other platform checks
}
```

**Breaking Change Risk:** 🟡 Medium (may be deprecated/moved in 3.0.0)

---

### `Throttler`
**Status:** ⚠️ Experimental

**Public API:**
```dart
class Throttler {
  Throttler({required this.duration});
  
  final Duration duration;
  
  void call(VoidCallback action);
}
```

**Breaking Change Risk:** 🟡 Medium (may be deprecated/moved in 3.0.0)

---

### `ValidationUtils`
**Status:** ⚠️ Experimental

**Public API:**
```dart
class ValidationUtils {
  static bool isEmail(String value);
  static bool isPhoneNumber(String value);
  // ... other validators
}
```

**Breaking Change Risk:** 🟡 Medium (may be deprecated/moved in 3.0.0)

---

## 7. Summary

### API Stability Matrix

| Component | Status | Breaking Change Risk | Since Version |
|-----------|--------|----------------------|---------------|
| **Core** | | | |
| JController | ✅ Stable | 🟢 Low | 1.0.0 |
| JIntent | ✅ Stable | 🟢 Low | 1.0.0 |
| JState | ✅ Stable | 🟢 Low | 1.0.0 |
| JEffect | ✅ Stable | 🟡 Medium | 2.0.0 |
| **Dispatchers** | | | |
| JIntentDispatcher | ✅ Stable | 🟢 Low | 2.0.0 |
| JDefaultIntentDispatcher | ✅ Stable | 🟢 Low | 2.0.0 |
| JSequentialIntentDispatcher | ✅ Stable | 🟡 Medium | 2.1.0 |
| **Dev Tools** | | | |
| JObserver | ⚠️ Stable (design concern) | 🔴 High | 2.0.0 |
| LoggingDispatcher | ✅ Stable | 🟢 Low | 2.0.0 |
| **Domain** | | | |
| Either | ✅ Stable | 🟢 Low | 1.0.0 |
| UseCase | ✅ Stable | 🟢 Low | 1.0.0 |
| **Utils** | | | |
| Navigation | ⚠️ Experimental | 🟡 Medium | 1.0.0 |
| PlatformInfo | ⚠️ Experimental | 🟡 Medium | 1.0.0 |
| Throttler | ⚠️ Experimental | 🟡 Medium | 1.0.0 |
| ValidationUtils | ⚠️ Experimental | 🟡 Medium | 1.0.0 |

### Deprecations

| Symbol | Deprecated | Replacement | Remove In |
|--------|-----------|-------------|-----------|
| `JController.setState()` | 2.0.0 | `update()` | 3.0.0 |

### Planned Changes (Future)

**For 3.0.0 (Major):**
1. Remove `setState()` (deprecated)
2. Refactor `JObserver` to instance-based (breaking)
3. Consider moving utils/navigation to separate packages
4. Review `JEffectsConfig` for Isolate safety

**For 2.x (Minor):**
1. Add error handling hooks to `JObserver`
2. Add performance metrics hooks
3. Add structured logging format

---

## Usage Guidelines

### For Library Maintainers:
1. **Before adding to public API:** Review against ADR-000 principles
2. **Before changing public API:** Create ADR, update this inventory
3. **Before removing from API:** Deprecate for ≥1 minor version, provide migration guide

### For Library Users:
1. **Stable APIs (🟢):** Safe to use in production
2. **Medium Risk (🟡):** Use with caution, monitor changelogs
3. **High Risk (🔴):** May change significantly, have migration plan

---

**Document Status:** ✅ Complete  
**Next Review:** Upon any API change  
**Maintained By:** Development Team
