# ADR-001: API Design and Versioning

**Status:** Proposed  
**Date:** 2025-10-15  
**Deciders:** Project Maintainers, Community  
**Context:** Phase 1 Foundation - API Stability  
**Related:** [ADR-000](./ADR-000-context-and-high-level-decisions.md)

---

## 1. Status

**Current Status:** Proposed  
**Approval Status:** Pending Stakeholder Review

This ADR defines the API design principles, versioning strategy, and breaking change policies for JIntent to ensure stability and predictable evolution.

---

## 2. Context

### 2.1 Background

JIntent has evolved from v1.0.0 to v2.1.0 with significant changes:
- v1.0.0: Initial MVI pattern implementation
- v2.0.0: Breaking changes - removed get_it, introduced side effects system
- v2.1.0: Sequential intent handling, enhanced effects

The project needs clear API design guidelines to:
- Minimize breaking changes for users
- Enable predictable version upgrades
- Maintain backward compatibility when possible
- Provide clear migration paths when breaking changes are necessary

### 2.2 Problem Statement

**Current Challenges:**
- No formal API versioning policy documented
- Breaking changes have occurred between major versions
- Migration guidance exists but could be more structured
- No clear deprecation timeline policy

**Business Impact:**
- User frustration with breaking changes
- Migration effort for consumers
- Reduced adoption due to instability concerns

---

## 3. Decision

### 3.1 Semantic Versioning

**Decision:** Follow strict Semantic Versioning (SemVer) 2.0.0

**Version Format:** MAJOR.MINOR.PATCH (e.g., 2.1.0)

**Increment Rules:**
- **MAJOR:** Breaking API changes (incompatible)
- **MINOR:** New features, backward-compatible additions
- **PATCH:** Bug fixes, no API changes

**Examples:**
- Adding new optional parameters → MINOR
- Removing public method → MAJOR
- Fixing calculation bug → PATCH
- Renaming public class → MAJOR

### 3.2 Public API Surface

**Decision:** Clearly define what constitutes the "public API"

**Public API Includes:**
- All classes exported from `lib/jintent.dart`
- Public methods, properties, constructors
- Public abstract classes and interfaces
- Documented behavior (not implementation details)

**Not Public API (Can Change):**
- Files under `lib/src/` not re-exported
- Private members (prefixed with `_`)
- Internal implementation details
- Test utilities in `test/` directory

**Public API Classes (Current v2.1.0):**
```dart
// Core
- JState
- JIntent
- JController<TState, TIntent>
- JMetadata

// Effects
- JEffect<T>
- JFireAndForgetEffect
- JResultEffect<T>
- JDialogEffect<T>
- JSideEffectHandler<TState>
- JEffectsConfig

// Domain
- Either<L, R>
- JUseCase<INPUT, OUTPUT>
- JMapper<FROM, TO>

// DevTools
- JObserver
- enableLoggingObserver()

// Utils
- SequentialIntentDispatcher
```

### 3.3 Breaking Change Policy

**Decision:** Minimize breaking changes, provide migration paths

**Breaking Changes Require:**
1. Major version increment (e.g., 2.x → 3.0)
2. Clear rationale documented in CHANGELOG
3. Migration guide with code examples
4. At least one deprecation cycle when feasible (see below)

**Breaking Change Examples:**
- Removing public class or method
- Changing method signature (parameters, return type)
- Changing behavior that users depend on
- Renaming public API elements

**Not Breaking Changes:**
- Adding new optional parameters with defaults
- Adding new classes or methods
- Changing internal implementation
- Performance improvements
- Bug fixes (even if behavior changes)

### 3.4 Deprecation Policy

**Decision:** Use deprecation warnings before removal when possible

**Deprecation Process:**
1. Mark API element with `@Deprecated('message')` annotation
2. Provide alternative in deprecation message
3. Document in CHANGELOG under "Deprecated" section
4. Keep deprecated API for at least one MINOR version
5. Remove in next MAJOR version

**Example:**
```dart
@Deprecated('Use emitSideEffect() instead. Will be removed in v3.0.0')
void triggerEffect(JEffect effect) {
  emitSideEffect(effect);
}
```

**Deprecation Timeline:**
- Minimum: 1 minor version (e.g., deprecated in 2.1.0, removed in 3.0.0)
- Recommended: 2-3 minor versions for widely-used APIs
- Critical: 6+ months between deprecation and removal

### 3.5 API Stability Guarantees

**Decision:** Provide stability commitments per version range

**Stability Levels:**

**1. Stable (Current: v2.x)**
- Public API frozen for MAJOR version
- Only additions allowed (MINOR)
- Bug fixes allowed (PATCH)
- Breaking changes only in next MAJOR

**2. Experimental (Future Features)**
- Mark with `@experimental` annotation
- Can change in MINOR versions
- Documented as experimental in dartdoc
- Example: Future undo/redo support

**3. Internal (Implementation)**
- No stability guarantees
- Can change any time
- Not exported from main library

### 3.6 API Evolution Guidelines

**Decision:** Follow these principles when evolving the API

**1. Extend, Don't Modify**
- Add new classes/methods rather than changing existing ones
- Use factory constructors for flexibility
- Prefer composition over inheritance

**2. Optional Parameters**
- Use named parameters for flexibility
- Provide sensible defaults
- Make parameters optional when possible

**3. Backward Compatibility First**
- Exhaust all options before breaking changes
- Consider adapter pattern for major refactors
- Maintain old API alongside new when feasible

**4. Clear Migration Paths**
- Provide automated migration tools when possible (pub run jintent:migrate)
- Document step-by-step migration in MIGRATION.md
- Show before/after code examples

### 3.7 Version Numbering Strategy

**Decision:** Version numbers communicate stability and change magnitude

**Current Version:** 2.1.0

**Future Path:**
- v2.x.x: Continue with non-breaking improvements
- v3.0.0: Next breaking change cycle (planned ~2026)

**Pre-release Versions:**
- Alpha: Major features in development (3.0.0-alpha.1)
- Beta: Feature complete, testing phase (3.0.0-beta.1)
- RC: Release candidate, final testing (3.0.0-rc.1)

**Version Metadata:**
- Build metadata allowed (e.g., 2.1.0+001)
- Not used for precedence (2.1.0 == 2.1.0+001)

### 3.8 API Documentation Requirements

**Decision:** All public API must be documented before release

**Requirements:**
- Public classes: purpose, usage, example
- Public methods: parameters, return value, exceptions
- Public properties: meaning, valid values
- Deprecated APIs: migration path

**Example:**
```dart
/// Manages state and intent handling for the application.
///
/// [JController] is the central component of JIntent architecture.
/// It receives [JIntent] instances, processes them, and updates [JState].
///
/// Example:
/// ```dart
/// class CounterController extends JController<CounterState, CounterIntent> {
///   CounterController() : super(CounterState(count: 0));
///   
///   @override
///   void handleIntent(CounterIntent intent) {
///     if (intent is IncrementIntent) {
///       setState(state.copyWith(count: state.count + 1));
///     }
///   }
/// }
/// ```
///
/// See also:
/// - [JState] for state management
/// - [JIntent] for intent definitions
class JController<TState extends JState, TIntent extends JIntent> { ... }
```

---

## 4. Consequences

### 4.1 Positive Consequences

✅ **User Confidence**
- Predictable upgrade path
- Clear version meaning (major vs minor)
- Reduced fear of upgrades

✅ **Maintainability**
- Clear rules for API changes
- Documented decision process
- Less debate on version numbers

✅ **Ecosystem Health**
- Other packages can depend safely
- Version constraints meaningful
- Reduced downstream breakage

✅ **Professional Image**
- Industry-standard practices
- Mature governance
- Enterprise-ready

### 4.2 Negative Consequences

⚠️ **Slower Evolution**
- Must maintain deprecated APIs
- Can't quickly fix design mistakes
- More planning required

⚠️ **Documentation Overhead**
- Must document all deprecations
- Migration guides required
- More CHANGELOG detail

⚠️ **Testing Burden**
- Must test deprecated and new APIs
- Longer test suites
- More maintenance

### 4.3 Mitigation Strategies

**For Slower Evolution:**
- Use experimental APIs for new features
- Plan deprecation cycles in advance
- Bundle related breaking changes in major versions

**For Documentation:**
- Use automated tools (dartdoc)
- Templates for deprecation notices
- Community contributions

**For Testing:**
- Automated test generation
- Focus on high-value test coverage
- Remove deprecated API tests after removal

---

## 5. Implementation Plan

### Phase 1: Documentation (Current)
- [x] Create ADR-001
- [ ] Update CHANGELOG with versioning policy
- [ ] Add VERSIONING.md guide
- [ ] Document public API surface

### Phase 2: Tooling (Future)
- [ ] Add automated API surface reporting
- [ ] Create migration helper scripts
- [ ] API breaking change detector in CI

### Phase 3: Process Integration
- [ ] Update PR template with version impact
- [ ] Add version bump checklist
- [ ] Train maintainers on policy

---

## 6. Examples

### Example 1: Adding New Optional Parameter (MINOR)

**Before (v2.1.0):**
```dart
void emitSideEffect(JEffect effect);
```

**After (v2.2.0):**
```dart
void emitSideEffect(JEffect effect, {Duration? timeout});
```

**Version:** 2.1.0 → 2.2.0 (MINOR)  
**Rationale:** Backward compatible, existing code still works

### Example 2: Deprecating Method (MAJOR with Warning)

**v2.2.0 (Deprecation):**
```dart
@Deprecated('Use emitSideEffect() instead. Will be removed in v3.0.0')
void triggerEffect(JEffect effect) {
  emitSideEffect(effect);
}
```

**v3.0.0 (Removal):**
```dart
// triggerEffect() removed
```

**CHANGELOG v2.2.0:**
```markdown
### Deprecated
- `triggerEffect()` deprecated in favor of `emitSideEffect()`. Will be removed in v3.0.0.
```

### Example 3: Breaking Change (MAJOR)

**Before (v2.x):**
```dart
abstract class JIntent {}
```

**After (v3.0.0):**
```dart
abstract class JIntent {
  DateTime get timestamp; // Required property added
}
```

**Version:** 2.x → 3.0.0 (MAJOR)  
**Migration:** All JIntent subclasses must implement `timestamp`

---

## 7. Alternatives Considered

### Alternative 1: CalVer (Calendar Versioning)

**Format:** YYYY.MM.PATCH (e.g., 2025.10.1)

**Pros:**
- Clear release date
- No subjective "what's breaking"

**Cons:**
- No semantic meaning
- Hard to assess compatibility
- Uncommon in Dart/Flutter

**Decision:** Rejected - SemVer is ecosystem standard

### Alternative 2: Loose Versioning

**Approach:** Increment as maintainers see fit

**Pros:**
- Maximum flexibility
- Faster iteration

**Cons:**
- Unpredictable for users
- Breaks trust
- Ecosystem fragmentation

**Decision:** Rejected - Professionalism and user trust paramount

### Alternative 3: API Versioning (v1/, v2/ directories)

**Approach:** Maintain multiple API versions simultaneously

**Pros:**
- No breaking changes ever
- Users migrate at own pace

**Cons:**
- Massive maintenance burden
- Code duplication
- Not standard in Dart

**Decision:** Rejected - Impractical for library of this size

---

## 8. Risks

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Unintentional breaking changes | High | Medium | Automated API surface testing |
| Users ignore deprecation warnings | Medium | High | Clear communication, blog posts |
| Slow adoption of new major versions | Medium | Medium | Compelling features, easy migration |
| Policy too restrictive | Medium | Low | Experimental APIs for flexibility |

---

## 9. Open Questions

### Q1: Pre-1.0 Version Strategy?

**Context:** Project is at v2.1.0, never had 0.x phase

**Status:** Not applicable - already past 1.0

### Q2: Support Multiple Major Versions?

**Question:** Should we maintain v2.x and v3.x simultaneously?

**Answer:** No - resources too limited. Recommend v2.x → v3.0 upgrade path only.

### Q3: API Freeze Period?

**Question:** Should we freeze API before MAJOR release?

**Answer:** Yes - no new features 1 month before major version, only bug fixes.

---

## 10. References

### Internal Documents
- [ADR-000: Context and High-Level Decisions](./ADR-000-context-and-high-level-decisions.md)
- [Executive Summary](../EXECUTIVE_SUMMARY.md) - Section 5.8 Versioning
- [Repository Analysis](../REPOSITORY_ANALYSIS.md) - Section 11 Governance

### External Resources
- [Semantic Versioning 2.0.0](https://semver.org/)
- [Effective Dart: API Design](https://dart.dev/guides/language/effective-dart/design)
- [Pub Versioning Philosophy](https://dart.dev/tools/pub/versioning)
- [Flutter Breaking Changes Policy](https://github.com/flutter/flutter/wiki/Tree-hygiene#handling-breaking-changes)

### Related ADRs
- ADR-004: Documentation Standards (dartdoc requirements)
- ADR-002: Testing Strategy (API surface testing)

---

## 11. Approval & Sign-Off

### Reviewers

| Role | Name | Status | Date |
|------|------|--------|------|
| Project Lead | TodoFlutter.com | Pending | - |
| Technical Lead | TBD | Pending | - |
| Community | Open | Pending | - |

### Approval Criteria

- [ ] SemVer policy clearly stated
- [ ] Public API surface defined
- [ ] Deprecation process documented
- [ ] Examples provided
- [ ] Migration strategy outlined
- [ ] Risks assessed

### Next Steps After Approval

1. Mark ADR-001 as **Accepted**
2. Create VERSIONING.md guide
3. Update CHANGELOG template
4. Add version impact to PR template
5. Communicate policy to community

---

**Document Status:** Proposed  
**Version:** 1.0  
**Last Updated:** 2025-10-15  
**Next Review:** After stakeholder approval

---

*This ADR establishes API design and versioning governance for JIntent. It builds upon the foundation set in ADR-000.*
