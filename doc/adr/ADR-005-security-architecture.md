# ADR-005: Security Architecture

**Status:** Proposed  
**Date:** 2025-10-15  
**Deciders:** Project Maintainers, Community  
**Context:** Phase 2 Security & API - Security Baseline  
**Related:** [ADR-000](./ADR-000-context-and-high-level-decisions.md)

---

## 1. Status

**Current Status:** Proposed  
**Approval Status:** Pending Stakeholder Review

This ADR defines the security architecture, baseline controls, OWASP ASVS mapping, and security practices for JIntent to ensure secure usage and trustworthy library development.

---

## 2. Context

### 2.1 Background

**Current Security State (v2.1.0):**

**Baseline:**
- ❌ No security controls documented
- ❌ No OWASP ASVS assessment performed
- ❌ No vulnerability scanning configured
- ❌ No security testing
- ❌ No secure coding guidelines

**Dependencies:**
- Only 3 production dependencies (low surface area)
- All from trusted sources (pub.dev official)
- No known vulnerabilities (not scanned)

**Library Context:**
JIntent is a state management library, not a complete application. Security concerns are primarily:
1. Supply chain security (dependencies)
2. Input validation (developer-facing APIs)
3. Information disclosure (logging, errors)
4. Secure usage guidance for consumers

### 2.2 Problem Statement

**Current Challenges:**
- No security baseline established
- Unknown OWASP ASVS compliance level
- No guidance for secure usage
- No vulnerability disclosure process
- No security response plan

**Business Impact:**
- Reduced trust from enterprise users
- Potential security issues undiscovered
- No clear security posture
- Risk of supply chain attacks

---

## 3. Decision

### 3.1 Security Framework

**Decision:** Adopt OWASP ASVS Level 2 as baseline framework

**OWASP Application Security Verification Standard (ASVS):**
- **Level 1:** Opportunistic (basic security)
- **Level 2:** Standard (most applications) ✅ Target
- **Level 3:** Advanced (high security applications)

**Rationale:**
- Level 2 appropriate for library used in production
- Industry-recognized standard
- Provides clear checklist
- Enables compliance verification

**Target Compliance:**
- Phase 1: Baseline assessment (0% → 50%)
- Phase 2: Implementation (50% → 70%)
- Phase 3: Certification-ready (70% → 85%)
- Phase 4: Full compliance (85% → 95%)

### 3.2 Security Domains (ASVS)

**Decision:** Map security controls to ASVS domains

**Applicable Domains for JIntent:**

**V1: Architecture, Design and Threat Modeling**
- ✅ Architecture documentation (ADR-000)
- ✅ Security stored in repo (this ADR)
- ⚠️ Threat model (to be created)

**V2: Authentication** - N/A (Library, not app)

**V3: Session Management** - N/A (Library, not app)

**V4: Access Control** - N/A (Library, not app)

**V5: Validation, Sanitization and Encoding**
- ⚠️ Input validation on developer APIs
- ✅ Type safety (Dart strong typing)
- ⚠️ Validation guidance for consumers

**V6: Stored Cryptography** - N/A (No crypto)

**V7: Error Handling and Logging**
- ⚠️ Error messages don't leak sensitive info
- ⚠️ Logging guidance (see ADR-008)
- ⚠️ Unhandled exception strategy

**V8: Data Protection** - Minimal (Library context)
- ✅ Immutable state (prevents mutation)
- ⚠️ Guidance on sensitive data handling

**V9: Communication** - N/A (No network layer)

**V10: Malicious Code**
- ⚠️ Code review process
- ⚠️ Dependency scanning
- ⚠️ Supply chain security

**V11: Business Logic**
- ✅ Sequential intent processing (no race conditions)
- ✅ Type-safe state management

**V12: Files and Resources** - N/A (No file I/O)

**V13: API and Web Service**
- ⚠️ Public API security review
- ⚠️ Version management (ADR-001)

**V14: Configuration** - Minimal
- ⚠️ JEffectsConfig security implications

**Legend:**
- ✅ Implemented
- ⚠️ Partial / To be addressed
- ❌ Not implemented
- N/A: Not applicable

### 3.3 Supply Chain Security

**Decision:** Implement supply chain security controls

**Controls:**

**1. Dependency Scanning**
- Tool: GitHub Dependabot (ADR-003)
- Frequency: Daily
- Action: Auto-PR for patches, manual review for major

**2. Dependency Pinning**
```yaml
# pubspec.yaml
dependencies:
  equatable: ^2.0.5    # Allow patch updates
  state_notifier: ^1.0.0
  
dev_dependencies:
  flutter_lints: ^2.0.0
  mockito: ^5.4.0
```

**3. Dependency Audit**
- Review all dependencies quarterly
- Check for:
  - Known vulnerabilities (CVEs)
  - Maintenance status (last update)
  - Trustworthiness (author, downloads)
  - License compatibility

**4. SBOM (Software Bill of Materials)**
- Generate: `flutter pub deps --json > sbom.json`
- Include in releases
- Track transitive dependencies

**5. Verified Commits**
- Maintainers use GPG-signed commits
- Verify: `git log --show-signature`

### 3.4 Input Validation

**Decision:** Validate all inputs at API boundaries

**Validation Points:**

**1. Controller Methods**
```dart
/// Emits a side effect and waits for completion.
///
/// Throws [ArgumentError] if [effect] is null or [timeout] is negative.
Future<T> emitAndWaitSideEffect<T>(
  JEffect<T> effect, {
  Duration timeout = const Duration(seconds: 30),
}) {
  ArgumentError.checkNotNull(effect, 'effect');
  if (timeout.isNegative) {
    throw ArgumentError.value(timeout, 'timeout', 'Must be non-negative');
  }
  // ... implementation
}
```

**2. State Updates**
```dart
/// Updates the state.
///
/// Throws [ArgumentError] if [newState] is null.
void setState(TState newState) {
  ArgumentError.checkNotNull(newState, 'newState');
  // ... implementation
}
```

**3. Configuration**
```dart
/// Configures effect handling behavior.
class JEffectsConfig {
  UnhandledEffectStrategy _unhandledStrategy = 
      UnhandledEffectStrategy.warnAndAutoComplete;
  
  /// Sets the unhandled effect strategy.
  ///
  /// Throws [ArgumentError] if [strategy] is null.
  set unhandledStrategy(UnhandledEffectStrategy strategy) {
    ArgumentError.checkNotNull(strategy, 'strategy');
    _unhandledStrategy = strategy;
  }
}
```

**Validation Principles:**
- Fail fast (at API boundary)
- Clear error messages
- Use Dart's type system (compile-time safety)
- Document validation rules

### 3.5 Error Handling Security

**Decision:** Prevent information disclosure in errors

**Guidelines:**

**1. Sanitize Error Messages (Library)**
```dart
// Bad: Exposes internal state
throw Exception('Failed to process intent: $intent with state $state');

// Good: Generic message
throw Exception('Intent processing failed');

// Better: Actionable message
throw ArgumentError('Intent must not be null');
```

**2. Logging Guidance (Consumers)**
```dart
// Guidance in docs/best-practices.md

// Bad: Log sensitive data
debugPrint('Login state: ${state.password}');  // DON'T

// Good: Log sanitized data
debugPrint('Login state: ${state.copyWith(password: "***")}');  // DO
```

**3. Effect Completion Errors**
```dart
// Don't expose internal details
effect.completeError(
  Exception('Operation failed'),  // Generic
  // Not: Exception('Database query failed: SELECT * FROM users')
);
```

### 3.6 Secure Usage Guidance

**Decision:** Document security best practices for consumers

**Documentation (doc/security.md):**

```markdown
# Security Best Practices

## Sensitive Data in State

### ❌ DON'T: Store sensitive data in plain text state
```dart
class LoginState extends JState {
  final String password;  // Plain text password - BAD
  LoginState({required this.password});
  
  @override
  List<Object?> get props => [password];  // Logged/debugged
}
```

### ✅ DO: Keep sensitive data out of state
```dart
class LoginState extends JState {
  final bool isAuthenticated;
  final String? userId;  // Reference, not password
  // Password only in memory during processing, never in state
}
```

## Logging

### ❌ DON'T: Log sensitive information
```dart
JObserver.onStateChanged = (prev, next, origin) {
  debugPrint('State: $next');  // May contain sensitive data
};
```

### ✅ DO: Sanitize before logging
```dart
JObserver.onStateChanged = (prev, next, origin) {
  debugPrint('State changed: ${next.runtimeType}');  // Generic
};

// Or use custom toString()
class LoginState extends JState {
  @override
  String toString() => 'LoginState(isAuthenticated: $isAuthenticated)';
  // Don't include password, token, etc.
}
```

## Side Effects

### ✅ DO: Use side effects for sensitive operations
```dart
// Navigation after authentication
emitSideEffect(NavigateToHomeEffect(userId: userId));

// NOT stored in state, consumed once, not logged
```

## Dependency Injection

### ✅ DO: Inject services, don't hardcode secrets
```dart
class UserController extends JController<UserState, UserIntent> {
  final ApiService _apiService;  // Injected
  
  UserController(this._apiService) : super(UserState.initial());
  
  // Don't: hardcode API keys, tokens
  // Do: Get from environment or secure storage
}
```
```

### 3.7 Vulnerability Disclosure

**Decision:** Establish security vulnerability reporting process

**Process:**

**Reporting:**
1. Email: security@todoflutter.com (create alias)
2. Private GitHub Security Advisory (preferred)
3. Do NOT open public issues for vulnerabilities

**Response Timeline:**
- Acknowledgment: 24 hours
- Initial assessment: 72 hours
- Fix timeline: Based on severity
  - Critical: 7 days
  - High: 14 days
  - Medium: 30 days
  - Low: 90 days

**Disclosure:**
1. Fix developed and tested
2. Release prepared
3. Coordinated disclosure (give users time to upgrade)
4. Public announcement after majority upgraded

**Credit:**
- Security researchers credited in CHANGELOG
- Hall of fame (future): docs/SECURITY_HALL_OF_FAME.md

**File: SECURITY.md**
```markdown
# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 2.1.x   | ✅ Yes             |
| 2.0.x   | ✅ Yes (until 3.0) |
| 1.x     | ❌ No              |

## Reporting a Vulnerability

If you discover a security vulnerability, please report it via:

1. **GitHub Security Advisory** (preferred):
   https://github.com/GenSoftMX/JIntent/security/advisories/new

2. **Email**: security@todoflutter.com

Please include:
- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

**Do NOT open public issues for vulnerabilities.**

## Response Timeline

- Acknowledgment: 24 hours
- Assessment: 72 hours
- Fix: Based on severity (7-90 days)

## Disclosure Policy

We follow coordinated disclosure:
1. Fix developed privately
2. Release deployed
3. Public announcement

## Security Updates

Security fixes are released as patch versions (e.g., 2.1.1).
Subscribe to releases for notifications.
```

### 3.8 Security Testing

**Decision:** Implement security testing in CI/CD

**Tests:**

**1. Dependency Scanning (ADR-003)**
```yaml
# .github/workflows/security.yml
name: Security Scan
on: [push, pull_request]

jobs:
  dependencies:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: dart pub outdated --mode=null-safety
      - run: dart pub audit  # Future tool
```

**2. Static Analysis**
```yaml
- name: Security Lints
  run: |
    flutter analyze --fatal-infos
    # Custom security lints (future)
```

**3. Secret Scanning**
- GitHub secret scanning (automatic)
- Prevent accidental commit of secrets

**4. SAST (Static Application Security Testing) - Future**
- Tool: CodeQL (GitHub)
- Scan for common vulnerabilities

### 3.9 Security Maintenance

**Decision:** Ongoing security maintenance process

**Activities:**

**Quarterly:**
- Review dependencies for vulnerabilities
- Update OWASP ASVS compliance checklist
- Review security documentation
- Test vulnerability reporting process

**Annually:**
- Full security audit (external if budget allows)
- Penetration testing (if applicable)
- Update threat model
- Security training for maintainers

**Continuous:**
- Monitor security advisories (GitHub, pub.dev)
- Respond to vulnerability reports
- Update SECURITY.md

---

## 4. Consequences

### 4.1 Positive Consequences

✅ **Trust & Credibility**
- Enterprise-ready security posture
- Clear vulnerability process
- Professional image

✅ **Risk Reduction**
- Proactive vulnerability detection
- Supply chain protection
- Information disclosure prevention

✅ **Compliance**
- OWASP ASVS Level 2 alignment
- Security audit readiness
- Clear security documentation

✅ **User Protection**
- Secure usage guidance
- Best practices documented
- Vulnerability notifications

### 4.2 Negative Consequences

⚠️ **Overhead**
- Quarterly security reviews
- Vulnerability response process
- Security testing in CI

⚠️ **False Positives**
- Dependency scanners can be noisy
- Manual triage required

⚠️ **Disclosure Complexity**
- Coordinating with reporters
- Balancing transparency and responsible disclosure

### 4.3 Mitigation Strategies

**For Overhead:**
- Automate scanning (Dependabot)
- Template response process
- Integrate into existing workflows

**For False Positives:**
- Whitelist known false positives
- Document triage process
- Community help with triage

**For Disclosure:**
- Clear SECURITY.md guidelines
- Template communications
- Use GitHub Security Advisories

---

## 5. Implementation Plan

### Phase 1: Baseline (Week 1-2)
- [x] Create ADR-005
- [ ] Create SECURITY.md
- [ ] Configure Dependabot (ADR-003)
- [ ] Initial OWASP ASVS assessment
- [ ] Document current security posture

### Phase 2: Implementation (Week 3-6)
- [ ] Add input validation to public APIs
- [ ] Create security best practices guide
- [ ] Set up vulnerability reporting email
- [ ] Add security tests to CI
- [ ] Implement SBOM generation

### Phase 3: Certification (Week 7+)
- [ ] Complete OWASP ASVS Level 2 checklist
- [ ] External security audit (if budget)
- [ ] Security badges in README
- [ ] Quarterly security reviews

---

## 6. Examples

### Example 1: Input Validation

```dart
/// Emits a side effect with timeout.
///
/// Throws [ArgumentError] if [effect] is null or [timeout] is invalid.
Future<T> emitAndWaitSideEffect<T>(
  JEffect<T> effect, {
  Duration timeout = const Duration(seconds: 30),
}) {
  // Input validation
  ArgumentError.checkNotNull(effect, 'effect');
  
  if (timeout.isNegative) {
    throw ArgumentError.value(
      timeout,
      'timeout',
      'Timeout must be non-negative',
    );
  }
  
  if (timeout > Duration(minutes: 5)) {
    // Warn about unreasonably long timeouts
    debugPrint('Warning: Effect timeout > 5 minutes may indicate a problem');
  }
  
  // ... implementation
}
```

### Example 2: Secure State Example

```dart
// ❌ Bad: Sensitive data in state
class UserState extends JState {
  final String apiKey;
  final String creditCard;
  
  @override
  List<Object?> get props => [apiKey, creditCard];  // Logged!
}

// ✅ Good: Sanitized state
class UserState extends JState {
  final bool isAuthenticated;
  final String? userId;  // Reference only
  
  @override
  List<Object?> get props => [isAuthenticated, userId];
  
  @override
  String toString() => 'UserState(authenticated: $isAuthenticated)';
}

// Secure storage handled separately:
// - Use flutter_secure_storage for sensitive data
// - Never store in JState
// - Use side effects for sensitive operations
```

### Example 3: OWASP ASVS Checklist (Excerpt)

```markdown
# OWASP ASVS Level 2 - JIntent Compliance

## V1: Architecture, Design and Threat Modeling

| ID | Requirement | Status | Notes |
|----|-------------|--------|-------|
| 1.1.1 | All application components are identified | ✅ | ADR-000 documents architecture |
| 1.1.2 | Security controls identified | ✅ | This ADR |
| 1.1.3 | Architecture diagrams exist | ⚠️ | Partial - needs threat model |
| 1.1.4 | All trust boundaries documented | ⚠️ | In progress |

## V5: Validation, Sanitization and Encoding

| ID | Requirement | Status | Notes |
|----|-------------|--------|-------|
| 5.1.1 | Input validation on untrusted data | ⚠️ | Implementing |
| 5.1.2 | Validation failures handled securely | ⚠️ | Implementing |
| 5.1.3 | Strong typing used | ✅ | Dart type system |

## V7: Error Handling and Logging

| ID | Requirement | Status | Notes |
|----|-------------|--------|-------|
| 7.1.1 | No sensitive data in logs | ⚠️ | Guidance needed |
| 7.1.2 | Error messages don't leak info | ⚠️ | Review needed |
| 7.2.1 | All exceptions logged | ✅ | JObserver pattern |

**Overall Compliance: 50%**
Target: 85% by Phase 3
```

---

## 7. Alternatives Considered

### Alternative 1: No Security Framework

**Approach:** Ad-hoc security measures

**Pros:**
- No overhead
- Flexibility

**Cons:**
- No standard
- Hard to verify
- Gaps unknown

**Decision:** Rejected - Framework provides structure

### Alternative 2: OWASP ASVS Level 3

**Approach:** Highest security level

**Pros:**
- Maximum security
- Best practices

**Cons:**
- Overkill for library
- Resource intensive
- Many N/A controls

**Decision:** Rejected - Level 2 more appropriate

### Alternative 3: ISO 27001

**Approach:** ISO security standard

**Pros:**
- International standard
- Comprehensive

**Cons:**
- Complex certification process
- Expensive
- Heavy process

**Decision:** Rejected - ASVS more agile and relevant

---

## 8. Risks

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Vulnerability discovered | High | Medium | Fast response process |
| Dependency compromise | High | Low | Supply chain controls |
| Information disclosure | Medium | Low | Sanitization guidelines |
| Non-compliance | Low | Medium | Regular audits |

---

## 9. Open Questions

### Q1: Third-Party Security Audit?

**Question:** Should we hire external security auditors?

**Answer:** Phase 3 - If budget allows, valuable for credibility.

### Q2: Bug Bounty Program?

**Question:** Offer rewards for vulnerability reports?

**Answer:** Phase 4 - Consider when library is widely adopted.

### Q3: Security Certification?

**Question:** Pursue formal security certification?

**Answer:** Deferred - ASVS compliance sufficient for now.

---

## 10. References

### Internal Documents
- [ADR-000: Context and High-Level Decisions](./ADR-000-context-and-high-level-decisions.md)
- [Repository Analysis](../REPOSITORY_ANALYSIS.md) - Section 3 Security Baseline
- [Executive Summary](../EXECUTIVE_SUMMARY.md) - Section 3 Security Gaps

### External Resources
- [OWASP ASVS 4.0](https://owasp.org/www-project-application-security-verification-standard/)
- [Supply Chain Levels for Software Artifacts (SLSA)](https://slsa.dev/)
- [Dependency Confusion](https://medium.com/@alex.birsan/dependency-confusion-4a5d60fec610)
- [GitHub Security Best Practices](https://docs.github.com/en/code-security)

### Related ADRs
- ADR-003: CI/CD Architecture (security scanning)
- ADR-006: Error Handling Patterns (information disclosure)
- ADR-008: Observability Strategy (secure logging)

---

## 11. Approval & Sign-Off

### Reviewers

| Role | Name | Status | Date |
|------|------|--------|------|
| Project Lead | TodoFlutter.com | Pending | - |
| Security Lead | TBD | Pending | - |
| Community | Open | Pending | - |

### Approval Criteria

- [ ] Security framework selected
- [ ] OWASP ASVS mapping completed
- [ ] Supply chain controls defined
- [ ] Vulnerability process documented
- [ ] Secure usage guidance provided
- [ ] Implementation plan outlined

### Next Steps After Approval

1. Mark ADR-005 as **Accepted**
2. Create SECURITY.md
3. Perform initial OWASP ASVS assessment
4. Configure Dependabot
5. Create security best practices guide
6. Set up vulnerability reporting

---

**Document Status:** Proposed  
**Version:** 1.0  
**Last Updated:** 2025-10-15  
**Next Review:** After stakeholder approval

---

*This ADR establishes security architecture and baseline controls for JIntent. It builds upon ADR-000 and prepares for Phase 2 security implementation.*
