# ADR-010: Publication Process and CI/CD Pipeline

**Status:** Proposed  
**Date:** 2025-10-15  
**Deciders:** JIntent Maintainers (GenSoftMX)  
**Supersedes:** None  
**Superseded by:** None

---

## Context

JIntent currently has **no CI/CD pipeline**. This creates several risks:
1. No automated testing before merging PRs
2. No quality gates preventing broken code from reaching main
3. Manual publication process is error-prone
4. No automated security scanning
5. Unknown test coverage

As we transition from Phase 0 to Phase 1, establishing a robust CI/CD pipeline is **critical priority** to ensure code quality, security, and reliable releases.

## Decision

### CI/CD Strategy Overview

**Platform:** GitHub Actions (free for public repositories, integrated with GitHub)

**Pipeline Structure:**
- **PR Pipeline:** Run on all pull requests (linting, testing, security checks)
- **Main Pipeline:** Run on merge to main (same as PR + coverage reporting)
- **Release Pipeline:** Run on version tags (publication to pub.dev)

---

## PR Pipeline (Continuous Integration)

**Trigger:** On pull request to `main` or `develop` branches

### Jobs

#### 1. Code Quality
```yaml
- Dart/Flutter version: stable, beta
- Run: dart format --set-exit-if-changed
- Run: flutter analyze
- Run: dart pub outdated --mode=null-safety
```

**Purpose:** Catch formatting issues, static analysis warnings, outdated dependencies

#### 2. Unit Tests
```yaml
- Dart/Flutter version: stable, stable-1, stable-2
- Run: flutter test
- Generate: coverage/lcov.info
```

**Purpose:** Ensure tests pass on supported Flutter versions (N, N-1, N-2 per ADR-008)

#### 3. Integration Tests (Example App)
```yaml
- Platforms: Linux (headless), Web (Chrome headless)
- Run: flutter test integration_test/
```

**Purpose:** Validate library works in real application context

#### 4. Security Scanning
```yaml
- Run: dart pub audit (when available)
- Check: Known vulnerabilities in dependencies
```

**Purpose:** Detect vulnerable dependencies before merge

#### 5. Coverage Report
```yaml
- Run: flutter test --coverage
- Upload: Codecov / Coveralls
- Enforce: ≥70% coverage (Phase 1 target)
```

**Purpose:** Track and enforce test coverage requirements

#### 6. Publish Dry-Run
```yaml
- Run: dart pub publish --dry-run
- Check: Package passes all pub.dev validation
```

**Purpose:** Catch publication issues early

**Required Checks:** All jobs must pass before merge

---

## Main Pipeline (Continuous Deployment)

**Trigger:** On push to `main` branch

### Jobs

All PR pipeline jobs **plus:**

#### 7. Documentation Build
```yaml
- Run: dart doc
- Deploy: GitHub Pages (optional)
```

**Purpose:** Keep API documentation up-to-date

#### 8. Coverage Tracking
```yaml
- Compare coverage delta vs. main
- Comment on PR if coverage decreased
- Publish coverage badge for README
```

**Purpose:** Maintain visibility on test coverage trends

---

## Release Pipeline (Publication)

**Trigger:** On tag matching `v*.*.*` (e.g., `v2.1.0`)

### Pre-Checks
```yaml
- Verify tag matches pubspec.yaml version
- Verify CHANGELOG.md has entry for version
- Run all CI checks (quality, tests, security)
```

### Publication Steps

#### 1. Create GitHub Release
```yaml
- Extract CHANGELOG excerpt for this version
- Create GitHub release with notes
- Attach any release artifacts (if applicable)
```

#### 2. Publish to pub.dev
```yaml
- Run: dart pub publish --force
- Requires: PUB_DEV_CREDENTIALS secret
```

**Credentials Management:**
- Store pub.dev token in GitHub Secrets
- Rotate token every 90 days
- Limit access to repository maintainers only

#### 3. Post-Publication Validation
```yaml
- Wait 2 minutes for pub.dev indexing
- Verify package appears in search
- Check pub.dev score (should be 160/160)
```

#### 4. Notifications
```yaml
- Post to Discord/Slack (if configured)
- Update project status dashboard
```

---

## Observability and Monitoring

### Metrics Collected

**Build Metrics:**
- Build duration (per job)
- Test execution time
- Flaky test detection (retry analysis)

**Code Metrics:**
- Test coverage % (line, branch)
- Number of lint warnings
- Cyclomatic complexity (optional)

**Security Metrics:**
- Known vulnerabilities count (high/critical)
- Dependency freshness score
- Security advisories addressed

### Alerting

**Critical Failures:**
- Main branch build failure → notify maintainers immediately
- Security vulnerability (critical/high) → create issue automatically
- Coverage drop >5% → block merge

**Warnings:**
- Beta Flutter version test failure → informational only
- Outdated dependencies → weekly digest

---

## Performance Targets (SLOs)

Based on issue requirements, document performance baselines:

### Intent Processing
- **Target:** <10ms per intent dispatch (95th percentile)
- **Measurement:** Benchmark tests in CI/CD
- **Alert:** If >20ms in performance regression tests

### Effect Emission
- **Target:** <5ms overhead per effect emission (95th percentile)
- **Measurement:** Benchmark tests in CI/CD
- **Alert:** If >10ms in performance regression tests

### Memory Usage
- **Target:** <50KB memory overhead for typical controller (10 intents/effects)
- **Measurement:** Memory profiling in integration tests
- **Alert:** If >100KB or memory leak detected

### State Transition
- **Target:** <1ms per state transition (immutable state update)
- **Measurement:** Benchmark tests
- **Alert:** If >5ms in regression tests

**Implementation:** Add performance benchmark suite in Phase 2

---

## CI/CD Configuration Example

### Minimal `.github/workflows/ci.yml`
```yaml
name: CI

on:
  pull_request:
    branches: [ main, develop ]
  push:
    branches: [ main ]

jobs:
  analyze:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: 'stable'
      - run: flutter pub get
      - run: dart format --set-exit-if-changed .
      - run: flutter analyze

  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        flutter-version: ['stable', '3.19.0', '3.16.0']
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: ${{ matrix.flutter-version }}
      - run: flutter pub get
      - run: flutter test --coverage
      - uses: codecov/codecov-action@v3
        if: matrix.flutter-version == 'stable'

  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: dart pub outdated --mode=null-safety
```

---

## Alternatives Considered

### Alternative 1: Travis CI / CircleCI
**Pros:** Mature CI platforms  
**Cons:** Additional external dependency, cost for private repos, less GitHub integration

### Alternative 2: Self-Hosted Runners
**Pros:** Full control, no usage limits  
**Cons:** Infrastructure maintenance burden, security concerns

### Alternative 3: Manual Testing Only
**Pros:** No setup effort  
**Cons:** High risk of regressions, no quality gates, slow feedback

### Alternative 4: Publish Pre-Release to Test Registry
**Pros:** Safe testing before production  
**Cons:** pub.dev doesn't have test registry, complicates workflow

## Consequences

### Positive
- Automated quality gates prevent broken code in main
- Fast feedback loop for contributors (<10 min CI time)
- Consistent, reliable release process
- Security vulnerabilities detected early
- Test coverage visibility drives quality improvements
- Reduced manual effort in releases

### Negative
- Initial setup effort (1-2 days)
- CI/CD costs (GitHub Actions free for public repos, but has usage limits)
- Flaky tests can block legitimate PRs (requires retry logic)
- Dependency on GitHub platform (vendor lock-in)

### Neutral
- Requires discipline to not bypass CI checks
- Maintainers must monitor build health
- Need fallback plan for GitHub Actions outages

---

## Implementation Plan

### Phase 1 (Week 1) - Critical Priority
- [x] Create `.github/workflows/ci.yml` (PR pipeline)
- [x] Configure Codecov / Coveralls integration
- [x] Add status badges to README.md
- [ ] Test PR pipeline with sample PR
- [ ] Document CI/CD in CONTRIBUTING.md

### Phase 1 (Week 2) - High Priority
- [ ] Create `.github/workflows/release.yml` (publication)
- [ ] Configure pub.dev credentials in GitHub Secrets
- [ ] Add security scanning (Dependabot, dart pub audit)
- [ ] Set up coverage enforcement (≥70%)

### Phase 2 - Quality Improvements
- [ ] Add integration tests for example app
- [ ] Create performance benchmark suite
- [ ] Add flaky test detection and retry logic
- [ ] Set up automated dependency updates

### Phase 3 - Advanced Features
- [ ] Matrix testing on all platforms (Linux, macOS, Windows)
- [ ] Automated release notes generation
- [ ] Community beta testing workflow
- [ ] Performance regression alerts

---

## Security Considerations

### Credentials Management
- **pub.dev token:** Store in GitHub Secrets, rotate every 90 days
- **Codecov token:** Store in GitHub Secrets
- **Access control:** Only repository maintainers can modify workflows

### Dependency Security
- Enable **Dependabot** for automated vulnerability scanning
- Configure **Dependabot Security Updates** for auto-PR on critical vulnerabilities
- Add `dart pub audit` to CI when available in Dart SDK

### Supply Chain Security
- Pin GitHub Actions versions with SHA (e.g., `actions/checkout@abc123`)
- Review all third-party actions before adding
- Enable **Branch Protection Rules:**
  - Require PR reviews before merge
  - Require status checks to pass
  - Require up-to-date branches
  - Restrict force push

---

## Monitoring and Maintenance

### Weekly Reviews
- Check CI build times (should be <10 minutes)
- Review flaky test reports
- Monitor dependency vulnerability alerts
- Check test coverage trends

### Monthly Reviews
- Review GitHub Actions usage (stay within free tier limits)
- Rotate pub.dev credentials
- Update Flutter versions in test matrix (follow ADR-008)
- Evaluate CI/CD effectiveness (blocked bugs, false positives)

### Quarterly Reviews
- Evaluate alternative CI/CD tools
- Review and update security policies
- Assess community contributions and CI/CD pain points

---

## References

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Publishing Packages to pub.dev](https://dart.dev/tools/pub/publishing)
- [Dependabot Configuration](https://docs.github.com/en/code-security/dependabot)
- [Codecov for Dart/Flutter](https://docs.codecov.com/docs/supported-languages#dart--flutter)
- [ADR-008: Compatibility and Platform Support](./ADR-008-compatibility-and-platform-support.md)
- [ADR-009: Semantic Versioning and Release Strategy](./ADR-009-semantic-versioning-release.md)

---

**Related ADRs:**
- ADR-000: Establishes guiding principles including "Testability by Design"
- ADR-008: Defines compatibility testing requirements (N, N-1, N-2 Flutter versions)
- ADR-009: Defines versioning strategy and release checklist
