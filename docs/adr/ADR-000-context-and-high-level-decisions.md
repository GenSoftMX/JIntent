# ADR-000: Context and High-Level Decisions

**Status:** Draft  
**Date:** 2025-10-14  
**Deciders:** JIntent Maintainers (GenSoftMX)  
**Version:** 2.1.0 Baseline

---

## Status

🟡 **DRAFT** - Awaiting stakeholder review and approval

This ADR captures the baseline architectural decisions as of version 2.1.0. It serves as the foundation for all future ADRs.

---

## Context Overview

### Project Purpose
JIntent is a lightweight Flutter package providing an MVI-inspired (Model-View-Intent) architecture for managing state changes through explicit intents and side effects. It aims to bring clarity, testability, and maintainability to Flutter applications with minimal boilerplate.

### Problem Space
Flutter applications often struggle with:
- Mixed UI and business logic leading to tight coupling
- Side effects (navigation, dialogs) polluting state management
- Difficulty testing complex state transitions
- Race conditions from concurrent state updates
- Implicit error handling making bugs hard to track

### Target Audience
- Flutter developers building production applications
- Teams requiring clear architecture boundaries
- Projects needing testable business logic
- Applications with complex state flows and side effects

### System Criticality
**Medium** - This is infrastructure code that apps depend on for state management. Bugs can impact user experience but rarely cause data loss or security issues.

### Data Classification
**Public** - Open source MIT-licensed package. No sensitive data handled by the library itself.

---

## Guiding Principles

### 1. Explicit Over Implicit
All state changes and side effects must be explicit. No hidden control flow, no magic.

### 2. Separation of Concerns
Clear boundaries between UI (presentation), Controller (orchestration), and Use Cases (business logic).

### 3. Type Safety First
Leverage Dart's type system to catch errors at compile time, not runtime.

### 4. Minimal Boilerplate
Simple patterns that don't require extensive code generation or configuration.

### 5. Testability by Design
Every component (State, Intent, Use Case, Effect) is independently testable.

### 6. Functional Error Handling
Prefer Either monad over exceptions for expected failures. Make errors explicit and composable.

### 7. Flexibility Without Fragmentation
Provide sensible defaults while allowing customization without breaking core abstractions.

### 8. Documentation as Code
Code should be self-documenting; comprehensive docs required for complex patterns.

---

## Initial High-Level Decisions

### 1. MVI-Inspired Architecture
**Decision:** Adopt Model-View-Intent pattern with Side Effects extension.

**Rationale:**
- Clear unidirectional data flow: UI → Intent → State → UI
- Explicit intent naming makes app behavior discoverable
- Side effects separated from state prevent pollution
- Pattern scales from simple to complex applications

**Alternatives Considered:**
- BLoC: More boilerplate, less explicit intent naming
- Redux: Too much ceremony for Flutter apps
- Provider alone: No structure for complex flows

### 2. StateNotifier as Foundation
**Decision:** Extend `StateNotifier<T>` from state_notifier package.

**Rationale:**
- Battle-tested reactive state management
- Excellent integration with Riverpod (optional)
- Built-in immutability enforcement
- Minimal overhead, maximum compatibility

**Trade-offs:**
- Adds dependency, but it's stable and well-maintained
- Locks into immutable state pattern (this is desired)

### 3. Either Monad for Error Handling
**Decision:** Use `Either<Exception, Result>` pattern for use case results.

**Rationale:**
- Explicit error handling (compiler enforced)
- No hidden control flow from exceptions
- Composable and testable
- Industry standard in functional programming

**Alternatives Considered:**
- Exceptions only: Hidden control flow, harder to test
- Result<T, E> type: Similar, but Either is more established in Dart

### 4. Side Effect Stream Architecture
**Decision:** Dedicated broadcast stream for one-time UI events (effects).

**Rationale:**
- Navigation, dialogs, toasts don't belong in persistent state
- Stream allows multiple listeners (useful for analytics)
- Completion mechanism enables request-response patterns
- Separates transient events from application state

**Key Features:**
- Optional result via Completer<T>
- Timeout support
- Configurable unhandled strategy
- Effect categorization

### 5. Sequential Intent Processing (Default)
**Decision:** Intents execute one at a time by default (JSequentialIntentDispatcher).

**Rationale:**
- Prevents race conditions in state updates
- Guarantees order of operations
- Simpler reasoning about state transitions
- Apps can opt-into concurrent dispatching if needed

**Trade-offs:**
- May be slower for independent intents
- Blocking long-running intents delay queue
- Solution: Make intents fast, offload work to use cases

### 6. Use Case Pattern for Business Logic
**Decision:** Encapsulate business logic in JUseCase/JSyncUseCase classes.

**Rationale:**
- Single Responsibility Principle (one use case = one business action)
- Independently testable without UI or controller
- Reusable across controllers
- Clear dependency injection points
- Composable validators

**Structure:**
```dart
abstract class JUseCase<INPUT, OUTPUT> {
  Future<Either<Exception, OUTPUT>> run(INPUT input);
}
```

### 7. Immutable State with copyWith
**Decision:** All state must be immutable and implement copyWith pattern.

**Rationale:**
- Predictable state changes (no hidden mutations)
- Easier debugging (state snapshots)
- Better performance (change detection)
- Required by StateNotifier

**Enforcement:**
- State extends JState (which extends Equatable)
- Linter rules for immutability (recommended)

### 8. No Built-in Dependency Injection
**Decision:** Remove get_it dependency; let apps handle DI (as of v2.0.0).

**Rationale:**
- Reduces coupling
- Flexibility for apps to choose their DI solution
- Smaller package footprint
- Apps can use get_it, Riverpod, or manual injection

**Migration:** v1.x used get_it internally; removed in v2.0.0 breaking change.

### 9. Dart/Flutter Ecosystem Alignment
**Decision:** Use standard Dart/Flutter tools and patterns.

**Rationale:**
- Easier onboarding for Flutter developers
- Better IDE support
- Leverage ecosystem tools (flutter test, analyzer)
- No custom build tools required

**Choices:**
- Equatable for value equality
- flutter_test for testing
- Standard pub.dev distribution

### 10. Mapper Pattern for Data Transformation
**Decision:** Provide JMapper/IBiMapper abstractions for transforming data.

**Rationale:**
- Common need in layered architectures
- Type-safe transformations
- Reusable and testable
- Clean separation of concerns

**Usage:** Transform between layers (DTO → Domain, Entity → State)

### 11. Observer Pattern for DevTools
**Decision:** JObserver interface for debugging and tooling.

**Rationale:**
- Extensible logging and debugging
- No performance impact when not used
- Enables custom analytics integration
- Clean separation of concerns

**Features:**
- State change observation
- Intent tracking
- Effect monitoring

### 12. Multi-Platform Support
**Decision:** Support all Flutter platforms (Android, iOS, Web, Desktop).

**Rationale:**
- Pure Dart implementation (no platform-specific code)
- Flutter's promise of cross-platform development
- Maximum package utility

**Constraint:** No platform channels or native dependencies.

### 13. Semantic Versioning
**Decision:** Strict adherence to SemVer (MAJOR.MINOR.PATCH).

**Rationale:**
- Predictable upgrade path
- Clear communication of breaking changes
- Industry standard
- pub.dev convention

**Policy:**
- MAJOR: Breaking API changes
- MINOR: New features, backward compatible
- PATCH: Bug fixes only

### 14. MIT License
**Decision:** Open source under MIT license.

**Rationale:**
- Maximum freedom for users
- Encourages adoption
- Compatible with commercial projects
- Simple and well-understood

### 15. Documentation-First Approach
**Decision:** Maintain comprehensive documentation alongside code.

**Rationale:**
- Lowers barrier to entry
- Reduces support burden
- Documents design decisions
- Facilitates contributions

**Structure:**
- README: Quick start and overview
- doc/: Detailed guides
- docs/: Governance and architecture (Phase 0)
- Inline code docs

---

## Non-Functional Targets

### Performance
- **Intent Processing:** < 10ms for simple state updates (no I/O)
- **Effect Emission:** < 5ms overhead
- **Memory:** < 1KB per controller instance
- **No Memory Leaks:** All effects must complete or timeout

### Reliability
- **Stability:** No crashes in framework code (exceptions caught and surfaced)
- **Compatibility:** Support last 3 Flutter stable releases
- **Backward Compatibility:** Within major version

### Security
- **No Secrets:** No credentials or secrets in package code
- **Input Validation:** Apps responsible for validating use case inputs
- **Dependency Health:** Keep dependencies updated and scanned
- **Target Compliance:** OWASP ASVS L1 90%+ (Phase 2 goal)

### Maintainability
- **Code Coverage:** Target 80%+ (currently ~30%)
- **Linting:** 100% compliance with flutter_lints
- **Documentation:** All public APIs documented
- **ADR Process:** All major decisions recorded

### Scalability
- **Package Size:** < 100KB (minified)
- **Dependencies:** < 5 direct dependencies
- **Large Apps:** Support 100+ controllers without performance degradation

---

## Future Evolution Path

### Phase 1: Foundation (Months 1-2)
- Establish CI/CD pipeline
- Increase test coverage to 70%+
- Add security documentation
- Dependency vulnerability scanning
- ADR process formalization

### Phase 2: Maturity (Months 3-4)
- OWASP ASVS L1 compliance
- Integration test suite
- Performance benchmarks
- Migration guides for breaking changes
- Security audit

### Phase 3: Enhancement (Months 5-6)
- Structured logging examples
- Advanced error recovery patterns
- Memory profiling tools
- Production debugging guides
- Community examples

### Phase 4: Ecosystem (Ongoing)
- Plugin system for extensions
- DevTools integration
- Code generation tools (optional)
- Framework integrations (Riverpod, GetX)
- Community contributions

---

## Governance & Change Control

### ADR Lifecycle
1. **Propose:** Create ADR draft (PR or Issue)
2. **Review:** Tech lead + 2 reviewers
3. **Approve:** Merge into main branch with "Approved" status
4. **Implement:** Reference ADR in implementation PRs
5. **Supersede:** New ADR marks old one as superseded (never delete)

### Decision Authority
- **Architecture:** Tech Lead (with team review)
- **Breaking Changes:** Requires consensus + migration guide
- **Security:** Security Champion veto power
- **Documentation:** Any maintainer can improve

### Issue Templates
**Required for Phase 1:**
- Feature Request (requires ADR for significant features)
- Bug Report
- Security Vulnerability (private reporting)
- Error Code Change Request (Phase 2)

### Code Review Policy
- **Minimum Reviews:** 1 for minor changes, 2 for breaking changes
- **Required Checks:** Tests pass, linter passes, no regressions
- **Security Review:** Required for authentication, cryptography, input validation

### Branching Strategy
- **main:** Stable, always releasable
- **feature/*:** New features
- **fix/*:** Bug fixes
- **chore/*:** Housekeeping (deps, docs)

---

## Open Questions

### Q1: Should we support concurrent intent dispatching?
**Status:** Open  
**Discussion:** Sequential by default is safe, but some apps may need concurrent processing for performance.  
**Proposed Solution:** Already supported via custom JIntentDispatcher; document pattern.

### Q2: Should we provide code generation for boilerplate?
**Status:** Open  
**Discussion:** copyWith() and mapper boilerplate could be generated.  
**Trade-off:** Adds complexity, another tool to learn. Defer until community demand is clear.

### Q3: How should we handle side effect timeouts in production?
**Status:** Open  
**Discussion:** Auto-complete vs. throw vs. custom handler?  
**Current:** Configurable via UnhandledEffectStrategy. Document best practices.

### Q4: Should we provide built-in analytics/telemetry?
**Status:** Open  
**Discussion:** Effect categorization exists but no built-in reporting.  
**Decision:** Provide hooks (JObserver), let apps integrate their tools.

### Q5: What's the migration path for breaking changes?
**Status:** Needs Documentation  
**Action:** Phase 2 - Create migration guide template and guides for v1→v2.

---

## References

### Internal
- [Repository Analysis](../REPOSITORY_ANALYSIS.md)
- [Exception Inventory](../EXCEPTION_INVENTORY.md)
- [Executive Summary](../EXECUTIVE_SUMMARY.md)

### External
- [MVI Pattern](https://cycle.js.org/model-view-intent.html)
- [StateNotifier Package](https://pub.dev/packages/state_notifier)
- [Equatable Package](https://pub.dev/packages/equatable)
- [Flutter Architecture Samples](https://github.com/brianegan/flutter_architecture_samples)
- [OWASP ASVS](https://owasp.org/www-project-application-security-verification-standard/)

### Design Influences
- Redux (unidirectional data flow)
- Elm Architecture (model-update-view)
- Clean Architecture (use case pattern)
- Railway Oriented Programming (Either monad)

---

## Approval

| Role | Name | Status | Date |
|------|------|--------|------|
| Tech Lead | TBD | Pending | - |
| Security Champion | TBD | Pending | - |
| Maintainer | GenSoftMX | Pending | - |

---

**Document Owner:** System Architecture & Governance Analyst  
**Next Review:** After Phase 1 completion or significant architecture change  
**Supersedes:** None (baseline ADR)  
**Superseded By:** None
