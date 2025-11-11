# ADR-003: CI/CD Architecture

**Status:** Proposed  
**Date:** 2025-10-15  
**Deciders:** Project Maintainers, Community  
**Context:** Phase 1 Foundation - Automation & Delivery  
**Related:** [ADR-000](./ADR-000-context-and-high-level-decisions.md)

---

## 1. Status

**Current Status:** Proposed  
**Approval Status:** Pending Stakeholder Review

This ADR defines the CI/CD architecture, automation strategy, and deployment pipeline for JIntent to ensure quality, consistency, and reliable releases.

---

## 2. Context

### 2.1 Background

**Current State (v2.1.0):**
- No CI/CD pipeline configured
- Manual testing before releases
- Manual version bumps and publishing
- No automated checks on PRs
- No dependency scanning

**Repository:**
- Platform: GitHub (GenSoftMX/JIntent)
- Branches: main (production)
- PRs: Manual review only
- Releases: Manual pub.dev publishing

### 2.2 Problem Statement

**Current Challenges:**
- Human error in releases (version mismatches, missing CHANGELOG)
- No automated quality gates
- Slow feedback on PRs
- Inconsistent testing
- No security scanning

**Business Impact:**
- Risk of broken releases
- Slow contribution feedback
- Manual overhead for maintainers
- Reduced contributor confidence

---

## 3. Decision

### 3.1 CI/CD Platform

**Decision:** Use GitHub Actions as primary CI/CD platform

**Rationale:**
- Native GitHub integration
- Free for public repositories
- Mature Flutter support
- YAML-based configuration
- Large marketplace of actions

**Alternatives Considered:**
- CircleCI, Travis CI: Additional account, cost
- GitLab CI: Would require migration
- Jenkins: Self-hosted overhead

**Status:** Selected - GitHub Actions

### 3.2 Pipeline Architecture

**Decision:** Implement multi-stage pipeline

```
┌─────────────┐
│   PR/Push   │
└──────┬──────┘
       │
       ├─► Lint          (Fast feedback)
       ├─► Format Check  (Code style)
       ├─► Analyze       (Static analysis)
       ├─► Test          (Unit tests)
       ├─► Coverage      (Report coverage)
       ├─► Security Scan (Dependency check)
       └─► Build Example (Verify compilation)
              │
              ▼
       ┌─────────────┐
       │   All Pass  │ ──► Merge Allowed
       └─────────────┘
```

**Stages:**

**1. Code Quality (Fast - ~2 min)**
- Lint: `flutter analyze`
- Format: `dart format --set-exit-if-changed`
- Analyze: custom lint rules

**2. Testing (Medium - ~5 min)**
- Unit tests: `flutter test`
- Coverage: `flutter test --coverage`
- Report: Upload to Codecov

**3. Security (Fast - ~1 min)**
- Dependency scan: `dart pub outdated`
- Vulnerability check: GitHub Dependabot

**4. Build Verification (Medium - ~3 min)**
- Example app: `cd example && flutter build apk --debug`
- Ensures code compiles

**Total Time:** ~10 minutes per PR

### 3.3 Workflow Definitions

**Decision:** Create specific workflows for different triggers

**1. PR Workflow (`.github/workflows/pr.yml`)**

```yaml
name: PR Checks
on:
  pull_request:
    branches: [main]
    
jobs:
  quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.x'
          channel: 'stable'
      - run: flutter pub get
      - run: dart format --set-exit-if-changed .
      - run: flutter analyze
      
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter test --coverage
      - uses: codecov/codecov-action@v3
        with:
          file: coverage/lcov.info
          
  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: dart pub outdated --mode=null-safety
      
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: cd example && flutter build apk --debug
```

**2. Main Branch Workflow (`.github/workflows/main.yml`)**

Similar to PR but with:
- Badge generation
- Documentation deployment
- Notification on failure

**3. Release Workflow (`.github/workflows/release.yml`)**

```yaml
name: Release
on:
  push:
    tags:
      - 'v*'
      
jobs:
  publish:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter test
      - run: flutter pub publish --dry-run
      # Manual approval gate
      # - run: flutter pub publish --force (future automation)
      - name: Create GitHub Release
        uses: actions/create-release@v1
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          tag_name: ${{ github.ref }}
          release_name: Release ${{ github.ref }}
          body: See CHANGELOG.md for details
```

**4. Nightly Workflow (`.github/workflows/nightly.yml`)**

```yaml
name: Nightly Tests
on:
  schedule:
    - cron: '0 2 * * *'  # 2 AM UTC daily
    
jobs:
  extended_tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter test --coverage
      - run: cd example && flutter test integration_test/
      # Future: performance benchmarks
```

### 3.4 Quality Gates

**Decision:** Define mandatory checks for merging

**PR Merge Requirements:**
1. ✅ All CI checks pass
2. ✅ At least 1 approving review
3. ✅ Branch up-to-date with main
4. ✅ No merge conflicts
5. ✅ Coverage not decreased (future)

**Configuration:** Branch protection rules in GitHub

### 3.5 Dependency Management

**Decision:** Automate dependency updates with controls

**Tool:** GitHub Dependabot

**Configuration (`.github/dependabot.yml`):**
```yaml
version: 2
updates:
  - package-ecosystem: "pub"
    directory: "/"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 5
    reviewers:
      - "project-maintainers"
    labels:
      - "dependencies"
    commit-message:
      prefix: "chore"
      include: "scope"
    # Group minor/patch updates
    groups:
      minor-and-patch:
        patterns:
          - "*"
        update-types:
          - "minor"
          - "patch"
```

**Process:**
1. Dependabot creates PR weekly
2. CI runs tests automatically
3. Maintainer reviews and merges
4. Breaking updates get manual review

### 3.6 Release Automation

**Decision:** Semi-automated releases with manual gate

**Release Process:**

**Phase 1 (Current - Manual):**
1. Update version in `pubspec.yaml`
2. Update `CHANGELOG.md`
3. Commit: `build: release v2.2.0`
4. Create tag: `git tag v2.2.0`
5. Push: `git push --tags`
6. CI runs tests
7. Manual: `flutter pub publish`
8. Create GitHub release

**Phase 2 (Semi-Automated):**
1. Maintainer creates tag: `v2.2.0`
2. CI workflow triggers
3. Runs full test suite
4. Creates draft GitHub release
5. Manual approval + publish to pub.dev
6. Auto-publish GitHub release

**Phase 3 (Fully Automated):**
1. Conventional Commits determine version bump
2. CI creates tag automatically
3. Publishes to pub.dev (with credentials)
4. Creates GitHub release
5. Announces on social media

**Current Status:** Phase 1 (moving to Phase 2)

### 3.7 Artifact Management

**Decision:** Store and manage build artifacts

**Artifacts to Store:**
- Test coverage reports
- Build logs
- APK files (example app)
- Documentation (dartdoc HTML)

**Retention:**
- PR artifacts: 7 days
- Main branch: 30 days
- Release artifacts: Permanent

**Configuration:**
```yaml
- name: Upload coverage
  uses: actions/upload-artifact@v3
  with:
    name: coverage-report
    path: coverage/
    retention-days: 30
```

### 3.8 Notifications

**Decision:** Configure notifications for key events

**Channels:**
- GitHub PR comments (automated)
- Email (for maintainers on failure)
- Future: Slack/Discord for releases

**Events:**
- CI failure on main branch (email)
- New release (GitHub release + social)
- Security vulnerabilities (email + GitHub)
- Coverage drop >5% (PR comment)

### 3.9 Environment Configuration

**Decision:** Manage environment-specific settings

**Environments:**
- Development: PR branches
- Staging: N/A (library, not app)
- Production: main branch

**Secrets Management:**
```yaml
secrets:
  CODECOV_TOKEN: ${{ secrets.CODECOV_TOKEN }}
  PUB_DEV_TOKEN: ${{ secrets.PUB_DEV_TOKEN }}  # Future
```

**Configuration:**
- Store in GitHub Secrets
- Rotate quarterly
- Minimal permissions

---

## 4. Consequences

### 4.1 Positive Consequences

✅ **Quality Assurance**
- Automated testing prevents regressions
- Consistent checks on every PR
- Early bug detection

✅ **Developer Experience**
- Fast feedback on PRs (~10 min)
- Reduced manual testing
- Clear merge criteria

✅ **Security**
- Automated vulnerability scanning
- Dependency updates
- Audit trail

✅ **Reliability**
- Repeatable release process
- Version consistency
- Reduced human error

### 4.2 Negative Consequences

⚠️ **Initial Setup Effort**
- Time to configure workflows
- Learning GitHub Actions
- Debugging CI issues

⚠️ **Maintenance Overhead**
- Keep workflows updated
- Manage secrets
- Monitor CI costs (none for public repo)

⚠️ **False Positives**
- Flaky tests can block PRs
- Tool updates can break CI
- Network issues cause failures

### 4.3 Mitigation Strategies

**For Setup Effort:**
- Start with basic workflow
- Iterate incrementally
- Use community actions

**For Maintenance:**
- Quarterly CI review
- Document workflow purposes
- Automated workflow updates (Dependabot)

**For False Positives:**
- Retry failed jobs automatically
- Isolated test environments
- Monitor flakiness metrics

---

## 5. Implementation Plan

### Phase 1: Foundation (Week 1-2)
- [x] Create ADR-003
- [ ] Create basic PR workflow (lint, format, test)
- [ ] Configure branch protection
- [ ] Add Codecov integration
- [ ] Test with sample PR

### Phase 2: Enhancement (Week 3-4)
- [ ] Add security scanning (Dependabot)
- [ ] Create release workflow
- [ ] Add build verification
- [ ] Configure notifications

### Phase 3: Optimization (Week 5+)
- [ ] Add caching for dependencies
- [ ] Parallel job execution
- [ ] Coverage gates
- [ ] Performance benchmarks

---

## 6. Examples

### Example 1: Basic PR Workflow File

File: `.github/workflows/pr.yml`

```yaml
name: PR Checks

on:
  pull_request:
    branches: [main]

jobs:
  analyze:
    name: Analyze & Format
    runs-on: ubuntu-latest
    timeout-minutes: 10
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
        
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.x'
          channel: 'stable'
          cache: true
          
      - name: Install dependencies
        run: flutter pub get
        
      - name: Verify formatting
        run: dart format --output=none --set-exit-if-changed .
        
      - name: Analyze code
        run: flutter analyze --fatal-infos
        
  test:
    name: Test with Coverage
    runs-on: ubuntu-latest
    timeout-minutes: 15
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
        
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.x'
          channel: 'stable'
          cache: true
          
      - name: Install dependencies
        run: flutter pub get
        
      - name: Run tests
        run: flutter test --coverage --reporter=expanded
        
      - name: Upload coverage
        uses: codecov/codecov-action@v4
        with:
          files: ./coverage/lcov.info
          flags: unittests
          name: jintent-coverage
          fail_ci_if_error: false
          
  build:
    name: Build Example
    runs-on: ubuntu-latest
    timeout-minutes: 15
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
        
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.x'
          channel: 'stable'
          cache: true
          
      - name: Install dependencies
        run: |
          flutter pub get
          cd example && flutter pub get
          
      - name: Build example APK
        run: cd example && flutter build apk --debug
        
      - name: Upload APK artifact
        uses: actions/upload-artifact@v3
        with:
          name: example-debug-apk
          path: example/build/app/outputs/flutter-apk/app-debug.apk
          retention-days: 7
```

### Example 2: Dependabot Configuration

File: `.github/dependabot.yml`

```yaml
version: 2
updates:
  # Main package dependencies
  - package-ecosystem: "pub"
    directory: "/"
    schedule:
      interval: "weekly"
      day: "monday"
      time: "09:00"
    open-pull-requests-limit: 3
    reviewers:
      - "GenSoftMX"
    labels:
      - "dependencies"
      - "automated"
    commit-message:
      prefix: "chore"
      include: "scope"
      
  # Example app dependencies
  - package-ecosystem: "pub"
    directory: "/example"
    schedule:
      interval: "monthly"
    open-pull-requests-limit: 2
    labels:
      - "dependencies"
      - "example"
```

### Example 3: Branch Protection Rules

GitHub Settings → Branches → Add rule

```
Branch name pattern: main

✅ Require a pull request before merging
  ✅ Require approvals: 1
  ✅ Dismiss stale PR approvals when new commits are pushed
  ✅ Require review from Code Owners

✅ Require status checks to pass before merging
  ✅ Require branches to be up to date before merging
  Status checks that are required:
    - Analyze & Format
    - Test with Coverage
    - Build Example

✅ Require conversation resolution before merging

✅ Require linear history

✅ Do not allow bypassing the above settings
```

---

## 7. Alternatives Considered

### Alternative 1: No CI/CD

**Approach:** Continue manual testing and releases

**Pros:**
- No setup time
- No CI complexity
- Full manual control

**Cons:**
- Human error prone
- Slow feedback
- Inconsistent quality
- Not scalable

**Decision:** Rejected - Unacceptable for professional library

### Alternative 2: Self-Hosted CI (Jenkins)

**Approach:** Run own Jenkins server

**Pros:**
- Full control
- No vendor lock-in
- Custom plugins

**Cons:**
- Infrastructure cost
- Maintenance burden
- Security responsibility
- Slower setup

**Decision:** Rejected - Overkill for project size

### Alternative 3: Multiple CI Platforms

**Approach:** Use Travis + CircleCI + GitHub Actions

**Pros:**
- Redundancy
- Different perspectives
- More platforms tested

**Cons:**
- Configuration duplication
- Higher complexity
- Conflicting results
- Maintenance nightmare

**Decision:** Rejected - Single source of truth better

---

## 8. Risks

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| CI failures block development | High | Medium | Retry mechanism, quick fixes |
| Flaky tests | Medium | Medium | Test isolation, monitoring |
| GitHub Actions outage | Medium | Low | Manual release process backup |
| Secret leakage | High | Low | Minimal permissions, rotation |
| Cost explosion | Low | Low | Public repo = free |

---

## 9. Open Questions

### Q1: Multi-Platform Testing?

**Question:** Should CI test on Windows/macOS runners?

**Answer:** Phase 1: Linux only. Phase 2: Add macOS for iOS verification.

**Cost:** ~$0.08/min for macOS (public repos still free)

### Q2: Auto-Merge Dependabot PRs?

**Question:** Should minor dependency updates auto-merge?

**Answer:** No - always require manual review for supply chain security.

### Q3: Preview Deployments?

**Question:** Deploy dartdoc previews for PRs?

**Answer:** Phase 2 - useful but not critical initially.

---

## 10. References

### Internal Documents
- [ADR-000: Context and High-Level Decisions](./ADR-000-context-and-high-level-decisions.md)
- [ADR-002: Testing Strategy](./ADR-002-testing-strategy.md) - Test execution
- [Repository Analysis](../REPOSITORY_ANALYSIS.md) - Section 10 CI/CD

### External Resources
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Flutter CI Best Practices](https://docs.flutter.dev/deployment/cd)
- [Dependabot Configuration](https://docs.github.com/en/code-security/dependabot)
- [Branch Protection Rules](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches)

### Related ADRs
- ADR-002: Testing Strategy (what to test)
- ADR-005: Security Architecture (security scanning)
- ADR-001: API Design (release process)

---

## 11. Approval & Sign-Off

### Reviewers

| Role | Name | Status | Date |
|------|------|--------|------|
| Project Lead | TodoFlutter.com | Pending | - |
| Technical Lead | TBD | Pending | - |
| Community | Open | Pending | - |

### Approval Criteria

- [ ] CI/CD platform selected
- [ ] Pipeline stages defined
- [ ] Workflows documented
- [ ] Quality gates specified
- [ ] Release process clarified
- [ ] Implementation plan provided

### Next Steps After Approval

1. Mark ADR-003 as **Accepted**
2. Create `.github/workflows/` directory
3. Implement basic PR workflow
4. Configure branch protection
5. Test with sample PR
6. Add Dependabot configuration
7. Document CI/CD in README

---

**Document Status:** Proposed  
**Version:** 1.0  
**Last Updated:** 2025-10-15  
**Next Review:** After stakeholder approval

---

*This ADR establishes CI/CD architecture for JIntent. It builds upon the foundation set in ADR-000 and complements ADR-002 (Testing Strategy).*
