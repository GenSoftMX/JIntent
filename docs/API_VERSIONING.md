# JIntent API Versioning Strategy

**Version:** 1.0  
**Status:** Active  
**Last Updated:** 2025-10-15  
**Applies To:** JIntent 2.1.0+

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Semantic Versioning](#2-semantic-versioning)
3. [Public API Surface](#3-public-api-surface)
4. [Breaking Change Policy](#4-breaking-change-policy)
5. [Deprecation Process](#5-deprecation-process)
6. [Migration Guides](#6-migration-guides)
7. [Versioning Examples](#7-versioning-examples)
8. [Release Process](#8-release-process)
9. [Backwards Compatibility](#9-backwards-compatibility)

---

## 1. Introduction

### 1.1 Purpose

This document defines the API versioning strategy for JIntent, ensuring predictable evolution and clear communication of changes to library consumers.

### 1.2 Goals

- **Stability:** Minimize breaking changes
- **Predictability:** Clear version number meaning
- **Transparency:** Well-documented changes
- **Ease of Migration:** Clear upgrade paths
- **Trust:** Reliable versioning commitments

### 1.3 Versioning Philosophy

JIntent follows **Semantic Versioning 2.0.0** (SemVer) with strict adherence to:
1. **MAJOR:** Breaking API changes
2. **MINOR:** New features, backwards-compatible
3. **PATCH:** Bug fixes, no API changes

---

## 2. Semantic Versioning

### 2.1 Version Format

```
MAJOR.MINOR.PATCH
  │     │     │
  │     │     └─── Bug fixes only (2.1.0 → 2.1.1)
  │     └───────── New features, backwards-compatible (2.1.0 → 2.2.0)
  └─────────────── Breaking changes (2.1.0 → 3.0.0)
```

### 2.2 Version Components

#### MAJOR Version (Breaking Changes)

Increment when making incompatible API changes:
- Removing public classes, methods, or properties
- Changing method signatures
- Renaming public APIs
- Changing behavior of existing APIs in incompatible ways
- Removing or changing constructor parameters
- Changing return types

**Example:** 2.1.0 → 3.0.0

#### MINOR Version (New Features)

Increment when adding functionality in a backwards-compatible manner:
- Adding new classes
- Adding new methods to existing classes
- Adding new optional parameters
- Adding new properties
- Adding new features
- Deprecating APIs (without removing)

**Example:** 2.1.0 → 2.2.0

#### PATCH Version (Bug Fixes)

Increment when making backwards-compatible bug fixes:
- Fixing incorrect behavior
- Performance improvements
- Documentation updates
- Internal refactoring (no API changes)
- Security patches (if no API changes)

**Example:** 2.1.0 → 2.1.1

### 2.3 Pre-release Versions

For pre-release versions, append a hyphen and identifier:

```
3.0.0-alpha.1    # Alpha release
3.0.0-beta.1     # Beta release  
3.0.0-rc.1       # Release candidate
```

**Stability Guarantees:**
- **alpha:** Experimental, API may change significantly
- **beta:** Feature complete, API mostly stable
- **rc:** Production candidate, no expected changes

---

## 3. Public API Surface

### 3.1 What is "Public API"?

The **public API** includes all symbols exported from `lib/jintent.dart`:

```dart
// lib/jintent.dart - Public API entry point
library jintent;

// Core architecture
export 'src/core/jstate.dart';
export 'src/core/jintent.dart';
export 'src/core/jcontroller.dart';
export 'src/core/jmeta_data.dart';

// Side effects
export 'src/core/effects/jeffect.dart';
export 'src/core/effects/jfire_and_forget_effect.dart';
export 'src/core/effects/jresult_effect.dart';
export 'src/core/effects/jdialog_effect.dart';
export 'src/core/effects/jside_effect_handler.dart';
export 'src/core/effects/jeffects_config.dart';

// Domain abstractions
export 'src/domain/either.dart';
export 'src/domain/use_case.dart';
export 'src/domain/mapper.dart';

// Dev tools
export 'src/devtools/logging_observer.dart';
export 'src/devtools/jobserver.dart';

// Navigation
export 'src/navigation/jnavigator_observer.dart';

// Utilities
export 'src/utils/jintent_helpers.dart';
```

**Public API Elements:**
- Public classes, interfaces, abstract classes
- Public methods and properties
- Public constructors
- Public constants and enums
- Documented behavior (contracts)

### 3.2 What is NOT "Public API"?

The following are **NOT** part of the public API and can change at any time:

#### Internal Implementation (`lib/src/*` not re-exported)

```dart
// lib/src/core/internal/sequential_dispatcher.dart
// NOT exported from jintent.dart = not public API
class JSequentialIntentDispatcher { ... }
```

#### Private Members (prefixed with `_`)

```dart
class JController<T extends JState> {
  // Private - not public API
  final List<JIntent<T>> _intentQueue = [];
  
  // Public - part of API
  Stream<JEffect> get sideEffects;
}
```

#### Documentation Disclaimers

APIs marked with `@internal`, `@experimental`, or `@visibleForTesting`:

```dart
/// Internal use only. May change without notice.
@internal
class InternalHelper { ... }

/// Experimental feature. API may change in minor versions.
@experimental
void experimentalFeature() { ... }
```

#### Test Utilities

Files in `test/` directory are not part of public API.

---

## 4. Breaking Change Policy

### 4.1 Definition of Breaking Change

A change is **breaking** if it requires consumers to modify their code to maintain functionality.

#### Examples of Breaking Changes

**1. Removing a Public API**

```dart
// v2.1.0
class JController {
  void doSomething() { ... }  // Public method
}

// v3.0.0 - BREAKING
class JController {
  // Method removed - users' code will break
}
```

**2. Changing Method Signature**

```dart
// v2.1.0
void emitSideEffect(JEffect effect) { ... }

// v3.0.0 - BREAKING
void emitSideEffect(JEffect effect, {bool immediate = false}) { 
  // Added required parameter
}
```

**3. Renaming Public API**

```dart
// v2.1.0
class JState { ... }

// v3.0.0 - BREAKING
class JStateBase { ... }  // Renamed
```

**4. Changing Return Type**

```dart
// v2.1.0
String getUserId() { ... }

// v3.0.0 - BREAKING
int getUserId() { ... }  // Changed return type
```

**5. Changing Behavior**

```dart
// v2.1.0 - intents processed sequentially
void intent(JIntent intent) { 
  _queue.add(intent);
}

// v3.0.0 - BREAKING - now parallel (behavioral change)
void intent(JIntent intent) { 
  _process(intent);  // Immediate, breaking sequential guarantee
}
```

### 4.2 Allowed in Minor Versions

The following are **NOT breaking** and allowed in minor versions:

**1. Adding New APIs**

```dart
// v2.1.0
class JController { ... }

// v2.2.0 - OK (new method, backwards compatible)
class JController {
  void newMethod() { ... }  // New method added
}
```

**2. Adding Optional Parameters**

```dart
// v2.1.0
void emitSideEffect(JEffect effect) { ... }

// v2.2.0 - OK (optional parameter with default)
void emitSideEffect(JEffect effect, {Duration? timeout}) { ... }
```

**3. Deprecating APIs**

```dart
// v2.2.0 - OK to deprecate (but not remove)
@Deprecated('Use newMethod() instead. Will be removed in 3.0.0')
void oldMethod() { ... }

void newMethod() { ... }  // Replacement provided
```

**4. Internal Implementation Changes**

```dart
// v2.1.0
class JController {
  void _internalHelper() { ... }
}

// v2.2.0 - OK (private method changed)
class JController {
  void _internalHelper2() { ... }  // Private can change
}
```

### 4.3 Breaking Change Approval

Before introducing a breaking change:

1. **Justification:** Document why the change is necessary
2. **Impact Analysis:** Estimate how many users are affected
3. **Migration Path:** Provide clear upgrade instructions
4. **Deprecation Period:** Deprecate in minor version first (if possible)
5. **Community Feedback:** Discuss in GitHub issue before implementing

---

## 5. Deprecation Process

### 5.1 Deprecation Timeline

When deprecating an API:

1. **Minor Version (N.x.0):** Mark as deprecated, add replacement
2. **Wait Period:** At least one MAJOR version cycle
3. **Major Version (N+1.0.0):** Remove deprecated API

**Example:**
```
v2.1.0: Introduce newMethod()
v2.2.0: Deprecate oldMethod(), suggest newMethod()
v2.3.0+: oldMethod() still available but deprecated
v3.0.0: Remove oldMethod()
```

### 5.2 Deprecation Annotation

Use `@Deprecated` with clear guidance:

```dart
@Deprecated(
  'Use emitSideEffect() instead. '
  'This will be removed in version 3.0.0. '
  'See https://github.com/GenSoftMX/JIntent/wiki/Migration-v3'
)
void emitEffect(JEffect effect) {
  emitSideEffect(effect);  // Delegate to new method
}

/// Replacement for deprecated emitEffect()
void emitSideEffect(JEffect effect) {
  // New implementation
}
```

### 5.3 Deprecation Documentation

In CHANGELOG.md:

```markdown
## [2.2.0] - 2025-11-01

### Deprecated
- `JController.emitEffect()` is deprecated. Use `emitSideEffect()` instead.
  - **Reason:** Naming consistency with side effects terminology
  - **Migration:** Replace `emitEffect(effect)` with `emitSideEffect(effect)`
  - **Removal:** Planned for version 3.0.0
```

### 5.4 Communication

When deprecating:
- Add deprecation notice to CHANGELOG
- Update documentation
- Create GitHub issue explaining deprecation
- Provide migration examples
- Announce in release notes

---

## 6. Migration Guides

### 6.1 Migration Guide Template

For each MAJOR version, provide a migration guide:

```markdown
# Migration Guide: v2.x → v3.0

## Breaking Changes

### 1. JController.emitEffect() removed

**What changed:**
- Method `emitEffect()` has been removed

**Why:**
- Naming consistency with side effects terminology

**How to migrate:**
```dart
// Before (v2.x)
controller.emitEffect(ShowSnackbarEffect('Hello'));

// After (v3.0)
controller.emitSideEffect(ShowSnackbarEffect('Hello'));
```

### 2. JState now requires const constructor

**What changed:**
- State classes must use const constructors

**Why:**
- Performance optimization

**How to migrate:**
```dart
// Before (v2.x)
class MyState extends JState {
  final int counter;
  MyState({required this.counter});
}

// After (v3.0)
class MyState extends JState {
  final int counter;
  const MyState({required this.counter});  // Added const
}
```
```

### 6.2 Migration Guide Location

Migration guides should be:
1. In `docs/migrations/` directory
2. Linked from main README
3. Referenced in CHANGELOG
4. Announced in release notes

---

## 7. Versioning Examples

### 7.1 Example: Bug Fix (Patch)

**Scenario:** Fix incorrect state notification

```dart
// v2.1.0 - Bug: state not notified on update
void update(T Function(T) reducer) {
  final newState = reducer(state);
  state = newState;
  // BUG: Missing notification
}

// v2.1.1 - Fixed (PATCH version)
void update(T Function(T) reducer) {
  final newState = reducer(state);
  state = newState;
  notifyListeners();  // Fixed: Now notifies
}
```

**Version:** 2.1.0 → 2.1.1 (PATCH)  
**Reason:** Bug fix, no API change

### 7.2 Example: New Feature (Minor)

**Scenario:** Add effect priority support

```dart
// v2.1.0 - Original API
abstract class JEffect<T> {
  Future<T> get result;
  void complete(T value);
}

// v2.2.0 - New feature (MINOR version)
abstract class JEffect<T> {
  Future<T> get result;
  void complete(T value);
  
  // NEW: Optional priority property
  int get priority => 0;  // Default implementation
}

class JResultEffect<T> extends JEffect<T> {
  @override
  final int priority;  // Can be customized
  
  JResultEffect({this.priority = 0});  // Optional parameter
}
```

**Version:** 2.1.0 → 2.2.0 (MINOR)  
**Reason:** New feature, backwards compatible (default value provided)

### 7.3 Example: Breaking Change (Major)

**Scenario:** Change JIntent to async-only

```dart
// v2.1.0 - Original API
abstract class JIntent<T extends JState> {
  void onInvoke();  // Synchronous
  T get state;
  JController<T> get controller;
}

// v3.0.0 - Breaking change (MAJOR version)
abstract class JIntent<T extends JState> {
  Future<void> onInvoke();  // Now async (BREAKING)
  T get state;
  JController<T> get controller;
}
```

**Version:** 2.1.0 → 3.0.0 (MAJOR)  
**Reason:** Changed return type from `void` to `Future<void>` (breaking)

**Migration:**
```dart
// v2.x
class MyIntent extends JIntent<MyState> {
  @override
  void onInvoke() {
    // Synchronous logic
  }
}

// v3.0
class MyIntent extends JIntent<MyState> {
  @override
  Future<void> onInvoke() async {
    // Now async
  }
}
```

### 7.4 Example: Deprecation + Removal

**Timeline:**

**v2.1.0 - Original**
```dart
class JController {
  void emitEffect(JEffect effect) { ... }
}
```

**v2.2.0 - Deprecation (MINOR)**
```dart
class JController {
  @Deprecated('Use emitSideEffect() instead. Removed in 3.0.0')
  void emitEffect(JEffect effect) {
    emitSideEffect(effect);
  }
  
  void emitSideEffect(JEffect effect) { ... }  // New method
}
```

**v3.0.0 - Removal (MAJOR)**
```dart
class JController {
  // emitEffect() removed
  void emitSideEffect(JEffect effect) { ... }
}
```

---

## 8. Release Process

### 8.1 Version Decision Flowchart

```
Is this a breaking change?
├─ Yes → MAJOR version (x.0.0)
└─ No → Is this a new feature?
    ├─ Yes → MINOR version (x.y.0)
    └─ No → PATCH version (x.y.z)
```

### 8.2 Pre-Release Checklist

Before releasing a new version:

**For All Releases:**
- [ ] All tests passing
- [ ] Documentation updated
- [ ] CHANGELOG updated
- [ ] Version number updated in pubspec.yaml
- [ ] Git tag created

**For Minor/Major Releases:**
- [ ] Migration guide written (if breaking changes)
- [ ] Examples updated
- [ ] README updated
- [ ] API documentation reviewed

**For Major Releases:**
- [ ] Breaking changes justified
- [ ] Community feedback gathered
- [ ] Migration path tested
- [ ] Beta/RC releases completed

### 8.3 Release Announcement Template

```markdown
# JIntent v2.2.0 Released 🎉

We're excited to announce JIntent v2.2.0 with new features and improvements!

## ✨ New Features
- Effect priority support (#123)
- Enhanced logging observer (#124)

## 🔧 Improvements
- Performance optimization for state updates (#125)
- Better TypeScript type definitions (#126)

## 📚 Documentation
- New validation examples
- Updated API reference

## 🔄 Migration
No breaking changes! Simply update your pubspec.yaml:

```yaml
dependencies:
  jintent: ^2.2.0
```

## 🙏 Contributors
Thanks to @user1, @user2 for contributions!

## 📖 Full Changelog
See CHANGELOG.md for complete details.
```

### 8.4 CHANGELOG Format

Follow Keep a Changelog format:

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- New feature X

### Changed
- Modified behavior Y

### Deprecated
- Method Z (use W instead)

### Removed
- (None)

### Fixed
- Bug fix A

### Security
- Security patch B

## [2.2.0] - 2025-11-01

### Added
- Effect priority support
- Enhanced logging

### Fixed
- State notification bug

## [2.1.0] - 2025-10-01
...
```

---

## 9. Backwards Compatibility

### 9.1 Compatibility Guarantees

**Within a Major Version:**
- Patch versions are always compatible
- Minor versions are always backwards compatible
- Code working on 2.1.0 will work on 2.2.0, 2.3.0, etc.

**Across Major Versions:**
- No compatibility guarantee
- Migration guide provided
- Deprecation warnings given in advance

### 9.2 Compatibility Testing

For each release, test against:
- Previous MINOR version
- Example app
- Common use cases

```bash
# Test compatibility
flutter test
flutter analyze
flutter pub publish --dry-run
```

### 9.3 Version Constraints in Dependencies

Recommended constraints for consumers:

```yaml
# Recommended: Allow minor and patch updates
dependencies:
  jintent: ^2.1.0  # Allows 2.1.0 to <3.0.0

# More restrictive: Only patch updates
dependencies:
  jintent: '>=2.1.0 <2.2.0'

# Not recommended: Too permissive
dependencies:
  jintent: any  # ❌ Allows breaking changes
```

### 9.4 Minimum Dart/Flutter Versions

Specify minimum versions in pubspec.yaml:

```yaml
environment:
  sdk: ^3.7.2
  flutter: ">=1.17.0"
```

**Version Support Policy:**
- Support last 3 Dart stable versions
- Support last 2 Flutter stable versions
- Announce deprecation 6 months before dropping support

---

## 10. Versioning Decision Reference

### 10.1 Quick Reference

| Change Type | Example | Version |
|-------------|---------|---------|
| Bug fix | Fix state notification | PATCH |
| Performance improvement | Optimize controller | PATCH |
| Documentation update | Fix typo in README | PATCH |
| New optional parameter | Add `timeout` parameter | MINOR |
| New method | Add `retryEffect()` | MINOR |
| New class | Add `JBatchEffect` | MINOR |
| Deprecate method | Mark `emitEffect()` deprecated | MINOR |
| Remove method | Delete deprecated method | MAJOR |
| Rename class | `JState` → `JStateBase` | MAJOR |
| Change signature | Required parameter added | MAJOR |
| Change behavior | Sequential → parallel | MAJOR |

### 10.2 When in Doubt

If unsure whether a change is breaking:
1. Ask: "Would existing code need to change?"
2. If yes → MAJOR
3. If no but adds functionality → MINOR
4. If no and fixes bug → PATCH

**Rule of thumb:** Err on the side of a MAJOR version if uncertain.

---

## 11. Additional Resources

### 11.1 Related Documentation

- [ADR-001: API Design and Versioning](./adr/ADR-001-api-design-and-versioning.md)
- [Contributing Guidelines](../README.md#contributing-guidelines)
- [CHANGELOG.md](../CHANGELOG.md)

### 11.2 External Resources

- [Semantic Versioning 2.0.0](https://semver.org/)
- [Keep a Changelog](https://keepachangelog.com/)
- [Dart Package Versioning](https://dart.dev/tools/pub/versioning)
- [Pub.dev Publishing](https://dart.dev/tools/pub/publishing)

---

**Document Version:** 1.0  
**Last Updated:** 2025-10-15  
**Next Review:** 2025-11-15  
**Maintained By:** JIntent Core Team
