# ADR-004: Documentation Standards

**Status:** Proposed  
**Date:** 2025-10-15  
**Deciders:** Project Maintainers, Community  
**Context:** Phase 1 Foundation - Documentation & Developer Experience  
**Related:** [ADR-000](./ADR-000-context-and-high-level-decisions.md)

---

## 1. Status

**Current Status:** Proposed  
**Approval Status:** Pending Stakeholder Review

This ADR defines documentation standards, tooling, and processes for JIntent to ensure comprehensive, maintainable, and user-friendly documentation.

---

## 2. Context

### 2.1 Background

**Current Documentation (v2.1.0):**

**Existing:**
- ✅ Comprehensive README.md (286 lines)
- ✅ CHANGELOG.md (version history)
- ✅ CODE_OF_CONDUCT.md
- ✅ LICENSE (MIT)
- ✅ Effects guide (doc/effects.md)
- ✅ Contributing guidelines (in README)
- ✅ Inline comments in code

**Missing:**
- ❌ Generated API documentation (dartdoc)
- ❌ Migration guides (v1 → v2)
- ❌ Standalone CONTRIBUTING.md
- ❌ Architecture diagrams
- ❌ Tutorial/getting started
- ❌ Best practices guide
- ❌ FAQ

**Quality Issues:**
- Some public APIs lack dartdoc comments
- No consistency standard for comment style
- Documentation scattered across README and doc/
- No versioned documentation

### 2.2 Problem Statement

**Current Challenges:**
- Hard to find specific API details
- No browsable API reference
- Inconsistent comment style
- Missing migration guidance
- No visual architecture aids

**Business Impact:**
- Slower user onboarding
- Increased support questions
- Lower adoption rate
- Contributor friction

---

## 3. Decision

### 3.1 Documentation Hierarchy

**Decision:** Organize documentation in clear hierarchy

```
JIntent/
├── README.md                    # Overview, quick start, high-level
├── LICENSE
├── CODE_OF_CONDUCT.md
├── CHANGELOG.md                 # Version history
├── CONTRIBUTING.md              # How to contribute
├── VERSIONING.md               # Version policy (new)
├── MIGRATION.md                # Version migration guides (new)
│
├── doc/                        # User documentation
│   ├── getting-started.md      # Tutorial for beginners (new)
│   ├── core-concepts.md        # Deep dive into architecture (new)
│   ├── effects.md              # Side effects guide (existing)
│   ├── testing.md              # Testing guide (new)
│   ├── best-practices.md       # Patterns and anti-patterns (new)
│   ├── FAQ.md                  # Frequently asked questions (new)
│   └── examples/               # Code examples (new)
│       ├── counter.md
│       ├── login-flow.md
│       └── pagination.md
│
├── docs/                       # Project governance (Phase 0)
│   ├── adr/                    # Architecture Decision Records
│   ├── EXECUTIVE_SUMMARY.md
│   └── REPOSITORY_ANALYSIS.md
│
└── api/                        # Generated dartdoc (new)
    └── index.html              # Browsable API documentation
```

**Principles:**
- README = Landing page (overview, quick start)
- doc/ = User guides (how-to, tutorials)
- docs/ = Project governance (ADRs, analysis)
- api/ = Generated API reference (dartdoc)

### 3.2 Dartdoc Standards

**Decision:** Require dartdoc comments for all public APIs

**Requirements:**

**1. Public Classes**
```dart
/// Manages state and intent handling for the application.
///
/// [JController] is the central component of JIntent architecture.
/// It receives [JIntent] instances, processes them, and updates [JState].
///
/// ## Usage
///
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
/// - [JEffect] for side effects
class JController<TState extends JState, TIntent extends JIntent> { ... }
```

**2. Public Methods**
```dart
/// Emits a side effect and waits for its completion.
///
/// This method is useful when you need to wait for user input
/// (e.g., dialog confirmation) before continuing intent processing.
///
/// Returns the result of type [T] when the effect completes.
/// Throws [TimeoutException] if [timeout] expires before completion.
///
/// Example:
/// ```dart
/// final confirmed = await controller.emitAndWaitSideEffect(
///   ConfirmDialogEffect(message: 'Delete item?'),
///   timeout: Duration(seconds: 30),
/// );
/// if (confirmed) {
///   // Proceed with deletion
/// }
/// ```
///
/// See also:
/// - [emitSideEffect] for fire-and-forget effects
/// - [JEffect.complete] for completing effects
Future<T> emitAndWaitSideEffect<T>(
  JEffect<T> effect, {
  Duration timeout = const Duration(seconds: 30),
}) async { ... }
```

**3. Public Properties**
```dart
/// The current state of the controller.
///
/// This property is always non-null and reflects the latest state
/// after all intent processing. Listeners are notified when this changes.
TState get state => _state;
```

**4. Required Sections**
- Summary (first line, < 80 chars)
- Detailed description (optional)
- Parameters (if method/constructor)
- Returns (if applicable)
- Throws (if exceptions possible)
- Example (for complex APIs)
- See also (related APIs)

**Dartdoc Style:**
- Use triple-slash `///` (not `/** */`)
- First line is summary (imperative mood: "Emits", "Returns", "Creates")
- Link to other APIs with `[ClassName]` or `[methodName]`
- Use code blocks with triple backticks
- Markdown supported

### 3.3 Documentation Generation

**Decision:** Generate and publish dartdoc automatically

**Tool:** dartdoc (Dart's official API documentation generator)

**Generation:**
```bash
# Generate locally
dart doc .

# Output: doc/api/index.html
```

**Publishing:**
- Automatically publish to GitHub Pages
- Available at: https://gensoftmx.github.io/JIntent/api/
- Regenerate on every release
- Version selector (future)

**CI Integration:**
```yaml
# .github/workflows/docs.yml
name: Generate Docs
on:
  push:
    branches: [main]
    tags: ['v*']

jobs:
  docs:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: dart doc .
      - name: Deploy to GitHub Pages
        uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./doc/api
```

### 3.4 README Standards

**Decision:** Maintain concise, scannable README

**Structure:**
```markdown
# JIntent

[Badges: Pub, License, Build, Coverage]

> One-line tagline

## Table of Contents
- Overview
- Why JIntent?
- Quick Start
- Core Concepts
- Architecture
- Examples
- Documentation
- Contributing
- License

## Overview
[2-3 paragraphs max]

## Why JIntent?
[Problem/Solution, comparison table]

## Quick Start
[Installation + minimal code example (< 20 lines)]

## Core Concepts
[Brief explanation with links to doc/]

## Architecture
[Diagram + explanation]

## Examples
[Links to doc/examples/]

## Documentation
- [Getting Started](doc/getting-started.md)
- [API Reference](https://gensoftmx.github.io/JIntent/api/)
- [Best Practices](doc/best-practices.md)
- [FAQ](doc/FAQ.md)

## Contributing
[Link to CONTRIBUTING.md]

## License
[MIT © 2025 TodoFlutter.com]
```

**Guidelines:**
- Keep under 500 lines
- Scannable (headers, bullets, tables)
- Code examples < 30 lines
- Link to detailed docs, don't duplicate
- Update on major version changes

### 3.5 User Guides

**Decision:** Create comprehensive user documentation

**Required Guides:**

**1. Getting Started (doc/getting-started.md)**
- Installation
- First controller
- First intent
- First side effect
- Next steps

**2. Core Concepts (doc/core-concepts.md)**
- Deep dive into MVI pattern
- JState, JIntent, JController
- Lifecycle
- Best practices

**3. Effects Guide (doc/effects.md)** ✅ Exists
- Enhance existing guide
- Add more examples
- Add troubleshooting

**4. Testing Guide (doc/testing.md)**
- How to test controllers
- How to test intents
- How to test effects
- Mocking strategies

**5. Best Practices (doc/best-practices.md)**
- When to use JIntent
- State design patterns
- Intent granularity
- Performance tips
- Anti-patterns

**6. FAQ (doc/FAQ.md)**
- Common questions
- Troubleshooting
- Comparison with other libraries
- Migration assistance

### 3.6 Code Examples

**Decision:** Provide runnable code examples

**Format:**
- Complete, runnable code
- Focused on single concept
- Commented for clarity
- Include expected output

**Location:**
```
doc/examples/
├── counter.md              # Basic counter (existing in example/)
├── login-flow.md           # Authentication flow
├── pagination.md           # List pagination
├── form-validation.md      # Form handling
└── offline-sync.md         # Offline capability
```

**Template:**
```markdown
# Example: Login Flow

## Overview
Demonstrates authentication with loading states and error handling.

## Code

```dart
// State
class LoginState extends JState {
  final bool isLoading;
  final User? user;
  final String? error;
  
  LoginState({this.isLoading = false, this.user, this.error});
  
  @override
  List<Object?> get props => [isLoading, user, error];
  
  LoginState copyWith({...}) { ... }
}

// Intents
class LoginIntent extends JIntent {
  final String email;
  final String password;
  LoginIntent(this.email, this.password);
}

// Controller
class LoginController extends JController<LoginState, JIntent> {
  LoginController(this._authService) : super(LoginState());
  
  @override
  void handleIntent(JIntent intent) async {
    if (intent is LoginIntent) {
      setState(state.copyWith(isLoading: true, error: null));
      
      final result = await _authService.login(intent.email, intent.password);
      
      if (result.isRight) {
        setState(state.copyWith(
          isLoading: false,
          user: result.right,
        ));
        emitSideEffect(NavigateToHomeEffect());
      } else {
        setState(state.copyWith(
          isLoading: false,
          error: result.left.message,
        ));
      }
    }
  }
}
```

## Explanation
[Walk through the code]

## Running
[How to run this example]
```

### 3.7 Migration Guides

**Decision:** Provide version migration documentation

**File:** MIGRATION.md

**Structure:**
```markdown
# Migration Guide

## v2.x to v3.x (Future)
[When v3.0 happens]

## v1.x to v2.x

### Breaking Changes
1. Removed `get_it` dependency
2. Renamed `triggerEffect` to `emitSideEffect`
3. ...

### Step-by-Step Migration

#### Step 1: Update Dependencies
```yaml
dependencies:
  jintent: ^2.1.0
```

#### Step 2: Remove get_it
[Before/after code]

#### Step 3: Update Effect Calls
[Before/after code]

### Automated Migration
[If available]

### Common Issues
[Troubleshooting]
```

### 3.8 Inline Code Comments

**Decision:** Use comments judiciously

**Guidelines:**

**DO Comment:**
- Complex algorithms
- Non-obvious design decisions
- Temporary workarounds (with TODO)
- Public APIs (dartdoc)

**DON'T Comment:**
- Obvious code (`i++; // increment i`)
- Redundant information
- Dead code (delete instead)
- Version history (use git)

**Example:**
```dart
// Good: Explains non-obvious behavior
/// Sequential dispatcher ensures intents are processed one-at-a-time
/// to prevent race conditions in state updates. This is critical for
/// maintaining predictable state transitions.
class SequentialIntentDispatcher { ... }

// Bad: Redundant
/// Increments the counter
void increment() {
  counter++; // Increment counter by 1
}

// Good: TODO with context
// TODO(john): Replace with Either<E,T> when error handling is standardized
throw Exception('Failed to load');
```

### 3.9 Documentation Quality Checks

**Decision:** Automate documentation validation

**Checks:**

**1. Dartdoc Coverage**
```bash
# Generate report
dart doc --validate-links

# Fail if coverage < 100% (public APIs)
```

**2. Link Validation**
- Check all markdown links work
- Check dartdoc `[ClassName]` references valid
- Check external links (quarterly)

**3. Code Example Compilation**
- Extract code blocks from markdown
- Compile to verify syntax
- Run (if executable)

**CI Integration:**
```yaml
- name: Validate Docs
  run: |
    dart doc --validate-links
    dart run doc_checker  # Custom tool
```

---

## 4. Consequences

### 4.1 Positive Consequences

✅ **Better Developer Experience**
- Easy to find API details
- Clear usage examples
- Reduced support burden

✅ **Higher Adoption**
- Professional appearance
- Lowers entry barrier
- Builds trust

✅ **Maintainability**
- Self-documenting code
- Easier onboarding for contributors
- Clear migration paths

✅ **SEO & Discovery**
- Better pub.dev ranking
- Google-indexed API docs
- Higher visibility

### 4.2 Negative Consequences

⚠️ **Documentation Debt**
- Must keep docs in sync with code
- Outdated docs worse than none
- Review burden

⚠️ **Overhead**
- Time to write docs
- CI time for generation
- Storage for generated docs

⚠️ **Initial Effort**
- Backfill missing docs
- Set up infrastructure
- Write guides

### 4.3 Mitigation Strategies

**For Documentation Debt:**
- PR checklist includes doc updates
- CI checks for dartdoc coverage
- Quarterly documentation review

**For Overhead:**
- Templates speed up writing
- Automated generation
- Community contributions

**For Initial Effort:**
- Prioritize high-value docs first
- Incremental improvement
- Reuse existing content

---

## 5. Implementation Plan

### Phase 1: Foundation (Week 1-2)
- [x] Create ADR-004
- [ ] Backfill missing dartdoc comments
- [ ] Set up dartdoc generation
- [ ] Create CONTRIBUTING.md
- [ ] Create MIGRATION.md (v1→v2)

### Phase 2: User Guides (Week 3-4)
- [ ] Write doc/getting-started.md
- [ ] Write doc/core-concepts.md
- [ ] Enhance doc/effects.md
- [ ] Write doc/testing.md
- [ ] Write doc/FAQ.md

### Phase 3: Automation (Week 5+)
- [ ] Configure GitHub Pages deployment
- [ ] Add dartdoc coverage check to CI
- [ ] Create code example tests
- [ ] Add link validation

---

## 6. Examples

### Example 1: Well-Documented Class

```dart
/// Manages application state and handles intent processing.
///
/// [JController] is the core component of the JIntent architecture,
/// responsible for:
/// - Receiving and processing [JIntent] instances
/// - Updating [JState] immutably
/// - Emitting [JEffect] side effects
/// - Notifying listeners of state changes
///
/// ## Lifecycle
///
/// 1. Create controller with initial state
/// 2. Listen to state changes via [addListener]
/// 3. Dispatch intents via [intent]
/// 4. Handle effects via [sideEffects] stream
/// 5. Dispose when done via [dispose]
///
/// ## Example
///
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
///
/// void main() {
///   final controller = CounterController();
///   controller.addListener(() {
///     print('Count: ${controller.state.count}');
///   });
///   controller.intent(IncrementIntent());
///   controller.dispose();
/// }
/// ```
///
/// ## Thread Safety
///
/// Controllers process intents sequentially (FIFO) to prevent race
/// conditions. See [SequentialIntentDispatcher] for details.
///
/// See also:
/// - [JState] for state management
/// - [JIntent] for intent definitions
/// - [JEffect] for side effects
/// - [JSideEffectHandler] for effect handling
abstract class JController<TState extends JState, TIntent extends JIntent>
    extends StateNotifier<TState> {
  
  /// Creates a controller with the given initial [state].
  ///
  /// Example:
  /// ```dart
  /// CounterController() : super(CounterState(count: 0));
  /// ```
  JController(super.initialState);
  
  // ... rest of class
}
```

### Example 2: Getting Started Guide

```markdown
# Getting Started with JIntent

## Installation

Add JIntent to your `pubspec.yaml`:

```yaml
dependencies:
  jintent: ^2.1.0
```

Run:

```bash
flutter pub get
```

## Your First Controller

Let's build a simple counter app.

### 1. Define State

```dart
import 'package:jintent/jintent.dart';

class CounterState extends JState {
  final int count;
  
  CounterState({required this.count});
  
  @override
  List<Object?> get props => [count];
  
  CounterState copyWith({int? count}) {
    return CounterState(count: count ?? this.count);
  }
}
```

### 2. Define Intents

```dart
class IncrementIntent extends JIntent {}
class DecrementIntent extends JIntent {}
```

### 3. Create Controller

```dart
class CounterController extends JController<CounterState, JIntent> {
  CounterController() : super(CounterState(count: 0));
  
  @override
  void handleIntent(JIntent intent) {
    if (intent is IncrementIntent) {
      setState(state.copyWith(count: state.count + 1));
    } else if (intent is DecrementIntent) {
      setState(state.copyWith(count: state.count - 1));
    }
  }
}
```

### 4. Use in UI

```dart
class CounterPage extends StatefulWidget {
  @override
  State<CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<CounterPage> {
  final controller = CounterController();
  
  @override
  void initState() {
    super.initState();
    controller.addListener(() => setState(() {}));
  }
  
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('JIntent Counter')),
      body: Center(
        child: Text(
          '${controller.state.count}',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () => controller.intent(DecrementIntent()),
            child: Icon(Icons.remove),
          ),
          SizedBox(width: 16),
          FloatingActionButton(
            onPressed: () => controller.intent(IncrementIntent()),
            child: Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
```

## Next Steps

- Learn about [Side Effects](effects.md)
- Read [Core Concepts](core-concepts.md)
- Explore [Examples](examples/)
- See [Best Practices](best-practices.md)
```

---

## 7. Alternatives Considered

### Alternative 1: No API Documentation

**Approach:** Rely on README and code comments only

**Pros:**
- Less tooling
- Faster iteration
- Lower maintenance

**Cons:**
- Hard to browse APIs
- Unprofessional
- Reduced discoverability

**Decision:** Rejected - API docs are industry standard

### Alternative 2: External Documentation Site

**Approach:** Use Docusaurus, GitBook, or similar

**Pros:**
- Rich features (search, versioning)
- Beautiful design
- Multi-language support

**Cons:**
- Additional maintenance
- Separate deployment
- Not integrated with pub.dev

**Decision:** Rejected - Dartdoc sufficient for library

### Alternative 3: Video Tutorials

**Approach:** YouTube series instead of written docs

**Pros:**
- Engaging
- Visual learning
- Higher reach

**Cons:**
- Hard to maintain
- Not searchable
- Time-consuming to produce
- Accessibility issues

**Decision:** Deferred - Written docs first, videos later

---

## 8. Risks

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Documentation becomes outdated | High | Medium | CI checks, PR reviews |
| Too much documentation (overwhelming) | Medium | Low | Clear navigation, ToC |
| Examples don't compile | Medium | Medium | Automated testing |
| Dartdoc generation fails | Low | Low | CI validation |

---

## 9. Open Questions

### Q1: Multi-Version Documentation?

**Question:** Should we host docs for multiple versions?

**Answer:** Phase 2 - Start with latest only, add version selector later.

### Q2: Community Contributions?

**Question:** Allow community to edit docs?

**Answer:** Yes - via PRs, with maintainer review.

### Q3: Non-English Docs?

**Question:** Support Spanish, Chinese, etc.?

**Answer:** Future - Community-driven translations welcome.

---

## 10. References

### Internal Documents
- [ADR-000: Context and High-Level Decisions](./ADR-000-context-and-high-level-decisions.md)
- [ADR-001: API Design](./ADR-001-api-design-and-versioning.md) - Documentation requirements
- [Repository Analysis](../REPOSITORY_ANALYSIS.md)

### External Resources
- [Dartdoc Documentation](https://dart.dev/tools/dartdoc)
- [Effective Dart: Documentation](https://dart.dev/guides/language/effective-dart/documentation)
- [Pub.dev Scoring](https://pub.dev/help/scoring)
- [Write the Docs](https://www.writethedocs.org/)

### Related ADRs
- ADR-001: API Design (public API surface)
- ADR-003: CI/CD Architecture (doc generation)

---

## 11. Approval & Sign-Off

### Reviewers

| Role | Name | Status | Date |
|------|------|--------|------|
| Project Lead | TodoFlutter.com | Pending | - |
| Technical Lead | TBD | Pending | - |
| Community | Open | Pending | - |

### Approval Criteria

- [ ] Documentation hierarchy defined
- [ ] Dartdoc standards specified
- [ ] User guides outlined
- [ ] Generation process documented
- [ ] Quality checks defined
- [ ] Implementation plan provided

### Next Steps After Approval

1. Mark ADR-004 as **Accepted**
2. Backfill dartdoc comments
3. Generate initial API documentation
4. Create CONTRIBUTING.md
5. Write getting-started guide
6. Set up GitHub Pages deployment

---

**Document Status:** Proposed  
**Version:** 1.0  
**Last Updated:** 2025-10-15  
**Next Review:** After stakeholder approval

---

*This ADR establishes documentation standards for JIntent. It builds upon the foundation set in ADR-000 and complements ADR-001 (API Design).*
