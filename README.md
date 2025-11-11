# JIntent

[![Pub Version](https://img.shields.io/pub/v/jintent.svg)](https://pub.dev/packages/jintent)
![License](https://img.shields.io/github/license/GenSoftMX/JIntent)
![Pub Points](https://img.shields.io/badge/pub%20points-160/160-informational)
![Likes](https://img.shields.io/pub/likes/jintent)
![Build](https://img.shields.io/github/actions/workflow/status/GenSoftMX/JIntent/ci.yml?branch=main)
![Coverage](https://img.shields.io/badge/coverage-checking-yellow)

> Lightweight, explicit Intent + State + Side Effect architecture for Flutter (MVI-inspired)  

## Table of Contents
- Overview
- Why JIntent?
- Quick Start
- Core Concepts
- Architecture
- Minimal Example
- Side Effects
- Concurrency & Ordering
- Observability
- Testing
- Comparison
- Migration (if any)
- Roadmap (Short Term)
- Contributing
- License

## Overview
JIntent provides a simple, explicit way to:
1. Represent immutable UI state (JState).
2. Trigger domain actions via Intents (JIntent subclasses).
3. Update state in a single, predictable point (JController).
4. Emit one-off side effects (navigation, dialogs, toasts) without polluting state (JEffect / side effect channels).

Goal: Clarity and testability with minimal boilerplate.

## Why JIntent?
| Problem in typical apps | How JIntent helps |
|-------------------------|-------------------|
| Mixed UI + logic        | Controller centralizes state transitions |
| Side effects duplicated | Dedicated side effect stream/channel |
| Hard to test flows      | Intents are discrete, testable units |
| Race conditions         | (Document your chosen intent handling policy) |
| State mutation          | Immutability via copyWith patterns |

## Quick Start
Add dependency:
```yaml
dependencies:
  jintent: ^X.Y.Z
```
Import:
```dart
import 'package:jintent/jintent.dart';
```

Create State:
```dart

@immutable
class CounterState extends JState {
  final int counter;

  const CounterState({required this.counter});

  @override
  CounterState copyWith({int? newStateCounter}) =>
      CounterState(counter: newStateCounter ?? counter);

  @override
  List<Object?> get props => [counter];

  factory CounterState.initialState() => const CounterState(counter: 0);
}

```

Declare Intents:
```dart
class DecrementUseCase extends JSyncUseCase<int, int> {
  @override
  Either<Exception, int> run(int currentValue) {
    final newValue = currentValue - 1;

    if (newValue < -10) {
      return Left(Exception('Value cannot be less than -10'));
    }
    return Right(newValue);
  }
}
```

Controller:
```dart
class CounterController extends JController<CounterState> {
  // With injection dependence
  final _getCurrentCounterValueIntent = Di.sl<GetCurrentCounterValueIntent>();
  final _incrementIntent = Di.sl<IncrementIntent>();
  final _decrementIntent = Di.sl<DecrementIntent>();

  // other common to Creation
  // final _getCurrentCounterValueIntent = GetCurrentCounterValueIntent()
  // final _incrementIntent = IncrementIntent();
  // final _decrementIntent = DecrementIntent();

  CounterController(super.initialState);

  void loadCounter() {
    intent(_getCurrentCounterValueIntent);
  }

  void increment() => intent(_incrementIntent);

  void decrement() => intent(_decrementIntent);

  @override
  void onInit() {}
}

```

UI:
```dart

import 'package:counter/src/presentation/counter/controllers/controller.dart';
import 'package:counter/src/presentation/counter/presentation/counter_effect_handler.dart';
import 'package:counter/src/presentation/counter/states/state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jintent/jintent.dart';

class CounterView extends ConsumerStatefulWidget {
  const CounterView({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _CounterViewState();
}

class _CounterViewState extends ConsumerState<CounterView> {
  final throttler = JThrottler(const Duration(milliseconds: 200));

  late final CounterController _counterController;

  JSideEffectHandler<CounterState> get _sideEffectHandler =>
      CounterEffectHandler(_counterController);

  @override
  void initState() {
    super.initState();

    _counterController = ref.read(couterControllerProvider.notifier);
  }

  @override
  Widget build(BuildContext context) {
    final counter = ref.watch(
      couterControllerProvider.select((value) => value.counter),
    );

    return JEffectListener(
      controller: _counterController,
      handler: _sideEffectHandler,
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text('You have pushed the button this many times:'),
              Text(
                '$counter',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ),
        ),
        floatingActionButton: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton.extended(
              label: const Text('Increment'),
              heroTag: 'Increment',
              onPressed: () => throttler.call(_counterController.increment),
              tooltip: 'Increment',
              icon: const Icon(Icons.exposure_plus_1_outlined),
            ),
            const SizedBox(height: 10),
            FloatingActionButton.extended(
              label: const Text('Decrement'),
              heroTag: 'Decrement',
              onPressed: () => throttler.call(_counterController.decrement),
              tooltip: 'Decrement',
              icon: const Icon(Icons.exposure_minus_1_sharp),
            ),
          ],
        ),
      ),
    );
  }
}

```

## Core Concepts
- JState: Immutable snapshot of UI data.
- JIntent: User or system intention (e.g., SubmitLogin, LoadItems).
- JController<S, I>: Receives intents, updates state, emits side effects.
- Side Effect: One-shot event (navigation, toast, analytics).
- Effect Channel / Stream: Decoupled delivery of ephemeral events.

## Architecture
Flow (simplified):
User Action -> Intent -> Controller.handle -> (New State) + (Optional Side Effect)

State updates propagate to UI via a ValueListenable/Stream.
Side effects consumed once by a listener (e.g. using a StreamBuilder or dedicated hook).


### ⚡ Side Effects (Modern Overview)

Side effects (JEffect) model transient events (navigation, dialogs, toasts) outside of state.  
Key types:
- JEffect<T> (base, can return a value or fail)
- JFireAndForgetEffect (no return value)
- JResultEffect<T> / JDialogEffect<T> (explicit return value)

Quick example:
```dart
final confirmed = await controller.emitAndWaitSideEffect(
  DeleteDialogEffect(itemName: 'File.txt'),
);
if (confirmed) {
  controller.intent(DeleteItemIntent(...));
}
```

If an awaited effect has no handler, the default strategy completes it silently (warnAndAutoComplete).  
Configure a different strategy with:
```dart
JEffectsConfig().unhandledStrategy = UnhandledEffectStrategy.throwError;
```

## Concurrency & Ordering

JIntent processes intents in a predictable, sequential order by default.  
- **Queue (FIFO):** Intents are enqueued and handled one at a time, ensuring state transitions are applied in the order they were received.
- **No Parallel Mutations:** This avoids race conditions and makes state changes easy to reason about.
- **Custom Policies:** Advanced users can implement custom intent handling strategies (e.g., debouncing, throttling, dropping, or merging intents) by extending the controller or using middleware.

**Best practice:**  
Document your chosen concurrency policy in your controller, especially if you change the default behavior. This helps maintain clarity and prevents subtle bugs in complex flows.


## Observability

JIntent provides production-ready observability features for monitoring, debugging, and understanding your application's behavior.

### Structured JSON Logging

```dart
import 'package:jintent/jintent.dart';

void main() {
  final logger = JStructuredLogger(
    serviceName: 'my-app',
    version: '1.0.0',
    minLevel: LogLevel.info,
  );
  
  logger.info('User logged in', context: {
    'userId': '12345',
    'action': 'login',
  });
  
  runApp(MyApp());
}
```

All logs are output as JSON for easy parsing:
```json
{
  "timestamp": "2025-10-15T12:34:56.789Z",
  "level": "INFO",
  "message": "User logged in",
  "service": "my-app",
  "version": "1.0.0",
  "context": {
    "userId": "12345",
    "action": "login"
  }
}
```

### Correlation IDs

Track user actions across multiple operations:

```dart
// Wrap user actions in a correlation context
await CorrelationContext.runWithCorrelation(() async {
  await controller.dispatch(LoginIntent());
  
  // Access the correlation ID anywhere
  final id = CorrelationContext.current;
  logger.info('Processing', context: {'correlationId': id});
});
```

### Metrics Collection

Collect operational and performance metrics:

```dart
void main() {
  // Enable metrics
  JMetrics.enable();
  JMetrics.attachToObserver();
  
  runApp(MyApp());
}

// Metrics are automatically tracked for:
// - Intent dispatches
// - State changes
// - Effect emissions
// - Execution timings
```

Manual metric recording:

```dart
// Counter
JMetrics.incrementCounter('user.login');

// Gauge
JMetrics.recordGauge('active.users', userCount);

// Timer
final timerId = JMetrics.startTimer('api.request');
await performOperation();
JMetrics.stopTimer(timerId);
```

### Complete Observability Example

```dart
class LoginIntent extends JIntent<AuthState> {
  final JStructuredLogger logger;

  @override
  Future<void> onInvoke() async {
    await CorrelationContext.runWithCorrelation(() async {
      final correlatedLogger = logger.withContext(
        CorrelationContext.asContext ?? {},
      );
      
      correlatedLogger.info('Login attempt started');
      final timerId = JMetrics.startTimer('login.duration');
      
      try {
        final user = await loginUseCase.execute();
        JMetrics.incrementCounter('login.success');
        JMetrics.stopTimer(timerId, tags: {'status': 'success'});
        correlatedLogger.info('Login successful');
        
        update((state) => state.copyWith(user: user));
      } catch (e) {
        JMetrics.incrementCounter('login.failed');
        JMetrics.stopTimer(timerId, tags: {'status': 'failed'});
        correlatedLogger.error('Login failed', error: e);
        
        emitSideEffect(ShowErrorEffect(e.toString()));
      }
    });
  }
}
```

📖 **For comprehensive observability documentation, see [docs/OBSERVABILITY_GUIDE.md](docs/OBSERVABILITY_GUIDE.md)**


## Advanced Features (Phase 4)

### DevTools Overlay

Real-time monitoring of JIntent operations directly in your app:

```dart
MaterialApp(
  builder: (context, child) {
    return JDevToolsOverlay(
      enabled: kDebugMode,
      child: child!,
    );
  },
)
```

Features:
- Real-time intent/state/effect visualization
- Event timeline with metadata
- Metrics dashboard
- Toggle on/off with FAB
- Zero performance impact when hidden

📖 **See [docs/DEVTOOLS_POC.md](docs/DEVTOOLS_POC.md)**

### Undo/Redo (Experimental)

Add undo/redo capabilities to your controllers:

```dart
class MyController extends JController<MyState>
    with UndoRedoMixin<MyState> {
  
  MyController() : super(MyState.initial());
  
  @override
  void onInit() {
    enableUndoRedo(maxHistorySize: 50);
  }
}

// In your intent
updateWithUndo((state) => state.copyWith(value: newValue));

// Undo/redo
controller.undo();  // Returns bool
controller.redo();  // Returns bool
```

Alternative command pattern approach also available for fine-grained control.

### Plugin Ecosystem

Extend JIntent with custom behavior:

```dart
class AnalyticsPlugin {
  void install() {
    JObserver.onIntentDispatched = (intent) {
      analytics.logEvent('intent_dispatched', 
        parameters: {'type': intent.runtimeType.toString()});
    };
  }
}
```

Extensibility points:
- Observer hooks (intents, states, effects)
- Custom dispatchers (priority, debouncing)
- Custom effect handlers
- Middleware pattern

📖 **See [docs/PLUGIN_HOOKS.md](docs/PLUGIN_HOOKS.md)**

### Performance

JIntent is designed for high performance:

- **Intent Processing**: < 0.5ms (P50)
- **State Updates**: > 10,000/sec
- **Memory Overhead**: < 1KB per controller
- **Binary Size**: +42KB to APK

📖 **See [docs/PERFORMANCE.md](docs/PERFORMANCE.md)**


## Testing
Recommended strategy:
1. Given initial state
2. When: dispatch intent
3. Await completion
4. Assert new state + captured side effects


## Comparison (High Level)
| Feature | JIntent | Bloc | Redux | Plain Riverpod |
|---------|---------|------|-------|----------------|
| Side effects channel | Yes | Yes (via Bloc) | Middleware needed | Provider-dependent |
| Boilerplate | Low | Medium | High | Low |
| Immutable state | Yes | Yes | Yes | Depends |
| Intent semantics | Explicit classes | Events | Actions | Method calls |
| Concurrency control | (Document) | Per event loop | Middleware | Custom |

## Migration
If upgrading from 1.x to 2.x:
- Update import paths.
- Adjust side effect API rename.
- See CHANGELOG for removed symbols.
(Provide MIGRATION.md if many items.)

## Roadmap

### Completed ✅
- [✓] **Phase 0**: Discovery and documentation baseline
- [✓] **Phase 1**: CI/CD, testing infrastructure, ADRs
- [✓] **Phase 2**: Security baseline, API patterns, data layer
- [✓] **Phase 3**: Structured logging, metrics, correlation IDs, integration tests
- [✓] **Phase 4**: DevTools overlay, undo/redo, performance docs, plugin hooks

### Recent Additions (Phase 4)
- [✓] DevTools overlay for real-time monitoring
- [✓] Undo/redo experimental support
- [✓] Performance benchmarks and optimization guide
- [✓] Plugin hooks documentation
- [✓] 95%+ OWASP compliance documentation

### Future Enhancements
- [ ] Advanced examples (debounce, pagination, streaming)
- [ ] Automated benchmark suite in CI
- [ ] Community plugin ecosystem
- [ ] Chrome DevTools integration

## Documentation

### Core Documentation
- **[Effects Guide](./doc/effects.md)** - Comprehensive side effects system documentation
- **[Mapper Reader](./doc/MAPPER_READER.md)** - Data mapping utilities

### Advanced Features (Phase 4)
- **[DevTools PoC](./docs/DEVTOOLS_POC.md)** - Real-time monitoring overlay documentation
- **[Plugin Hooks](./docs/PLUGIN_HOOKS.md)** - Extensibility guide for building plugins
- **[Performance Guide](./docs/PERFORMANCE.md)** - Benchmarks, optimization, profiling

### Observability (Phase 3)
- **[Observability Guide](./docs/OBSERVABILITY_GUIDE.md)** - Structured logging, metrics, correlation IDs
- **[Observability Example](./docs/examples/observability_example.dart)** - Complete working example

### Security & Best Practices
- **[Security Guide](./docs/SECURITY_GUIDE.md)** - OWASP ASVS compliance, input validation, secure state management
- **[Error Handling Guide](./docs/ERROR_HANDLING_GUIDE.md)** - Either patterns, exception handling, global error handlers
- **[API Versioning](./docs/API_VERSIONING.md)** - Semantic versioning policy, breaking changes, deprecation process
- **[Data Layer Guide](./docs/DATA_LAYER_GUIDE.md)** - Repository patterns, mappers, caching strategies

### Code Examples
- **[Validation Examples](./docs/examples/validation_examples.md)** - Input validation patterns and reusable validators
- **[Error Handling Examples](./docs/examples/error_handling_examples.md)** - Practical error handling patterns

### Governance & Architecture
- **[Documentation Index](./docs/README.md)** - Complete documentation navigation
- **[ADR-000 to ADR-009](./docs/adr/)** - Architecture Decision Records
- **[Executive Summary](./docs/EXECUTIVE_SUMMARY.md)** - Project overview and roadmap

# Contributing Guidelines

Thank you for your interest in contributing to this project.  
This document sets the official policies and guidelines for collaboration.  

## 1. Communication
- Before starting any development, please **open an issue** to discuss the proposal.  
- All contributions must align with the project's vision, objectives, and standards.  

## 2. Git Workflow
- Use branch names with the following format:
  - `feature/<short-description>`
  - `fix/<short-description>`
  - `chore/<short-description>`
- Example: `feature/offline-sync`

- Commit messages must follow the **Conventional Commits** standard:
  - `feat`: New feature
  - `fix`: Bug fix
  - `docs`: Documentation
  - `refactor`: Internal refactor, no functional change
  - `test`: Adding or updating tests

## 3. Code Quality
- Every change must include:
  - **Unit and/or integration tests**.
  - An entry in **CHANGELOG.md** under `[Unreleased]`.
  - Compliance with the project’s **linting and formatting** rules.

### CI/CD Pipeline
- All PRs trigger automated checks via GitHub Actions:
  - **Code formatting** (`dart format`)
  - **Static analysis** (`flutter analyze`)
  - **Test suite** with coverage report
  - **Coverage threshold** enforcement (≥80%)
- PRs cannot merge until all checks pass.
- Coverage reports are available as artifacts in the workflow runs.

## 4. Pull Requests
- PRs must be clear, concise, and focused only on related changes.  
- The PR description should include:
  - The problem it solves.
  - The changes introduced.
  - Instructions for testing.  
- At least one reviewer must approve the PR, and all automated checks must pass.  

## 5. Versioning and Releases
- We follow **Semantic Versioning (SemVer)**:
  - **MAJOR**: Breaking changes.
  - **MINOR**: Backward-compatible new features.
  - **PATCH**: Bug fixes.
- All releases must be documented in **CHANGELOG.md**.  

## 6. Code of Conduct
All interactions must follow the [Code of Conduct](./CODE_OF_CONDUCT.md), fostering a professional, inclusive, and respectful environment.  


## License
MIT © 2025 TodoFlutter.com  

## FAQ
Q: How do I avoid duplicate side effects after Hot Reload?  
A: Keep effects listener registration inside initState and cancel in dispose; do not re-emit past effects (channel is one-shot).

Q: Can I dispatch intents from inside another intent?  
A: Prefer composing functions or scheduling a new intent after current finishes to maintain linear flow.

Q: Does JIntent support cancellation?  
A: (Document if implemented; show API or mark as planned.)
