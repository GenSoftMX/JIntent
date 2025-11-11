# GitHub Labels Configuration

This document defines all labels used in the JIntent repository for issue and PR management.

## Phase Labels

Labels to track work across different project phases.

| Label | Color | Description |
|-------|-------|-------------|
| `phase-0` | `#0E8A16` | Phase 0: Discovery & Analysis (Complete) |
| `phase-1` | `#1D76DB` | Phase 1: Foundation (CI/CD, Testing, ADRs) |
| `phase-2` | `#5319E7` | Phase 2: Security & API |
| `phase-3` | `#D93F0B` | Phase 3: Observability & Advanced Testing |
| `phase-4` | `#E99695` | Phase 4: Advanced Features & Optimization |

## Gate Labels

Labels for governance gate tracking.

| Label | Color | Description |
|-------|-------|-------------|
| `gate-a1` | `#006B75` | Gate A1: Discovery Complete |
| `gate-a2` | `#0075CA` | Gate A2: Foundation Complete |
| `gate-b` | `#7057FF` | Gate B: Security Baseline |
| `gate-c` | `#A2EEEF` | Gate C: Production Ready |

## Priority Labels

Labels to indicate issue priority.

| Label | Color | Description |
|-------|-------|-------------|
| `critical` | `#B60205` | Critical priority - blocks progress |
| `high-priority` | `#D93F0B` | High priority - important for current phase |
| `medium-priority` | `#FBCA04` | Medium priority - should be addressed |
| `low-priority` | `#0E8A16` | Low priority - nice to have |

## Category Labels

Labels to categorize work type.

| Label | Color | Description |
|-------|-------|-------------|
| `adr` | `#5319E7` | Architecture Decision Record |
| `ci-cd` | `#1D76DB` | CI/CD pipeline and automation |
| `testing` | `#0075CA` | Testing-related work |
| `coverage` | `#BFD4F2` | Code coverage improvements |
| `governance` | `#D4C5F9` | Governance, process, and policy |
| `documentation` | `#0075CA` | Documentation improvements |
| `security` | `#D93F0B` | Security-related work |
| `observability` | `#5319E7` | Logging, metrics, tracing |
| `performance` | `#FBCA04` | Performance optimization |
| `dependencies` | `#0366D6` | Dependency management |

## Type Labels

Labels to indicate the type of issue.

| Label | Color | Description |
|-------|-------|-------------|
| `bug` | `#D73A4A` | Something isn't working |
| `feature` | `#A2EEEF` | New feature or request |
| `enhancement` | `#84B6EB` | Enhancement to existing feature |
| `refactor` | `#5319E7` | Code refactoring (no functional change) |
| `chore` | `#FEF2C0` | Maintenance tasks |

## Status Labels

Labels to track issue status.

| Label | Color | Description |
|-------|-------|-------------|
| `blocked` | `#D93F0B` | Blocked by another issue or external factor |
| `in-progress` | `#FBCA04` | Currently being worked on |
| `needs-review` | `#0075CA` | Ready for review |
| `needs-feedback` | `#CC317C` | Needs feedback from maintainers or community |
| `help-wanted` | `#008672` | Extra attention is needed (good for contributors) |
| `good-first-issue` | `#7057FF` | Good for newcomers |

## Special Labels

Special purpose labels.

| Label | Color | Description |
|-------|-------|-------------|
| `breaking-change` | `#B60205` | Breaking API change (major version) |
| `backward-compatible` | `#0E8A16` | Backward compatible change |
| `exception-change` | `#D93F0B` | Exception/error handling change (requires ADR) |
| `wontfix` | `#FFFFFF` | This will not be worked on |
| `duplicate` | `#CFD3D7` | Duplicate of another issue |
| `invalid` | `#E4E669` | Invalid issue |
| `question` | `#D876E3` | Further information is requested |

## Label Usage Guidelines

### Phase Labels

- Use phase labels to track which phase an issue belongs to
- An issue should have exactly one phase label
- Phase labels help with project board filtering and milestone tracking

### Priority Labels

- Assign priority based on impact and urgency
- Critical: Blocks other work or has security implications
- High: Important for current phase completion
- Medium: Should be addressed but not urgent
- Low: Nice to have, can be deferred

### Combining Labels

Common label combinations:

```
phase-1 + ci-cd + high-priority + feature
→ High-priority CI/CD feature for Phase 1

phase-1 + testing + coverage + medium-priority + enhancement
→ Medium-priority test coverage enhancement for Phase 1

gate-a1 + governance + documentation + critical
→ Critical governance documentation for Gate A1

adr + phase-1 + documentation + high-priority
→ High-priority ADR documentation for Phase 1
```

---

**Document Status:** Active  
**Last Updated:** 2025-10-15  
**Maintained By:** Project Maintainers

---
