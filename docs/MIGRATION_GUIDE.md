# Migration Guide

This guide helps you upgrade JIntent to newer versions with minimal disruption.

---

## Table of Contents

- [Version 1.x → 2.x](#version-1x--2x)
- [Future Migrations](#future-migrations)
- [General Migration Tips](#general-migration-tips)

---

## Version 1.x → 2.x

**Release Date:** June 2024  
**Breaking Changes:** Yes  
**Migration Effort:** Low-Medium (1-3 hours for typical project)

### Overview of Changes

Version 2.0.0 introduced:
1. **Removed `get_it` dependency** - You now manage your own dependency injection
2. **Side effect API changes** - Method renames and improved patterns
3. **Import path updates** - More consistent structure
4. **UI decoupling** - Intent-centric workflow

### Step-by-Step Migration

#### 1. Dependency Injection Changes

**Before (1.x):**
```dart
// JIntent automatically registered services with get_it
final controller = getIt<MyController>();
```

**After (2.x):**
```dart
// You manage DI yourself (use any DI solution)
// Example with Riverpod:
final myControllerProvider = Provider((ref) => MyController());

// Example with GetIt (if you choose):
getIt.registerSingleton<MyController>(MyController());
final controller = getIt<MyController>();

// Example with manual DI:
final controller = MyController(
  repository: MyRepository(),
  useCase: MyUseCase(),
);
```

**Why this change?**  
Removed tight coupling to `get_it`, giving you full control over your DI strategy. Use any DI solution: Riverpod, GetIt, Provider, or manual DI.

#### 2. Side Effect API Changes

**Before (1.x):**
```dart
// Old method name
controller.emitSideEffect(NavigateToDetailEffect(id: '123'));
```

**After (2.x):**
```dart
// Same method name, but enhanced with result support
controller.emitSideEffect(NavigateToDetailEffect(id: '123'));

// NEW: Wait for effect result (e.g., dialog confirmation)
final confirmed = await controller.emitAndWaitSideEffect(
  ConfirmDialogEffect(message: 'Are you sure?')
);
```

**Why this change?**  
Added `emitAndWaitSideEffect()` for effects that need results (dialogs, pickers), while keeping `emitSideEffect()` for fire-and-forget effects.

#### 3. Import Path Updates

**Before (1.x):**
```dart
import 'package:jintent/jintent.dart'; // Everything in one file
```

**After (2.x):**
```dart
// Still works:
import 'package:jintent/jintent.dart';

// Or more granular (optional):
import 'package:jintent/jintent.dart';
// All exports are still in the main barrel file
```

**Why this change?**  
Better organization, but backward compatible - you can still use the single import.

#### 4. Controller Instantiation

**Before (1.x):**
```dart
class MyController extends JController<MyState, MyIntent> {
  MyController() : super(MyState.initial());
  
  // Services accessed via get_it internally
}
```

**After (2.x):**
```dart
class MyController extends JController<MyState, MyIntent> {
  final MyRepository repository;
  final MyUseCase useCase;
  
  MyController({
    required this.repository,
    required this.useCase,
  }) : super(MyState.initial());
  
  // Inject dependencies explicitly
}
```

**Why this change?**  
Explicit dependencies are easier to test and reason about.

### Migration Checklist

- [ ] Remove `get_it` from your `pubspec.yaml` if no longer needed
- [ ] Choose your DI strategy (Riverpod, GetIt, manual, etc.)
- [ ] Update controller constructors to accept dependencies
- [ ] Update controller instantiation to pass dependencies
- [ ] Search codebase for `emitSideEffect` and evaluate if `emitAndWaitSideEffect` is better
- [ ] Run tests to ensure no regressions
- [ ] Update imports if using granular imports

### Testing Your Migration

```bash
# 1. Update pubspec.yaml
flutter pub get

# 2. Run static analysis
flutter analyze

# 3. Run all tests
flutter test

# 4. Test on target platforms
flutter run -d android
flutter run -d ios
flutter run -d web
```

### Common Issues

#### Issue: `get_it` not found
**Error:**
```
Error: Method not found: 'getIt'
```

**Solution:**
Add `get_it` to your `pubspec.yaml` if you want to continue using it, or migrate to another DI solution.

```yaml
dependencies:
  get_it: ^7.6.0  # If you want to keep using it
```

#### Issue: Controller constructor errors
**Error:**
```
Error: The constructor 'MyController' doesn't have a constructor argument 'repository'
```

**Solution:**
Update your controller to accept dependencies:
```dart
class MyController extends JController<MyState, MyIntent> {
  final MyRepository repository;
  
  MyController({required this.repository}) : super(MyState.initial());
}
```

### Need Help?

- **GitHub Issues:** [Report migration problems](https://github.com/GenSoftMX/JIntent/issues)
- **Discussions:** [Ask migration questions](https://github.com/GenSoftMX/JIntent/discussions)

---

## Future Migrations

### Version 2.x → 3.x (Planned)

No breaking changes planned yet. When version 3.0.0 is released, this guide will be updated with:
- Complete list of breaking changes
- Migration steps
- Code examples
- Common issues

**Stay Informed:**
- Watch the [GitHub repository](https://github.com/GenSoftMX/JIntent) for releases
- Check [CHANGELOG.md](../CHANGELOG.md) for updates
- Review deprecation warnings in your IDE

---

## General Migration Tips

### 1. Read the CHANGELOG First

Always review [CHANGELOG.md](../CHANGELOG.md) before upgrading:
- Understand what changed
- Identify breaking changes
- Review new features
- Check deprecation notices

### 2. Upgrade in Steps

For multi-version upgrades:
```
1.0.x → 1.0.latest → 2.0.0 → 2.0.latest → 2.1.0
```

**Why?** Easier to debug issues when upgrading incrementally.

### 3. Test Thoroughly

Migration testing checklist:
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Example app builds and runs
- [ ] Manual testing on all target platforms
- [ ] Performance baseline maintained

### 4. Use Version Constraints

In `pubspec.yaml`:
```yaml
dependencies:
  jintent: ^2.1.0  # Caret allows minor/patch updates
  # jintent: 2.1.0  # Exact version (not recommended)
  # jintent: '>=2.0.0 <3.0.0'  # Range constraint
```

**Recommendation:** Use caret (`^`) for automatic minor/patch updates while avoiding breaking changes.

### 5. Monitor Deprecation Warnings

JIntent marks deprecated APIs with `@deprecated`:
```dart
@deprecated('Use newMethod() instead. Will be removed in 3.0.0')
void oldMethod() { }
```

**IDE Support:**
- VS Code: Shows strikethrough on deprecated APIs
- Android Studio: Shows warning with migration tip

### 6. Rollback Plan

Before upgrading production:
1. Test in development/staging environment
2. Tag current working version in git: `git tag v1.0.0-working`
3. Document rollback command: `git checkout v1.0.0-working`
4. Keep old version in separate branch if needed

### 7. Communicate with Team

For team projects:
1. Announce migration plan
2. Share this guide with team
3. Schedule time for migration (don't rush)
4. Review changes in code review
5. Update team documentation

---

## Migration Support

### Self-Service Resources

- **Documentation:** [docs/](./README.md)
- **Examples:** [example/](../example/)
- **CHANGELOG:** [CHANGELOG.md](../CHANGELOG.md)
- **ADRs:** [docs/adr/](./adr/)

### Community Support

- **GitHub Discussions:** [Ask questions](https://github.com/GenSoftMX/JIntent/discussions)
- **GitHub Issues:** [Report bugs](https://github.com/GenSoftMX/JIntent/issues)

### Professional Support

For enterprise support or consulting:
- Email: **support@todoflutter.com**
- Include: Project details, timeline, specific needs

---

## Automated Migration Tools

### Future: Dart Fix Support

We plan to provide automated migration via `dart fix` in future versions:

```bash
# Future feature (not yet available)
dart fix --apply
```

This will automatically migrate deprecated APIs to new patterns.

**Current Status:** Not implemented yet (planned for Phase 2)

---

## Contributing to Migration Guides

Found an issue or have a migration tip? Help improve this guide:

1. Fork the repository
2. Edit `docs/MIGRATION_GUIDE.md`
3. Submit a pull request
4. Include:
   - Clear description of issue/tip
   - Code examples
   - Tested solution

---

**Last Updated:** 2025-10-15  
**Next Review:** After next major/minor release  
**Maintainer:** JIntent Team (GenSoftMX)
