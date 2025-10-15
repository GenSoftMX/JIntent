# ADR-008: Compatibility and Platform Support

**Status:** Proposed  
**Date:** 2025-10-15  
**Deciders:** JIntent Maintainers (GenSoftMX)  
**Supersedes:** None  
**Superseded by:** None

---

## Context

As a Flutter library/SDK, JIntent must explicitly declare its compatibility commitments to enable consumers to make informed decisions about adoption. This includes minimum SDK requirements, platform support, and version compatibility guarantees.

The library targets multiple Flutter platforms (Android, iOS, Web, Desktop) and must balance broad compatibility with the ability to evolve and adopt new Flutter/Dart features.

## Decision

### Minimum SDK Requirements

- **Dart SDK:** `^3.7.2` (current stable)
- **Flutter SDK:** `>=1.17.0` (minimum for state_notifier compatibility)

### Platform Support

JIntent supports **all Flutter platforms**:
- ✅ Android
- ✅ iOS  
- ✅ Web
- ✅ Linux Desktop
- ✅ macOS Desktop
- ✅ Windows Desktop

**Rationale:** JIntent is a pure Dart package with no platform-specific code. It relies only on `flutter` SDK, `state_notifier`, and `equatable`, all of which support all platforms.

### Flutter Version Compatibility

- **Minimum Support:** Latest 3 stable Flutter versions
- **Testing Commitment:** CI/CD tests against:
  - Latest stable Flutter release
  - Previous stable release (N-1)
  - Previous stable release (N-2)

**Rationale:** Balances broad compatibility with maintenance burden. Most production apps stay within 2-3 versions of latest stable.

### Dart Language Version

- Current: Dart 3.x (null safety required)
- No support for Dart 2.x (null safety migration completed in v2.0.0)

### Breaking Changes Policy

- **Major version changes** (e.g., 2.x → 3.x): May introduce breaking changes with migration guide
- **Minor version changes** (e.g., 2.1.x → 2.2.x): Backward compatible new features only
- **Patch version changes** (e.g., 2.1.0 → 2.1.1): Bug fixes only, no API changes

### Deprecation Policy

When deprecating APIs:
1. Mark with `@deprecated` annotation with migration instructions
2. Maintain deprecated API for at least 1 minor version cycle (e.g., deprecated in 2.1.0, removed in 2.3.0)
3. Document in CHANGELOG.md with clear migration path
4. Provide automated migration guide where possible

### Version Support Timeline

- **Current Major Version:** Full support (bug fixes, features, security patches)
- **Previous Major Version:** Security patches only for 6 months after new major release
- **Older Versions:** Community support only (no official patches)

## Alternatives Considered

### Alternative 1: Support Only Latest Flutter Stable
**Pros:** Minimal maintenance burden, can use latest features immediately  
**Cons:** Forces users to upgrade Flutter frequently, reduces adoption

### Alternative 2: Support All Flutter Versions Since 1.0
**Pros:** Maximum compatibility  
**Cons:** Cannot adopt new Dart/Flutter features, high testing burden, complex codebase

### Alternative 3: Platform-Specific Packages
**Pros:** Could optimize per platform  
**Cons:** Unnecessary complexity, JIntent is pure Dart with no platform-specific code

## Consequences

### Positive
- Clear compatibility guarantees build user trust
- Testing on N-2 versions catches compatibility regressions early
- Deprecation policy prevents breaking changes without warning
- Support for all platforms maximizes adoption

### Negative
- Must maintain compatibility with 3 Flutter versions (testing overhead)
- Cannot immediately adopt features from latest Flutter/Dart versions
- Deprecation cycles slow down breaking change velocity

### Neutral
- Version support timeline requires clear communication in releases
- Must document compatibility matrix in README.md

## Implementation Notes

### Required Documentation Updates

1. **README.md**: Add "Compatibility" section with:
   - Minimum Flutter/Dart versions
   - Supported platforms
   - Testing matrix

2. **CHANGELOG.md**: Mark breaking changes clearly with migration guides

3. **pubspec.yaml**: Keep SDK constraints current
   ```yaml
   environment:
     sdk: ^3.7.2
     flutter: ">=1.17.0"
   ```

### CI/CD Requirements

- Test matrix covering Flutter stable, stable-1, stable-2
- Platform-specific integration tests (example app on all platforms)
- Automated dependency compatibility checks

### Communication Strategy

- Breaking changes announced 1 release cycle in advance
- Migration guides published before breaking change release
- Version support timeline communicated in releases

## Compliance Targets

- **Phase 1 Goal:** Document compatibility matrix in README.md
- **Phase 2 Goal:** Implement CI/CD testing matrix (3 Flutter versions)
- **Phase 3 Goal:** Automated compatibility regression testing

## References

- [Dart Versioning Strategy](https://dart.dev/tools/pub/versioning)
- [Flutter Release Process](https://github.com/flutter/flutter/wiki/Release-process)
- [Semantic Versioning 2.0.0](https://semver.org/)
- [ADR-000: Context and High-Level Decisions](./ADR-000-context-and-high-level-decisions.md)
- [ADR-009: Semantic Versioning and Release Strategy](./ADR-009-semantic-versioning-release.md)

---

**Related ADRs:**
- ADR-000: Establishes guiding principles
- ADR-009: Defines versioning strategy
- ADR-010: Publication process details
