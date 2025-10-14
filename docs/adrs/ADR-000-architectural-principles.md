# ADR-000: Architectural Principles and High-Level Decisions

**Status:** Accepted  
**Date:** 2025-10-14  
**Context:** Discovery Phase (Gate A1)  
**Supersedes:** None  
**Related:** All future ADRs will reference this document

---

## Context

JIntent is a Flutter state management library providing a clear, testable architecture based on the MVI (Model-View-Intent) pattern. As the library evolves, we need documented principles to guide decision-making, ensure consistency, and maintain the library's core value propositions.

This ADR establishes the foundational architectural principles that:
1. Define what JIntent is (and isn't)
2. Guide all future design decisions
3. Ensure backward compatibility and stability
4. Maintain developer experience (DX) quality

---

## Decision

We adopt the following **immutable architectural principles** for JIntent:

### 1. Unidirectional Data Flow (Core Principle)

**Principle:** All state changes must flow through the explicit Intent → Controller → State cycle.

**Rationale:**
- Predictability: State changes are traceable to specific intents
- Testability: Each intent is an isolated, testable unit
- Debugging: Clear causal chain from user action to state change

**Implications:**
- ❌ Direct state mutation is prohibited
- ✅ State updates always use `controller.update((state) => newState)`
- ✅ UI triggers intents, never modifies state directly
- ✅ Side effects (navigation, dialogs) use dedicated `JEffect` stream

**Example:**
```dart
// ❌ WRONG: Direct UI → State
setState(() { counter++; });

// ✅ RIGHT: UI → Intent → Controller → State
controller.intent(IncrementIntent());

class IncrementIntent extends JIntent<CounterState> {
  @override
  Future<void> onInvoke() async {
    controller.update((state) => state.copyWith(
      counter: state.counter + 1
    ));
  }
}
```

---

### 2. Immutable State (Core Principle)

**Principle:** All state objects must be immutable. State updates create new instances.

**Rationale:**
- Change detection: Easy comparison via `==` (Equatable)
- Time-travel debugging: Can snapshot and restore states
- Predictability: No hidden mutations
- Performance: Can optimize rebuilds (reference equality)

**Implications:**
- ✅ `JState` extends `Equatable`
- ✅ All state fields are `final`
- ✅ State provides `copyWith()` for updates
- ❌ No setters or mutable collections without defensive copying

**Example:**
```dart
@immutable
class UserState extends JState {
  final String name;
  final int age;
  
  const UserState({required this.name, required this.age});
  
  @override
  UserState copyWith({String? name, int? age}) {
    return UserState(
      name: name ?? this.name,
      age: age ?? this.age,
    );
  }
  
  @override
  List<Object?> get props => [name, age];
}
```

---

### 3. Separation of Concerns (Core Principle)

**Principle:** Business logic, state management, and UI rendering are strictly separated.

**Rationale:**
- Maintainability: Changes in one layer don't affect others
- Testability: Can test logic without UI, UI without real data
- Reusability: Logic can be shared across platforms

**Implications:**
- **JIntent**: Contains business logic (use cases, API calls, validation)
- **JController**: Coordinates intents and manages state lifecycle
- **JState**: Represents UI data (no logic)
- **JEffect**: Represents one-time UI events (no state pollution)
- **UI (Widgets)**: Renders state, dispatches intents (no logic)

**Anti-patterns to avoid:**
```dart
// ❌ Logic in UI
if (user.age >= 18) {
  Navigator.push(...);
}

// ✅ Logic in Intent
class NavigateIfAdultIntent extends JIntent<UserState> {
  @override
  Future<void> onInvoke() async {
    if (state.age >= 18) {
      controller.emitSideEffect(NavigateToAdultContentEffect());
    }
  }
}
```

---

### 4. Explicitness Over Magic (Design Principle)

**Principle:** Favor explicit, traceable patterns over implicit conventions or "magic" behaviors.

**Rationale:**
- Discoverability: Developers can follow the code
- Onboarding: Easier to learn (no hidden rules)
- Debugging: Clear execution path

**Implications:**
- ✅ Intents are explicit classes (not strings or enums)
- ✅ State updates are explicit method calls (`update()`)
- ✅ Side effects are explicit events (`JEffect`)
- ❌ No global singletons for state (except optional `JObserver` for debugging)
- ❌ No code generation required (unlike some state libraries)

**Example:**
```dart
// ❌ Implicit (string-based)
dispatch('INCREMENT');

// ✅ Explicit (typed intent)
controller.intent(IncrementIntent());
```

---

### 5. Minimal Boilerplate (Design Principle)

**Principle:** Reduce repetitive code while maintaining clarity. Don't sacrifice explicitness for brevity.

**Rationale:**
- Developer Experience: Fast iteration
- Adoption: Lower barrier to entry
- Balance: Clarity is more important than brevity

**Implications:**
- ✅ Intents are simple classes (no complex interfaces)
- ✅ State uses standard Dart patterns (`copyWith`, `Equatable`)
- ✅ No forced use of code generation
- ⚠️ Acceptable boilerplate: `copyWith()`, `props` (standard Dart)

**Comparison:**
| Pattern       | Boilerplate Level | JIntent Position |
|---------------|-------------------|------------------|
| Redux         | High (actions, reducers, middleware) | ❌ Too much |
| Bloc          | Medium (events, states, mappers) | ⚠️ Acceptable |
| JIntent       | Low (intents, state.copyWith) | ✅ Preferred |
| setState      | Minimal (no structure) | ❌ Too loose |

---

### 6. Testability by Default (Quality Principle)

**Principle:** Every component must be unit-testable without mocks or complex setup.

**Rationale:**
- Quality: Bugs caught early
- Confidence: Refactoring is safe
- Documentation: Tests serve as examples

**Implications:**
- ✅ Intents are pure functions of state → new state
- ✅ Controllers have injectable dependencies (constructors)
- ✅ No global mutable state (except debug-only `JObserver`)
- ✅ Effects can be completed synchronously in tests

**Testing Pattern:**
```dart
test('IncrementIntent updates counter', () async {
  final controller = CounterController(CounterState(counter: 0));
  await controller.intent(IncrementIntent());
  expect(controller.state.counter, 1);
});
```

---

### 7. Predictable Concurrency (Quality Principle)

**Principle:** Intent execution order must be predictable and documented.

**Rationale:**
- Correctness: Avoid race conditions
- Debugging: Reproduce issues consistently
- User Experience: Actions happen in expected order

**Implications:**
- ✅ Default dispatcher: `JSequentialIntentDispatcher` (FIFO)
- ✅ Errors in one intent don't block subsequent intents
- ⚠️ Developers can opt into parallel execution (custom dispatcher)
- ✅ Dispatcher strategy is explicit (constructor parameter)

**Guarantees:**
```dart
// Sequential (default)
controller.intent(Intent1());  // Completes before Intent2 starts
controller.intent(Intent2());

// Parallel (opt-in)
final parallelController = MyController(
  initialState,
  dispatcher: JDefaultIntentDispatcher(), // No queue
);
```

---

### 8. Observable by Default (Quality Principle)

**Principle:** All lifecycle events (intents, state changes, effects) must be observable for debugging.

**Rationale:**
- Debugging: Understand what happened and when
- Tooling: Enable DevTools, time-travel debugging
- Production monitoring: Track errors, performance

**Implications:**
- ✅ `JObserver` provides global hooks (opt-in)
- ✅ Dispatchers log events (in debug mode)
- ✅ Effects include metadata (ID, timestamp)
- ✅ No performance overhead when disabled

**Usage:**
```dart
void main() {
  if (kDebugMode) {
    enableLoggingObserver();
  }
  runApp(MyApp());
}
```

---

### 9. Platform Agnostic (Quality Principle)

**Principle:** Core library must work on all Flutter platforms without platform-specific code.

**Rationale:**
- Portability: Same code runs everywhere
- Maintenance: No platform-specific bugs
- Adoption: No fragmentation

**Implications:**
- ✅ Core (`jcontroller`, `jintent`, `jstate`) has no platform imports
- ✅ Platform-specific features (navigation, storage) use abstractions
- ⚠️ Platform-specific utilities are optional (separate exports)

**Current Status:**
- ✅ Core: Platform-agnostic
- ⚠️ Navigation: Abstractions provided (`JNavigator`)
- ⚠️ Utils: Includes platform checks (acceptable, optional)

---

### 10. Backward Compatibility (Evolution Principle)

**Principle:** Breaking changes require major version bump and migration guide. Deprecations must have grace period.

**Rationale:**
- Trust: Users can upgrade safely
- Ecosystem: Apps don't break unexpectedly
- Adoption: Lower risk for production use

**Implications:**
- ✅ Follow Semantic Versioning (SEMVER) strictly
- ✅ Deprecate before removal (minimum 1 minor version)
- ✅ Provide migration guide for breaking changes
- ✅ Deprecation annotations include replacement guidance

**Example:**
```dart
@Deprecated(
  'setState is deprecated. Use update((state) => newState) instead '
  'for safer, reactive state updates. '
  'Will be removed in 3.0.0.'
)
void setState(T newState) { ... }
```

---

## Consequences

### Positive

1. **Consistency:** All future features follow established patterns
2. **Quality:** Principles enforce testability and maintainability
3. **Trust:** Users know what to expect (no surprises)
4. **Onboarding:** New contributors understand the "why" behind decisions
5. **Decision Speed:** Use principles to evaluate proposals quickly

### Negative

1. **Rigidity:** Principles may constrain innovative solutions
2. **Learning Curve:** Developers must understand principles to contribute
3. **Boilerplate:** Some principles (immutability, explicitness) require code overhead

### Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Principles conflict with future needs | Review and update ADRs when necessary (requires ADR) |
| Too restrictive for edge cases | Allow opt-out with explicit justification (ADR required) |
| Principles not followed in practice | Enforce via lints, code review, CI checks |

---

## Alternatives Considered

### Alternative 1: No Formal Principles
**Rejected because:**
- Leads to inconsistent APIs
- Difficult to onboard contributors
- Hard to justify design decisions

### Alternative 2: Adopt Another Library's Principles (e.g., Bloc)
**Rejected because:**
- JIntent has different goals (lower boilerplate)
- Not all principles align (e.g., Bloc uses events + states, JIntent uses intents + state)

### Alternative 3: Generate Principles from Code
**Rejected because:**
- Principles should guide code, not reverse-engineer from code
- Need explicit decisions before implementation

---

## Related Decisions

### Future ADRs Expected:
- ADR-001: Error Handling Strategy (exception hierarchy)
- ADR-002: Performance Optimization Guidelines
- ADR-003: DevTools Integration Design
- ADR-004: Middleware/Plugin System
- ADR-005: Isolate Safety Strategy

---

## References

- **MVI Pattern:** [Hannes Dorfmann - MVI on Android](http://hannesdorfmann.com/android/mosby3-mvi-1)
- **Unidirectional Data Flow:** [React Flux Architecture](https://facebook.github.io/flux/)
- **Immutability:** [Dart Effective Dart - Design](https://dart.dev/guides/language/effective-dart/design)
- **SEMVER:** [Semantic Versioning 2.0.0](https://semver.org/)

---

## Review History

| Date | Reviewer | Status | Notes |
|------|----------|--------|-------|
| 2025-10-14 | Development Team | Draft | Initial creation for Gate A1 |
| TBD | Maintainer | Pending | Awaiting approval |

---

## Appendix: Decision Framework

Use this checklist to evaluate proposals against principles:

- [ ] Does it maintain unidirectional data flow?
- [ ] Does it preserve state immutability?
- [ ] Does it separate concerns (logic vs UI)?
- [ ] Is it explicit and traceable?
- [ ] Does it minimize boilerplate without sacrificing clarity?
- [ ] Is it testable without complex setup?
- [ ] Is concurrency behavior predictable?
- [ ] Can it be observed/debugged?
- [ ] Does it work on all platforms?
- [ ] Is it backward compatible (or properly deprecated)?

If any answer is "No," the proposal needs justification via ADR.

---

**Document Status:** ✅ Complete and ready for Gate A1 review  
**Next Steps:** Present to maintainers for approval
