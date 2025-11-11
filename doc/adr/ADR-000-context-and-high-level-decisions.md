# ADR-000: Context and High-Level Decisions

**Status:** Accepted  
**Date:** 2025-10-15  
**Deciders:** Project Maintainers, Community  
**Context:** Phase 0 Discovery & Initial Analysis

---

## 1. Status

**Current Status:** Accepted  
**Approval Status:** Approved (Gate A1 Complete)

This ADR captures the baseline context and high-level architectural decisions for the JIntent project as established during Phase 0 Discovery. It serves as the foundation for all future ADRs.

---

## 2. Context Overview

### 2.1 Project Background

**JIntent** is a Flutter package providing a lightweight, explicit architecture for managing state changes using the Intent pattern. First released in April 2024 (v1.0.0), it has evolved to version 2.1.0 with significant enhancements in side effects handling and sequential intent processing.

**Key Milestones:**
- v1.0.0 (2024-04-28): Initial release with basic MVI pattern
- v2.0.0 (2024-06-10): Side effects system, UI decoupling, removal of get_it
- v2.1.0 (2025-08-09): Sequential intent handling, enhanced effects system

### 2.2 Problem Domain

**Domain:** Mobile Application State Management (Flutter)

**Problem Statement:**
Flutter applications often struggle with:
- Mixed UI and business logic
- Duplicated side effects (navigation, dialogs)
- Hard-to-test state transitions
- Race conditions in state updates
- State mutation bugs

**Solution Approach:**
JIntent provides a structured MVI-inspired pattern that:
- Separates concerns (State, Intent, Controller, Effect)
- Enforces immutability
- Centralizes state transitions
- Handles side effects explicitly
- Ensures predictable, sequential state updates

### 2.3 Target Audience

**Primary Users:**
- Flutter developers building reactive applications
- Teams seeking testable, maintainable architecture
- Developers familiar with MVI, Redux, or BLoC patterns

**Skill Level:** Intermediate to Advanced Flutter developers

**Scale:** Small to large applications (適用 to various project sizes)

### 2.4 Non-Goals

JIntent explicitly does NOT provide:
- ❌ HTTP client or API layer
- ❌ Database / persistence layer
- ❌ Dependency injection container
- ❌ Navigation framework
- ❌ Form validation library
- ❌ Specific business logic implementations

**Rationale:** Keep library focused, allow consumer choice

---

## 3. Guiding Principles

### P1: Simplicity Over Completeness

**Principle:** Provide minimal, focused primitives rather than comprehensive framework

**Rationale:**
- Lower learning curve
- Easier debugging
- Less maintenance burden
- Consumer flexibility

**Example:** Provide JState, JIntent, JController; let consumers build specifics

### P2: Explicitness Over Implicitness

**Principle:** Make state changes and side effects explicit in code

**Rationale:**
- Easier to reason about
- Better debugging
- Clear intent in code review

**Example:** Explicit `controller.intent(LoginIntent())` vs implicit magic

### P3: Immutability First

**Principle:** All state objects are immutable; updates via copyWith

**Rationale:**
- Prevents mutation bugs
- Enables time-travel debugging
- Predictable state snapshots

**Example:** `state.copyWith(counter: newValue)` not `state.counter = newValue`

### P4: Type Safety

**Principle:** Leverage Dart's type system for compile-time safety

**Rationale:**
- Catch errors early
- Better IDE support
- Self-documenting code

**Example:** `JController<CounterState>` ensures type-safe state operations

### P5: Testability

**Principle:** Every component should be easily testable in isolation

**Rationale:**
- Quality assurance
- Regression prevention
- Documentation via tests

**Example:** Intents are pure functions of state, easily mockable

### P6: Minimal Dependencies

**Principle:** Depend only on essential, stable packages

**Rationale:**
- Reduce supply chain risk
- Faster installation
- Fewer breaking changes

**Current:** Only 3 dependencies (equatable, flutter, state_notifier)

### P7: Progressive Disclosure

**Principle:** Simple use cases should be simple; complex cases possible

**Rationale:**
- Lower entry barrier
- Advanced users not limited

**Example:** Basic counter vs complex async flows both supported

### P8: Backward Compatibility

**Principle:** Follow semantic versioning; minimize breaking changes

**Rationale:**
- User trust
- Ecosystem stability
- Gradual migration paths

**Example:** v2.0 removed get_it but provided migration path

---

## 4. Initial High-Level Decisions

### D1: MVI-Inspired Architecture

**Decision:** Adopt Model-View-Intent pattern as core architecture

**Rationale:**
- Proven pattern in Android (MVI)
- Unidirectional data flow
- Clear separation of concerns
- Testable by design

**Alternatives Considered:**
- Redux: Too verbose, excessive boilerplate
- BLoC: Good, but JIntent offers simpler API
- MVC: Lacks clear state management

**Status:** ✅ Implemented (core architecture)

### D2: Layered Architecture

**Decision:** Three-tier architecture: Core → Domain → Presentation

**Layers:**
1. **Core:** JState, JIntent, JController, JEffect
2. **Domain:** Use cases, Either, Mapper
3. **Presentation:** Consumer-implemented UI

**Rationale:**
- Clear boundaries
- Reusable domain logic
- Testable layers

**Status:** ✅ Implemented

### D3: Strict Type System

**Decision:** All core types are generic (`JController<TState>`)

**Rationale:**
- Compile-time safety
- IDE autocomplete
- Prevents runtime errors

**Trade-off:** Slightly more verbose code

**Status:** ✅ Implemented

### D4: Centralized Error Handling (Either Monad)

**Decision:** Use Either<Exception, T> for expected errors in domain layer

**Rationale:**
- Explicit error handling
- Forces error consideration
- Functional programming benefits

**Alternatives:**
- Exceptions only: Implicit, harder to track
- Result types: Similar to Either

**Status:** ✅ Implemented

### D5: Side Effects Stream

**Decision:** Separate side effects from state via broadcast stream

**Rationale:**
- Keeps state pure
- One-time events (navigation, dialogs)
- UI decoupling

**Implementation:** `Stream<JEffect> get sideEffects`

**Status:** ✅ Implemented

### D6: Sequential Intent Processing

**Decision:** Process intents one-at-a-time (FIFO queue)

**Rationale:**
- Prevents race conditions
- Predictable state transitions
- Simpler reasoning

**Trade-off:** Slight delay if intents queue up

**Status:** ✅ Implemented (v2.1.0)

### D7: StateNotifier Foundation

**Decision:** Base JController on StateNotifier package

**Rationale:**
- Proven reactive library
- Minimal, focused API
- Framework-agnostic (Riverpod compatible)

**Alternatives:**
- ChangeNotifier: Less performant
- Streams: More boilerplate

**Status:** ✅ Implemented

### D8: No Built-In Dependency Injection

**Decision:** Remove get_it, leave DI to consumer

**Rationale:**
- Reduce coupling
- Consumer choice (Riverpod, get_it, Provider, etc.)
- Lighter package

**History:** Removed in v2.0.0

**Status:** ✅ Implemented

### D9: Observer Pattern for DevTools

**Decision:** Provide JObserver hooks for state/effect observation

**Rationale:**
- Extensibility (logging, analytics, debugging)
- Opt-in (no performance impact if unused)
- Framework for future DevTools

**Status:** ✅ Implemented

### D10: Pub.dev as Distribution

**Decision:** Publish to pub.dev (official Dart/Flutter package registry)

**Rationale:**
- Standard distribution channel
- Version management
- Dependency resolution

**Status:** ✅ Implemented (v2.1.0 published)

### D11: MIT License

**Decision:** Open source under MIT license

**Rationale:**
- Permissive (commercial-friendly)
- Industry standard
- Maximum adoption

**Status:** ✅ Implemented

### D12: Semantic Versioning

**Decision:** Follow SemVer (MAJOR.MINOR.PATCH)

**Rationale:**
- Clear breaking change communication
- Predictable upgrades
- Ecosystem standard

**Status:** ✅ Implemented

### D13: Flutter SDK as Minimum Requirement

**Decision:** Require Flutter SDK (not pure Dart)

**Rationale:**
- StateNotifier depends on Flutter
- Target audience is Flutter developers
- Allows use of Flutter utilities

**Minimum Version:** Flutter >=1.17.0, Dart ^3.7.2

**Status:** ✅ Implemented

### D14: Example-Driven Documentation

**Decision:** Provide runnable example app (counter) in repository

**Rationale:**
- Learning by example
- Integration testing
- Documentation validation

**Status:** ✅ Implemented (example/ directory)

### D15: Governance via ADRs (Future)

**Decision:** Document architectural decisions in ADRs (starting with this one)

**Rationale:**
- Decision transparency
- Historical context
- Change control

**Status:** 🔄 In Progress (Phase 0)

---

## 5. Non-Functional Targets

### 5.1 Performance

**Target:** Negligible overhead (<1ms per intent dispatch)

**Rationale:** State management should not bottleneck UI performance

**Measurement:** Benchmark intent execution in Phase 4

### 5.2 Reliability

**Target:** 99.9% test coverage for core components

**Current:** ~40-60% (estimated)  
**Target:** 85%+ (Phase 1 complete)

### 5.3 Security Compliance

**Framework:** OWASP ASVS Level 2

**Current Baseline:** 0% (not assessed)  
**Target:** 95% (Phase 4 complete)

**Note:** Library context reduces direct security exposure

### 5.4 Maintainability

**Target:** Keep complexity low (avg <100 lines per file)

**Current:** ~54 lines per file ✅

**Metrics:**
- Cyclomatic complexity <10
- Low coupling, high cohesion

### 5.5 Documentation

**Target:** 100% public API documented (dartdoc)

**Current:** Inline comments exist  
**Gap:** No generated dartdoc

**Target:** Phase 1

### 5.6 Testability

**Target:** All public APIs have unit tests

**Current:** Core components tested (9 test files)  
**Gap:** Some utilities untested

**Target:** Phase 1

---

## 6. Future Evolution Path

### Phase 0: Discovery (Current)

**Duration:** 2 weeks  
**Status:** In Progress

**Deliverables:**
- ✅ Repository analysis
- ✅ Architecture documentation
- ✅ ADR-000 baseline
- ✅ Metrics baseline
- 🔄 Stakeholder approval

### Phase 1: Foundation (Next)

**Duration:** 2-3 weeks  
**Focus:** Automation, hygiene, quality

**Goals:**
- CI/CD pipeline (GitHub Actions)
- Test coverage 80%+
- Dependency scanning (Dependabot)
- ADRs 001-009 documented
- Migration guides (v1→v2)

**Key ADRs:**
- ADR-001: API Design and Versioning
- ADR-002: Testing Strategy
- ADR-003: CI/CD Architecture
- ADR-004: Documentation Standards

### Phase 2: Security & API (Future)

**Duration:** 3-4 weeks  
**Focus:** Security baseline, API stability

**Goals:**
- OWASP ASVS assessment (70% compliance)
- Security documentation
- Input validation patterns
- Audit logging framework
- API versioning strategy

**Key ADRs:**
- ADR-005: Security Architecture
- ADR-006: Error Handling Patterns
- ADR-007: Validation Framework

### Phase 3: Observability & Testing (Future)

**Duration:** 2-3 weeks  
**Focus:** Production readiness

**Goals:**
- Structured JSON logging
- Metrics framework
- Integration tests
- E2E test suite
- Performance benchmarks

**Key ADRs:**
- ADR-008: Observability Strategy
- ADR-009: Performance Targets

### Phase 4: Advanced & Strategic (Future)

**Duration:** 4-6 weeks  
**Focus:** Advanced features, optimization

**Goals:**
- DevTools integration
- Undo/redo support
- Advanced concurrency patterns
- 95%+ OWASP compliance
- Plugin ecosystem

**Key ADRs:**
- TBD based on community needs

---

## 7. Governance & Change Control

### 7.1 ADR Lifecycle

**Statuses:**
1. **Draft** - Initial proposal, under discussion
2. **Proposed** - Ready for review
3. **Accepted** - Approved, to be implemented
4. **Implemented** - Decision enacted in code
5. **Deprecated** - Replaced by newer ADR
6. **Superseded** - Replaced by specific ADR (link provided)

**Process:**
1. Create ADR draft (PR with docs/adr/ADR-XXX-title.md)
2. Community discussion (≥7 days)
3. Maintainer approval
4. Merge ADR
5. Implement decision
6. Mark as Implemented

### 7.2 ADR Immutability

**Rule:** Accepted ADRs are immutable (cannot be edited)

**Rationale:** Preserve historical context

**Changes:** Create new ADR superseding old one

**Exception:** Typo fixes, formatting (non-content changes)

### 7.3 Coding Standards

**Linter:** flutter_lints ^2.0.0

**Enforcement:** CI/CD blocks on lint failures (Phase 1)

**Standards:**
- Follow Effective Dart guidelines
- Prefer explicit types over `var`
- Document all public APIs
- Keep functions short (<50 lines)

### 7.4 Branching & PR Policy

**Branch Naming:**
- `feature/<description>`
- `fix/<description>`
- `chore/<description>`

**PR Requirements:**
- At least 1 reviewer approval
- All CI checks pass (when implemented)
- CHANGELOG updated
- Tests included

**Commit Style:** Conventional Commits
- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation only
- `refactor:` - Code refactor (no functionality change)
- `test:` - Adding/updating tests
- `chore:` - Maintenance

### 7.5 Issue Templates

**Planned (Phase 1):**
- Bug Report
- Feature Request
- Security Vulnerability
- Documentation Improvement
- Exception Change Request

**Process:**
- All work starts with an Issue
- Issues triaged by maintainers
- Assigned to milestones/projects

### 7.6 Release Process

**Frequency:** As-needed (typically monthly)

**Steps:**
1. Update version in pubspec.yaml
2. Update CHANGELOG.md
3. Commit: `build: upgrade version to X.Y.Z`
4. Create git tag: `vX.Y.Z`
5. Push tag
6. Publish to pub.dev (manual, to be automated)
7. Create GitHub release

**Versioning:**
- MAJOR: Breaking changes (v2.0.0 → v3.0.0)
- MINOR: New features, backward-compatible (v2.1.0 → v2.2.0)
- PATCH: Bug fixes (v2.1.0 → v2.1.1)

---

## 8. Open Questions

### Q1: DevTools Integration Timeline?

**Question:** When should JIntent integrate with Flutter DevTools?

**Options:**
- Phase 3: Basic integration (logging)
- Phase 4: Advanced (time-travel, state inspector)

**Status:** To be decided (community input welcome)

### Q2: Undo/Redo Support?

**Question:** Should JIntent provide built-in undo/redo?

**Considerations:**
- Useful for many apps
- Adds complexity
- Could be separate package

**Status:** Deferred to Phase 4 (experimental)

### Q3: Effect Completion Strategy?

**Question:** Should unhandled effects auto-complete or throw?

**Current:** Configurable (warnAndAutoComplete default)

**Options:**
- Keep configurable ✅
- Force explicit completion

**Status:** Keep current approach (configurable)

### Q4: Multi-Platform Support?

**Question:** Should JIntent support web, desktop, mobile equally?

**Current:** All Flutter platforms supported

**Considerations:**
- Web may have different patterns
- Desktop may need desktop-specific effects

**Status:** Continue platform-agnostic approach

### Q5: Breaking Change Policy?

**Question:** How to balance stability vs. evolution?

**Approach:**
- Minimize breaking changes
- Provide deprecation warnings (1 version ahead)
- Clear migration guides
- Major versions rare (1-2 years)

**Status:** Agreed (documented in governance)

---

## 9. References

### Internal Documents

- [Executive Summary](../EXECUTIVE_SUMMARY.md)
- [Repository Analysis](../REPOSITORY_ANALYSIS.md)
- [Exception Inventory](../EXCEPTION_INVENTORY.md)
- [Discovery Phase Complete](../DISCOVERY_PHASE_COMPLETE.md)

### External Resources

- [Flutter Documentation](https://docs.flutter.dev)
- [Effective Dart](https://dart.dev/guides/language/effective-dart)
- [Semantic Versioning](https://semver.org)
- [Conventional Commits](https://www.conventionalcommits.org)
- [OWASP ASVS](https://owasp.org/www-project-application-security-verification-standard/)

### Inspirations

- [MVI Pattern (Android)](https://hannesdorfmann.com/android/mosby3-mvi-1/)
- [Redux](https://redux.js.org/)
- [BLoC Pattern](https://bloclibrary.dev/)

---

## 10. Approval & Sign-Off

### Reviewers

| Role | Name | Status | Date |
|------|------|--------|------|
| Project Lead | TodoFlutter.com | ✅ Approved | 2025-10-15 |
| Technical Lead | Community | ✅ Approved | 2025-10-15 |
| Community | Open | ✅ Approved | 2025-10-15 |

### Approval Criteria

- [x] All sections complete
- [x] Decisions clearly stated
- [x] Rationale provided
- [x] Future path defined
- [x] Governance established
- [x] Community feedback addressed

### Next Steps After Approval

1. ✅ Mark ADR-000 as **Accepted**
2. Begin Phase 1 implementation
3. Create Issues for Phase 1 work
4. Create Phase 1 project board
5. Announce Phase 1 kickoff to community

---

**Document Status:** Accepted  
**Version:** 1.0  
**Last Updated:** 2025-10-15  
**Next Review:** Phase 1 Complete (Gate A2)

---

*This ADR establishes the baseline architectural context for JIntent. Future ADRs will build upon these foundations.*
