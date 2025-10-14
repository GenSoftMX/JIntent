# Architecture Diagrams

**Status:** Phase 0 Baseline | **Date:** 2025-10-14

## Overview

This directory contains architectural diagrams and visual representations of the JIntent system. During Phase 0, diagrams are provided in textual/pseudo-diagram format within the main documentation. Visual diagrams (Mermaid, PlantUML, or exported images) will be added in Phase 2.

## Available Diagrams (Textual Format)

All diagrams are currently embedded in documentation as textual descriptions:

### 1. MVI Architecture Overview
**Location:** `docs/REPOSITORY_ANALYSIS.md#logical-architecture`

```
UI Layer (Flutter Widgets)
    ↓ Emits Intent | ↑ Listens to State + Effects
JController<State>
    ├─ State Stream (StateNotifier)
    ├─ Intent Queue (Sequential/Concurrent)
    └─ Side Effect Stream (Broadcast)
        ↓ Triggers | ↓ Executes | ↓ Emits
    JState      JIntent       JEffect
   (Immutable) (Use Cases)   (Transient)
                    ↓ Uses
              Either<L, R>
           (Functional Errors)
```

### 2. Data Flow: Request Lifecycle
**Location:** `docs/REPOSITORY_ANALYSIS.md#data-flow-request-lifecycle`

Describes the complete flow from UI interaction through intent processing to state updates.

### 3. Sequence Diagram: Generic Authentication Pattern
**Location:** `docs/REPOSITORY_ANALYSIS.md#sequence-diagram-authentication-flow-generic-pattern`

Shows interaction between User, UI Widget, Controller, Intent/UseCase, and Either Result.

### 4. Layer Structure
**Location:** `docs/REPOSITORY_ANALYSIS.md#directory-structure`

Complete directory tree with file organization by layer.

## Planned Visual Diagrams (Phase 2)

### High Priority
- [ ] MVI Architecture (Mermaid/PlantUML)
- [ ] Intent Processing Flow (Flowchart)
- [ ] Side Effect Lifecycle (State diagram)
- [ ] Error Handling Patterns (Sequence diagrams)

### Medium Priority
- [ ] Component Interaction (Class diagram)
- [ ] Deployment Topology (pub.dev distribution)
- [ ] Integration Patterns (Multiple apps sharing code)

### Low Priority
- [ ] Performance Benchmarking Results (Graphs)
- [ ] Test Coverage Visualization (Treemap)
- [ ] Dependency Graph (Package relationships)

## Diagram Standards (Future)

When visual diagrams are added, they should follow these standards:

### Format
- **Primary:** Mermaid (embeddable in Markdown)
- **Alternative:** PlantUML (for complex diagrams)
- **Export:** PNG/SVG for presentations

### Naming Convention
```
{category}-{description}-{version}.{ext}

Examples:
architecture-mvi-overview-v1.mmd
flow-intent-processing-v1.mmd
sequence-auth-flow-v1.puml
```

### Content Requirements
- Title and version in diagram
- Legend for symbols/colors
- Date created/updated
- Link to relevant documentation

### Accessibility
- High contrast colors
- Clear labels (readable at 100% zoom)
- Alternative text descriptions in README
- Both light and dark theme versions (if applicable)

## Tools

**Recommended Tools:**
- [Mermaid Live Editor](https://mermaid.live/)
- [PlantUML Online](https://www.plantuml.com/plantuml/)
- [draw.io](https://app.diagrams.net/) (for complex flows)
- [Excalidraw](https://excalidraw.com/) (for hand-drawn style)

**Integration:**
- GitHub renders Mermaid in Markdown
- VS Code extensions available for both
- Can be version-controlled as text

## Contributing Diagrams

To contribute a diagram:

1. Create diagram using approved tool
2. Follow naming convention
3. Add to this README with description
4. Reference from main documentation
5. Submit PR with diagram + documentation updates

---

**Note:** Visual diagrams are intentionally deferred to Phase 2 to maintain focus on comprehensive textual analysis during Phase 0 Discovery. The textual descriptions in the documentation are sufficient for understanding the architecture and making informed decisions.

---

**Maintained By:** System Architecture & Governance Analyst  
**Last Updated:** 2025-10-14  
**Related Documents:** [Repository Analysis](../../docs/REPOSITORY_ANALYSIS.md)
