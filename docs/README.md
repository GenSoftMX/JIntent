# JIntent - Documentation Index

**Status:** Draft  
**Last Updated:** 2025-10-15  
**Version:** 2.1.0

## 📚 Documentation Navigation Hub

This directory contains comprehensive documentation for the JIntent project, covering architecture, governance, analysis, and decision records.

---

## 📋 Phase 0: Discovery & Initial Analysis

### Core Documentation

1. **[Executive Summary](./EXECUTIVE_SUMMARY.md)**
   - High-level project overview
   - Key strengths and critical gaps
   - Risk highlights and improvement roadmap
   - Success criteria and assumptions

2. **[Repository Analysis](./REPOSITORY_ANALYSIS.md)**
   - Detailed codebase profiling
   - Architecture mapping and flow diagrams
   - Security and compliance baseline
   - Dependency assessment
   - Testing and quality metrics

3. **[Exception Inventory](./EXCEPTION_INVENTORY.md)**
   - Error and exception handling patterns
   - Exception codes and categories
   - Governance rules for error handling
   - Change workflow and approval process

4. **[Discovery Phase Complete](./DISCOVERY_PHASE_COMPLETE.md)**
   - Gate package and deliverables checklist
   - Validation criteria
   - Sign-off roster
   - Next phase entry requirements

---

## 🏛️ Architecture Decision Records (ADRs)

### Phase 0 Baseline

- **[ADR-000: Context and High-Level Decisions](./adr/ADR-000-context-and-high-level-decisions.md)**
  - Project context and guiding principles
  - Initial architectural decisions
  - Non-functional targets
  - Governance and change control

### Reserved for Future Phases

The following ADR slots are reserved for Design Phase (Phase 1):

- ADR-001: [Reserved] API Design and Versioning Strategy
- ADR-002: [Reserved] Security Architecture and Authentication
- ADR-003: [Reserved] Data Layer and Persistence Strategy
- ADR-004: [Reserved] Testing Strategy and Coverage Targets
- ADR-005: [Reserved] Observability and Monitoring
- ADR-006: [Reserved] Error Handling and Logging Standards
- ADR-007: [Reserved] CI/CD Pipeline and Release Process
- ADR-008: [Reserved] Documentation Standards
- ADR-009: [Reserved] Performance Optimization Strategy

---

## 📊 Supporting Materials

### Metrics & Analytics
- [Baseline Metrics](../supporting/metrics/BASELINE_METRICS.json) - Quantitative project metrics captured at discovery

### Diagrams
- [Architecture Diagrams](../supporting/diagrams/) - System architecture, flow diagrams, and sequence diagrams

---

## 🎯 Project Context

**Project Name:** JIntent  
**Domain:** Flutter State Management Architecture  
**Primary Language:** Dart  
**Framework:** Flutter SDK  
**Current Version:** 2.1.0  
**License:** MIT

### Purpose

JIntent is a lightweight, explicit Intent + State + Side Effect architecture for Flutter applications, inspired by MVI (Model-View-Intent) pattern. It provides:

1. Immutable UI state representation (JState)
2. Domain actions via Intents (JIntent subclasses)
3. Centralized state updates (JController)
4. One-off side effects without polluting state (JEffect)

### Key Characteristics

- **Pattern:** MVI-inspired architecture
- **Infrastructure:** Modular monolith (single package)
- **Deployment:** Published to pub.dev
- **Criticality:** Medium (open-source library)
- **Data Classification:** Public

---

## 🔐 Governance

### Change Control

- All code changes require Issue creation and discussion
- PRs require at least one reviewer approval
- Conventional Commits standard enforced
- Semantic Versioning (SemVer) followed

### Documentation Standards

- All major decisions documented in ADRs
- ADRs are immutable once approved
- Architecture changes require ADR update
- Error handling changes require governance approval

### Quality Gates

**Gate A1 - Discovery Complete:** All Phase 0 deliverables produced and reviewed  
**Gate A2 - Design Baseline:** ADRs 001-009 completed (Future Phase)  
**Gate B - Implementation:** Security and testing targets met (Future Phase)  
**Gate C - Release:** Full compliance and acceptance criteria met (Future Phase)

---

## 📖 Additional Documentation

### Project Documentation (Root Level)

- [Main README](../README.md) - User-facing documentation
- [CHANGELOG](../CHANGELOG.md) - Version history and changes
- [CODE_OF_CONDUCT](../CODE_OF_CONDUCT.md) - Community guidelines
- [LICENSE](../LICENSE) - MIT License

### Technical Documentation (doc/)

- [Effects Guide](../doc/effects.md) - Side effects system comprehensive guide
- [Mapper Reader](../doc/MAPPER_READER.md) - Mapper library documentation

### Example Application

- [Example App](../example/) - Counter application demonstrating JIntent usage

---

## 🚀 Quick Links

- **Repository:** https://github.com/GenSoftMX/JIntent
- **Package:** https://pub.dev/packages/jintent
- **Issues:** https://github.com/GenSoftMX/JIntent/issues
- **Discussions:** https://github.com/GenSoftMX/JIntent/discussions

---

## 📝 Document Status Legend

- **Draft** - Work in progress, subject to change
- **Review** - Under stakeholder review
- **Approved** - Finalized and approved by stakeholders
- **Immutable** - Locked, requires new ADR for changes

---

## 👥 Stakeholders

### Current Maintainers

- **Project Lead:** TodoFlutter.com
- **Organization:** GenSoftMX

### Contributor Community

- Open source contributors via GitHub
- Users and adopters providing feedback

---

## 📅 Phase Timeline

### Phase 0: Discovery & Initial Analysis
**Status:** In Progress  
**Started:** 2025-10-15  
**Target Completion:** 2025-10-29 (2 weeks)

### Future Phases
- **Phase 1:** Foundation - Hygiene fixes, dependency upgrades, design ADRs
- **Phase 2:** Security & API - Authentication, authorization, audit logging
- **Phase 3:** Observability & Testing - Structured logging, metrics, E2E tests
- **Phase 4:** Advanced - Advanced features, scalability optimizations

---

*This documentation is maintained as part of the JIntent governance and architectural decision-making process.*
