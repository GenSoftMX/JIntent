# ADR-009: Semantic Versioning and Release Strategy

**Status:** Proposed  
**Date:** 2025-10-15  
**Deciders:** JIntent Maintainers (GenSoftMX)  
**Supersedes:** None  
**Superseded by:** None

---

## Context

JIntent is a public library published on pub.dev. Consumers depend on predictable, semantic versioning to understand the impact of upgrades. Without a clear versioning policy, users cannot confidently adopt new versions, and breaking changes can cause unexpected breakage in production applications.

Current version: **2.1.0**  
Historical versions: 1.0.0 (initial), 1.0.1 (side effects), 2.0.0 (major refactor)

We need to formalize the semantic versioning policy and release process to ensure:
1. Users can trust version numbers to indicate compatibility
2. Breaking changes are communicated clearly
3. Release quality is consistent
4. Pre-release channels enable early feedback

## Decision

### Adopt Strict Semantic Versioning (SemVer 2.0.0)

**Version Format:** `MAJOR.MINOR.PATCH[-PRERELEASE][+BUILD]`

#### MAJOR Version (X.0.0)
Increment when making **incompatible API changes**:
- Removing public APIs or classes
- Changing method signatures (parameters, return types)
- Renaming public APIs without deprecation period
- Changing behavior in ways that break existing code
- Removing deprecated APIs after notice period

**Examples:**
- Removing `JController.emitSideEffect()` → 3.0.0
- Changing `JUseCase<I, O>` to `JUseCase<I, O, E>` → 3.0.0
- Removing `JEffect` base class → 3.0.0

#### MINOR Version (X.Y.0)
Increment when adding **backward-compatible functionality**:
- Adding new public APIs, classes, or methods
- Adding optional parameters with defaults
- Deprecating APIs (with notice, removal comes in MAJOR)
- Adding new features without breaking existing usage
- Performance improvements without behavior changes

**Examples:**
- Adding `JController.emitAndWaitSideEffect()` → 2.1.0 ✅ (already done)
- Adding new `JEffect` subclasses → 2.2.0
- Adding `JController.pauseIntents()` → 2.2.0
- New `JObserver` hooks → 2.2.0

#### PATCH Version (X.Y.Z)
Increment for **backward-compatible bug fixes**:
- Fixing incorrect behavior without API changes
- Documentation corrections
- Internal refactoring with no API surface changes
- Performance improvements that don't change behavior
- Security patches

**Examples:**
- Fixing memory leak in effect stream → 2.1.1
- Correcting typos in documentation → 2.1.1
- Fixing null safety issue → 2.1.1

### Pre-Release Versions

**Format:** `MAJOR.MINOR.PATCH-IDENTIFIER.NUMBER`

**Pre-release channels:**
- **alpha** (early testing, unstable API): `2.2.0-alpha.1`
- **beta** (feature complete, API stable, testing): `2.2.0-beta.1`
- **rc** (release candidate, production-ready): `2.2.0-rc.1`

**Usage:**
- Pre-release versions are NOT considered stable
- Users must explicitly opt-in (e.g., `jintent: 2.2.0-beta.1`)
- Breaking changes allowed between alpha versions
- No breaking changes between beta/rc versions

**Lifecycle:**
```
2.2.0-alpha.1 → ... → 2.2.0-alpha.N  (unstable, API may change)
       ↓
2.2.0-beta.1 → ... → 2.2.0-beta.N    (API stable, testing phase)
       ↓
2.2.0-rc.1 → ... → 2.2.0-rc.N        (production candidate)
       ↓
2.2.0                                 (stable release)
```

### Build Metadata

**Format:** `MAJOR.MINOR.PATCH+BUILD`

**Usage:** Internal CI/CD builds only, not published to pub.dev  
**Example:** `2.1.0+20251015.abc123` (date + commit hash)

## Release Process

### 1. Pre-Release Checklist
- [ ] All tests passing (unit, integration, example app)
- [ ] Code coverage ≥70% (Phase 1 target)
- [ ] No high/critical security vulnerabilities
- [ ] CHANGELOG.md updated with all changes
- [ ] Migration guide written (if MAJOR version)
- [ ] API documentation up-to-date
- [ ] Example app tested on all platforms
- [ ] Breaking changes clearly marked
- [ ] Deprecation warnings added for removed APIs

### 2. Version Bump Strategy

**Automated checks:**
- CI/CD runs `dart pub publish --dry-run`
- Validates pubspec.yaml version follows SemVer
- Ensures CHANGELOG.md has entry for new version
- Checks for breaking changes in git diff

**Manual review:**
- Maintainer reviews CHANGELOG for correct version classification
- Verifies breaking changes justify MAJOR bump
- Confirms migration guide completeness

### 3. Publication Steps

```bash
# 1. Update version in pubspec.yaml
# 2. Update CHANGELOG.md
# 3. Commit changes
git add pubspec.yaml CHANGELOG.md
git commit -m "chore: bump version to X.Y.Z"

# 4. Create and push tag
git tag -a vX.Y.Z -m "Release version X.Y.Z"
git push origin vX.Y.Z

# 5. Publish to pub.dev (requires credentials)
dart pub publish

# 6. Create GitHub Release with CHANGELOG excerpt
gh release create vX.Y.Z --notes-file release-notes.md
```

### 4. Post-Release

- [ ] Verify package appears on pub.dev
- [ ] Update README badges if needed
- [ ] Announce on social media/community channels
- [ ] Monitor issue tracker for regression reports
- [ ] Close milestone in GitHub

## Alternatives Considered

### Alternative 1: CalVer (Calendar Versioning)
**Format:** `YYYY.MM.MICRO` (e.g., `2025.10.1`)  
**Pros:** Clear release timeline, easier to identify outdated versions  
**Cons:** Doesn't communicate compatibility, unfamiliar to Dart/Flutter developers

### Alternative 2: Rolling Release (No Versions)
**Pros:** Always latest code, no versioning overhead  
**Cons:** Impossible to pin stable versions, unpredictable breaking changes, poor for production use

### Alternative 3: API Versioning (Multiple Major Versions)
**Format:** `jintent_v2`, `jintent_v3` as separate packages  
**Pros:** Users can stay on old versions indefinitely  
**Cons:** Maintenance burden, ecosystem fragmentation

## Consequences

### Positive
- Clear versioning builds trust and predictability
- Pre-release channels enable early feedback without destabilizing stable
- Automated checks prevent accidental breaking changes
- Migration guides ease upgrade pain
- SemVer is familiar to all Dart/Flutter developers

### Negative
- Strict SemVer can delay feature releases (waiting for MINOR cycle)
- Maintaining deprecated APIs during deprecation period increases code complexity
- Pre-release testing requires dedicated testers

### Neutral
- Version bumps require discipline and process adherence
- Must resist pressure to "just make it a PATCH" for breaking changes

## Compliance Targets

### Phase 1 (Immediate)
- [ ] Document SemVer policy in README.md
- [ ] Add pre-release checklist to CONTRIBUTING.md
- [ ] Create release workflow documentation

### Phase 2 (Short-term)
- [ ] Automate version validation in CI/CD
- [ ] Add breaking change detection tooling
- [ ] Publish first CHANGELOG with SemVer classifications

### Phase 3 (Long-term)
- [ ] Automated release notes generation
- [ ] Community beta testing program
- [ ] Performance regression testing in CI/CD

## Edge Cases and Clarifications

### Q: Is adding a new required parameter to a constructor breaking?
**A:** Yes, it's a MAJOR change unless:
- The constructor was already `@internal` or `@visibleForTesting`
- A factory constructor with named parameters can add `required` params if old constructors remain

### Q: Is deprecating an API breaking?
**A:** No, deprecation is a MINOR change. Removal is MAJOR.

### Q: Is fixing a bug that users might depend on breaking?
**A:** Yes, if the "bug" was documented behavior. Document as breaking in CHANGELOG.

### Q: Can we skip beta/rc and go straight to stable?
**A:** Yes, for PATCH releases or well-tested MINOR releases. MAJOR releases should have beta/rc.

### Q: What if we discover a critical security issue?
**A:** Publish emergency PATCH release immediately, following expedited process (documented in SECURITY.md).

## References

- [Semantic Versioning 2.0.0](https://semver.org/)
- [Dart Versioning Philosophy](https://dart.dev/tools/pub/versioning)
- [pub.dev Publishing Guide](https://dart.dev/tools/pub/publishing)
- [Flutter Package Guidelines](https://flutter.dev/docs/development/packages-and-plugins/developing-packages)
- [ADR-000: Context and High-Level Decisions](./ADR-000-context-and-high-level-decisions.md)
- [ADR-008: Compatibility and Platform Support](./ADR-008-compatibility-and-platform-support.md)

---

**Related ADRs:**
- ADR-000: Establishes guiding principles including "Flexibility Without Fragmentation"
- ADR-008: Defines compatibility matrix and deprecation policy
- ADR-010: Details publication process and automation
