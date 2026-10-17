# ADR-002: Stable optional undo/redo

**Status:** Accepted for unreleased 3.0.0

**Date:** 2026-10-16

**Relates to:** ADR-000 (D3, D7, D9, D12) and ADR-001 (D16).

## Decision

Promote snapshot and command history to the stable optional entry point
`package:jintent/undo_redo.dart`, as authorized by the maintainer. Preserve
`experimental.dart` as a compatibility export; implementation moves to
`lib/src/undo_redo/`. The core entry point remains focused.

The controller mixin exposes immutable `JUndoHistoryState` through a read-only
listenable. History metadata is separate from domain state, so clearing or
disabling history can notify UI without inventing a domain change or duplicating
flags in each application's state. The controller owns notifier disposal.

Snapshot undo/redo uses controller updates and global state observation. Its
synchronous methods do not enqueue themselves: consumers that require ordering
with asynchronous edits call them within a sequentially dispatched intent.
Cancelled intents and disposed controllers cannot mutate history. Positive
capacities, immutable snapshots and pure commands are explicit contracts.

## Consequences and verification

Existing type and method names remain available. Invalid capacities now throw.
Disposed operations become no-ops, and undo/redo state changes become visible to
observers. Consumers must subscribe to history metadata for history-only changes.
No persistence, remote compensation or automatic intent serialization is added.

The [guide](../undo-redo.md) specifies behavior and migration. Contract and
regression suites live under `test/src/undo_redo/`; the notes example covers the
controller and reactive UI. Test results are reported when these checks run,
not implied by the accepted status of this record.
