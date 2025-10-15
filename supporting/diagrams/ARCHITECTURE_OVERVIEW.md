# JIntent Architecture Diagrams

**Status:** Draft  
**Date:** 2025-10-15  
**Version:** 2.1.0

This document provides textual and conceptual diagrams for the JIntent architecture.

---

## 1. High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     PRESENTATION LAYER                       │
│          (Flutter Widgets, Screens, UI Components)          │
│                                                              │
│  Responsibilities:                                           │
│  - Display UI based on state                                │
│  - Capture user input                                       │
│  - Dispatch intents to controller                           │
│  - Listen to state changes                                  │
│  - Handle side effects (navigation, dialogs)                │
└─────────────┬────────────────────────────────────┬──────────┘
              │ dispatches JIntent                 │ observes
              │                                    │ state & effects
              ▼                                    │
┌─────────────────────────────────────────────────┴──────────┐
│                     CORE LAYER                              │
│                 (JIntent Framework)                         │
│                                                             │
│  ┌────────────────────────────────────────────────────┐   │
│  │           JController<TState>                       │   │
│  │  - Holds current state                              │   │
│  │  - Receives intents                                 │   │
│  │  - Updates state via update()                       │   │
│  │  - Emits side effects                               │   │
│  │  - Manages lifecycle (onInit, dispose)              │   │
│  └────────┬──────────────────────────────┬──────────────┘   │
│           │ dispatches                   │ emits            │
│           ▼                              ▼                  │
│  ┌─────────────────┐          ┌──────────────────────┐    │
│  │  JIntent        │          │  Side Effect Stream  │    │
│  │  Dispatcher     │          │  Stream<JEffect>     │    │
│  │  (Sequential)   │          │  (broadcast)         │    │
│  └────────┬────────┘          └──────────────────────┘    │
│           │ invokes                                        │
│           ▼                                                │
│  ┌─────────────────┐                                      │
│  │  JIntent        │                                      │
│  │  - onInvoke()   │                                      │
│  │  - Access state │                                      │
│  │  - Call use case│                                      │
│  │  - Update state │                                      │
│  └────────┬────────┘                                      │
└───────────┼─────────────────────────────────────────────┘
            │ calls
            ▼
┌─────────────────────────────────────────────────────────────┐
│                     DOMAIN LAYER                             │
│               (Business Logic & Rules)                       │
│                                                              │
│  ┌─────────────────────────────────────────────────────┐   │
│  │          JUseCase<INPUT, OUTPUT>                     │   │
│  │  - Encapsulates business logic                       │   │
│  │  - Validation via validators                         │   │
│  │  - Returns Either<Exception, OUTPUT>                 │   │
│  │  - Pure functions (testable)                         │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                              │
│  ┌─────────────────────────────────────────────────────┐   │
│  │          Either<L, R> (Result Monad)                 │   │
│  │  - Type-safe error handling                          │   │
│  │  - Left: Error/Failure                               │   │
│  │  - Right: Success/Value                              │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                              │
│  ┌─────────────────────────────────────────────────────┐   │
│  │          JMapper<INPUT, OUTPUT>                      │   │
│  │  - Data transformation                               │   │
│  │  - DTO ↔ Entity mapping                             │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. State Flow Diagram

```
┌──────────────┐
│  User Action │ (e.g., tap button)
└──────┬───────┘
       │
       ▼
┌───────────────────────┐
│  Widget Event Handler │
│  onPressed: () {...}  │
└──────┬────────────────┘
       │
       ▼
┌─────────────────────────────┐
│  Controller Method Call     │
│  controller.increment()     │
└──────┬──────────────────────┘
       │
       ▼
┌─────────────────────────────┐
│  Intent Dispatch            │
│  intent(IncrementIntent())  │
└──────┬──────────────────────┘
       │
       ▼
┌──────────────────────────────┐
│  Sequential Dispatcher       │
│  (Queues intent if busy)     │
└──────┬───────────────────────┘
       │
       ▼
┌───────────────────────────────┐
│  Intent Execution             │
│  IncrementIntent.onInvoke()   │
└──────┬────────────────────────┘
       │
       ├─→ Read Current State
       │   state.counter
       │
       ├─→ Call Use Case
       │   final result = await incrementUseCase.call(state.counter)
       │
       ├─→ Check Result
       │   if (result.isLeft) → Handle Error
       │   if (result.isRight) → Continue
       │
       ▼
┌────────────────────────────────┐
│  State Update                  │
│  controller.update((s) =>      │
│    s.copyWith(counter: newVal))│
└──────┬─────────────────────────┘
       │
       ▼
┌────────────────────────────────┐
│  StateNotifier Notification    │
│  Listeners notified of change  │
└──────┬─────────────────────────┘
       │
       ▼
┌────────────────────────────────┐
│  Widget Rebuild                │
│  Build method called with new  │
│  state values                  │
└────────────────────────────────┘
```

---

## 3. Side Effect Flow

```
┌──────────────────────────────┐
│  Intent Logic                │
│  (decides to show dialog)    │
└──────┬───────────────────────┘
       │
       ▼
┌──────────────────────────────┐
│  Emit Side Effect            │
│  controller.emitSideEffect(  │
│    ConfirmDialogEffect(...)  │
│  )                           │
└──────┬───────────────────────┘
       │
       ▼
┌──────────────────────────────┐
│  Add to Stream               │
│  _sideEffectController.add() │
└──────┬───────────────────────┘
       │
       ▼
┌──────────────────────────────┐
│  JEffectListener (in UI)     │
│  Receives effect from stream │
└──────┬───────────────────────┘
       │
       ▼
┌──────────────────────────────┐
│  EffectHandler.handle()      │
│  Matches effect type         │
└──────┬───────────────────────┘
       │
       ▼
┌──────────────────────────────┐
│  Show Dialog                 │
│  await showDialog(...)       │
└──────┬───────────────────────┘
       │
       ▼
┌──────────────────────────────┐
│  User Responds               │
│  (confirms or cancels)       │
└──────┬───────────────────────┘
       │
       ▼
┌──────────────────────────────┐
│  Complete Effect             │
│  effect.complete(confirmed)  │
└──────┬───────────────────────┘
       │
       ▼
┌──────────────────────────────┐
│  Intent Continues            │
│  (if using emitAndWaitSideEffect)
│  final confirmed = await ...  │
└────────────────────────────────┘
```

---

## 4. Component Relationships

```
┌─────────────────────────────────────────────────────────────┐
│                        JState                                │
│  - Immutable data class                                      │
│  - Extends Equatable                                         │
│  - Must implement copyWith()                                 │
└─────────────────────────────────────────────────────────────┘
                            ▲
                            │ extends
                            │
┌─────────────────────────────────────────────────────────────┐
│                    CounterState                              │
│  final int counter;                                          │
│  CounterState copyWith({int? counter}) {...}                 │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ managed by
                            ▼
┌─────────────────────────────────────────────────────────────┐
│              JController<CounterState>                       │
│  - Holds currentState                                        │
│  - Receives intents                                          │
│  - Updates state                                             │
│  - Emits effects                                             │
└─────────────────────────────────────────────────────────────┘
                            ▲                    │
                  receives  │                    │ emits
                            │                    ▼
┌──────────────────────────┐    ┌───────────────────────────┐
│  JIntent<CounterState>   │    │   Stream<JEffect>         │
│  - IncrementIntent       │    │   - ShowSnackbarEffect    │
│  - DecrementIntent       │    │   - NavigateEffect        │
└──────────┬───────────────┘    └───────────────────────────┘
           │ calls                              │
           ▼                                    │ handled by
┌──────────────────────────┐                   ▼
│  JUseCase<int, int>      │    ┌──────────────────────────┐
│  - IncrementUseCase      │    │  JEffectListener         │
│  - Returns Either        │    │  + EffectHandler         │
└──────────────────────────┘    └──────────────────────────┘
```

---

## 5. Intent Execution Sequence

```
Time ──────────────────────────────────────────────────────────▶

Thread: Main (UI)                 Thread: Sequential Dispatcher
─────────────────────────────────────────────────────────────────

User taps button
     │
     ▼
controller.intent(Intent1)
     │                                    │
     │───────────────────────────────────▶│ Queue Intent1
     │                                    │ Start execution
     │                                    │    │
User taps button again                   │    ▼
     │                                    │ Intent1.onInvoke()
     ▼                                    │    │
controller.intent(Intent2)               │    │ (processing...)
     │                                    │    │
     │───────────────────────────────────▶│ Queue Intent2
     │                                    │ (waits for Intent1)
     │                                    │    │
     │                                    │    ▼
     │◀───────────────────────────────────│ State Update
Widget rebuilds                          │    │
     │                                    │    ▼
     │                                    │ Intent1 Complete
     │                                    │    │
     │                                    │    ▼
     │                                    │ Dequeue Intent2
     │                                    │ Start execution
     │                                    │    │
     │                                    │    ▼
     │                                    │ Intent2.onInvoke()
     │                                    │    │
     │                                    │    ▼
     │◀───────────────────────────────────│ State Update
Widget rebuilds                          │
     │                                    │ Intent2 Complete
     ▼                                    ▼

Sequential execution ensures no race conditions!
```

---

## 6. Module Dependency Graph

```
┌────────────────────────────────────────────────────────────┐
│                    Application Layer                        │
│           (Consumer code using JIntent)                     │
│   - Concrete States (CounterState)                          │
│   - Concrete Intents (IncrementIntent)                      │
│   - Concrete Controllers (CounterController)                │
│   - Concrete Effects (ShowSnackbarEffect)                   │
└────────┬───────────────────────────────────────────────────┘
         │ depends on
         ▼
┌────────────────────────────────────────────────────────────┐
│                     JIntent Package                         │
│                  (lib/jintent.dart)                         │
└────────┬────────────────────────────────┬──────────────────┘
         │ exports                        │ exports
         ▼                                ▼
┌─────────────────────┐       ┌─────────────────────────────┐
│   Core Module       │       │     Domain Module           │
│   src/core/         │       │     src/domain/             │
│   - JController     │       │     - JUseCase              │
│   - JIntent         │       │     - Either                │
│   - JState          │       │     - Mapper                │
│   - JEffect         │       │                             │
│   - Dispatchers     │       │     (Pure Dart, no deps)    │
└──────┬──────────────┘       └─────────────────────────────┘
       │ depends on
       ▼
┌─────────────────────────────────────────────────────────────┐
│              External Dependencies                           │
│  - state_notifier (state management)                        │
│  - equatable (value equality)                               │
│  - flutter (framework)                                      │
└─────────────────────────────────────────────────────────────┘

Optional Modules (no required dependencies):
┌─────────────────────┐  ┌─────────────────────┐  ┌──────────┐
│  DevTools Module    │  │  Navigation Module  │  │  Utils   │
│  src/devtools/      │  │  src/navigation/    │  │  src/    │
│  - JObserver        │  │  - JNavigator       │  │  utils/  │
│  - Logging          │  │                     │  │          │
└─────────────────────┘  └─────────────────────┘  └──────────┘
```

---

## 7. Data Transformation Flow

```
External Source (API, Database)
        │
        ▼
┌──────────────────┐
│   Raw Data       │
│   (JSON, etc.)   │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│   DTO            │
│   (Data Transfer │
│    Object)       │
└────────┬─────────┘
         │
         │ JMapper.transform()
         ▼
┌──────────────────┐
│   Domain Entity  │
│   (Business      │
│    Model)        │
└────────┬─────────┘
         │
         │ Used in
         ▼
┌──────────────────┐
│   JState         │
│   (UI State)     │
└────────┬─────────┘
         │
         │ Rendered by
         ▼
┌──────────────────┐
│   Widget         │
│   (UI)           │
└──────────────────┘

Reverse flow for writes:
Widget Input → JState → Domain Entity → DTO → External Store
```

---

## 8. Error Handling Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    Use Case Execution                        │
└──────┬──────────────────────────────────────────────────────┘
       │
       ▼
   ┌───────┐
   │Validation│
   └───┬──────┘
       │
    ┌──┴──┐
    │ OK? │
    └──┬──┘
       │
   ┌───┴──────┬────────┐
   │          │        │
  YES        NO        │
   │          │        │
   ▼          ▼        │
┌──────┐  ┌────────┐  │
│ Run  │  │ Return │  │
│Logic │  │ Left(  │  │
└──┬───┘  │ Error) │  │
   │      └────────┘  │
   │                  │
   ▼                  │
┌───────┐             │
│Success?│            │
└───┬───┘             │
    │                 │
┌───┴──────┬────────┐ │
│          │        │ │
YES       NO        │ │
│          │        │ │
▼          ▼        │ │
Return    Return    │ │
Right(    Left(     │ │
value)    error)    │ │
│          │        │ │
└──────────┴────────┘ │
       │              │
       ▼              │
┌─────────────────────┴──────────────────────────────────────┐
│                Intent Handles Result                        │
│  if (result.isLeft) {                                       │
│    // Show error effect                                     │
│    controller.emitSideEffect(ErrorEffect(result.left!));   │
│    return;                                                  │
│  }                                                          │
│  // Use result.right, update state                         │
│  controller.update((s) => s.copyWith(data: result.right)); │
└─────────────────────────────────────────────────────────────┘
```

---

## 9. Testing Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Test Pyramid                            │
│                                                             │
│                    ┌───────────┐                           │
│                    │    E2E    │ (Future)                   │
│                    │   Tests   │                           │
│                    └─────┬─────┘                           │
│                          │ Few, slow, high-level           │
│                  ┌───────┴───────┐                         │
│                  │  Integration  │ (Future)                 │
│                  │     Tests     │                         │
│                  └───────┬───────┘                         │
│                          │ Some, medium speed              │
│          ┌───────────────┴───────────────┐                │
│          │       Unit Tests               │ (Current)      │
│          │  - Controller tests            │                │
│          │  - Intent tests                │                │
│          │  - Use case tests              │                │
│          │  - Effect tests                │                │
│          │  - State tests                 │                │
│          └────────────────────────────────┘                │
│                  Many, fast, focused                        │
└─────────────────────────────────────────────────────────────┘

Test Isolation:
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│  Controller  │────▶│   Intent     │────▶│   UseCase    │
│    Test      │     │    Test      │     │    Test      │
│              │     │              │     │              │
│ Mock Intent  │     │ Mock UseCase │     │ Pure logic   │
│ Verify state │     │ Verify calls │     │ No mocks     │
└──────────────┘     └──────────────┘     └──────────────┘
```

---

## 10. Observability Integration

```
┌─────────────────────────────────────────────────────────────┐
│                    JController                               │
│  (State & Effect Management)                                │
└──────┬────────────────────────────────────────┬─────────────┘
       │ notifies                               │ notifies
       ▼                                        ▼
┌──────────────────────┐         ┌───────────────────────────┐
│  JObserver           │         │  JObserver                │
│  .notifyStateChanged │         │  .notifyEffectEmitted     │
└──────┬───────────────┘         └───────┬───────────────────┘
       │                                 │
       │ hooks into                      │ hooks into
       ▼                                 ▼
┌──────────────────────────────────────────────────────────────┐
│              Observability Layer (Consumer)                   │
│                                                              │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐│
│  │  Logging    │  │  Analytics  │  │  Crash Reporting    ││
│  │  (Console,  │  │  (Firebase, │  │  (Sentry,           ││
│  │   File)     │  │   Mixpanel) │  │   Crashlytics)      ││
│  └─────────────┘  └─────────────┘  └─────────────────────┘│
│                                                              │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐│
│  │  Metrics    │  │  Tracing    │  │  DevTools           ││
│  │  (Custom)   │  │  (Future)   │  │  (Future)           ││
│  └─────────────┘  └─────────────┘  └─────────────────────┘│
└──────────────────────────────────────────────────────────────┘
```

---

**Note:** These diagrams are textual representations. For visual rendering, tools like Mermaid, PlantUML, or draw.io can be used in future phases.

---

**Document Status:** Draft  
**Last Updated:** 2025-10-15  
**Next Update:** Phase 1 (add Mermaid diagrams)
