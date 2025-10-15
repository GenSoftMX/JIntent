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

## Roadmap (Short Term)
- [✓] Formal concurrency policy documentation
- [✓] Logging observer utility
- [ ] Advanced examples (debounce, pagination, streaming)
- [ ] DevTool overlay (visualize intents/states)
- [ ] Undo/Redo experiment

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
