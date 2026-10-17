# ADR-003: Support equatable 2.x and 3.x

**Status:** Accepted for 3.0.1

**Date:** 2026-10-16

**Relates to:** ADR-001 (D21). This supersedes the `equatable` part of D21; the
`state_notifier` part stands.

## Context

pub.dev scores a package on whether all its dependencies support their latest
versions. `equatable: ^2.0.5` excluded 3.0.0 (published 2026-09-15). D21 kept
2.x because 3.0.0 was believed to stop comparing `runtimeType`, which would make
two distinct state classes with equal `props` equal and skip their transition.

## Decision

Declare `equatable: '>=2.0.5 <4.0.0'`. `JState` and `JEquatable` keep extending
the `Equatable` class, so state equality does not change.

## Evidence (verified 2026-10-16)

- The `Equatable` class in 3.0.0 still compares `runtimeType` in `==` and uses it
  in `hashCode`. Its changelog lists the removal of `EquatableMixin`, which
  JIntent does not use. The premise of D21 was a misreading of that changelog.
- A test with 3.0.0 resolved: empty-props `Initial` and `Loading` states are not
  equal, and `update` from one to the other notifies listeners. The same test
  passes with 2.x. It is now part of `test/src/core/jstate_test.dart`.
- The library's tests and the analyzer pass on Flutter 3.29.2 and 3.47.6 with
  `equatable` 3.0.0 and with the lowest allowed version, 2.0.5.

## Consequences

- Applications on `equatable` 2.x keep working, and applications on 3.x can now
  resolve JIntent.
- An application that mixes `EquatableMixin` into its own classes must migrate
  that code before moving to `equatable` 3.x. That is independent of JIntent.
- State equality is defined by `equatable`. The regression test fails if a future
  release changes how distinct state classes compare.
