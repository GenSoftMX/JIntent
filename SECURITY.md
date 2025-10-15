# Security Policy

## Supported Versions

We release patches for security vulnerabilities in the following versions:

| Version | Supported          |
| ------- | ------------------ |
| 2.1.x   | :white_check_mark: |
| 2.0.x   | :white_check_mark: |
| < 2.0   | :x:                |

**Support Policy:**
- **Current Major Version (2.x):** Full support including security patches, bug fixes, and new features
- **Previous Major Version (1.x):** Security patches only for 6 months after 2.0.0 release (until 2024-12-10)
- **Older Versions:** Community support only, no official security patches

## Reporting a Vulnerability

We take the security of JIntent seriously. If you believe you have found a security vulnerability, please report it to us as described below.

### Where to Report

**Please DO NOT report security vulnerabilities through public GitHub issues.**

Instead, please report them via one of the following methods:

1. **GitHub Security Advisories (Preferred):**
   - Navigate to the [Security tab](https://github.com/GenSoftMX/JIntent/security)
   - Click "Report a vulnerability"
   - Fill out the form with details

2. **Email:**
   - Send an email to: **security@todoflutter.com**
   - Subject line: `[SECURITY] JIntent - [Brief Description]`

### What to Include

Please include the following information in your report:

- **Description:** Clear description of the vulnerability
- **Impact:** What kind of security issue is this? (e.g., authentication bypass, injection, DoS)
- **Affected Versions:** Which versions of JIntent are affected?
- **Steps to Reproduce:** Detailed steps to reproduce the vulnerability
- **Proof of Concept:** Code snippet or test case demonstrating the issue (if applicable)
- **Suggested Fix:** If you have ideas on how to fix it (optional)
- **Disclosure Timeline:** Your preferred disclosure timeline (we aim for 90 days)

### What to Expect

- **Initial Response:** Within 48 hours of your report, we will acknowledge receipt
- **Status Updates:** We will keep you informed of our progress every 5 business days
- **Validation:** Within 5 business days, we will validate the vulnerability and determine severity
- **Fix Timeline:**
  - **Critical/High:** Patch released within 7-14 days
  - **Medium:** Patch released within 30 days
  - **Low:** Patch released in next scheduled release
- **Credit:** We will credit you in the security advisory and CHANGELOG (unless you prefer to remain anonymous)
- **Coordinated Disclosure:** We will work with you on a coordinated public disclosure timeline

### Severity Classification

We use the [CVSS 3.1](https://www.first.org/cvss/calculator/3.1) scoring system:

| Severity | CVSS Score | Response Time | Examples |
|----------|------------|---------------|----------|
| **Critical** | 9.0-10.0 | 7 days | Remote code execution, auth bypass affecting all users |
| **High** | 7.0-8.9 | 14 days | Data exposure, privilege escalation, injection vulnerabilities |
| **Medium** | 4.0-6.9 | 30 days | Limited DoS, information disclosure with no sensitive data |
| **Low** | 0.1-3.9 | Next release | Minor information leakage, low-impact issues |

## Security Best Practices for JIntent Users

### General Recommendations

1. **Keep JIntent Updated:**
   - Always use the latest stable version
   - Subscribe to release notifications on GitHub
   - Review CHANGELOG.md for security-related updates

2. **Dependency Security:**
   - Regularly run `dart pub outdated` to check for outdated dependencies
   - Monitor GitHub Dependabot alerts
   - Enable automated dependency updates

3. **Input Validation:**
   - Always validate user input in your Use Cases before processing
   - Use the `Either<Exception, T>` pattern for explicit error handling
   - Never trust client-side validation alone

4. **Sensitive Data Handling:**
   - **Do not store sensitive data in JState** (passwords, tokens, PII)
   - Use secure storage solutions (flutter_secure_storage, encrypted databases)
   - Be cautious with logging and observability hooks (see below)

5. **Side Effect Security:**
   - Validate navigation targets to prevent open redirects
   - Sanitize data before displaying in dialogs/snackbars
   - Avoid passing sensitive data through side effects

### Logging and Observability

JIntent provides `JObserver` hooks for debugging and observability. **Be careful with these in production:**

❌ **Bad - Logs Sensitive Data:**
```dart
class LoggingObserver extends JObserver {
  @override
  void onIntentReceived(JIntent intent) {
    print('Intent: ${intent.toString()}'); // May contain sensitive data!
  }
}
```

✅ **Good - Logs Safely:**
```dart
class SafeLoggingObserver extends JObserver {
  @override
  void onIntentReceived(JIntent intent) {
    print('Intent type: ${intent.runtimeType}'); // Only logs type
  }
  
  @override
  void onError(Object error, StackTrace stackTrace) {
    // Send to error tracking service (sanitized)
    errorService.report(error, stackTrace, redactPII: true);
  }
}
```

**Recommendations:**
- Disable verbose logging in production builds
- Redact PII before logging
- Use error tracking services with PII filtering
- Review logs before enabling telemetry

### Secure Use Case Patterns

✅ **Good - Input Validation:**
```dart
class LoginUseCase extends JUseCase<LoginInput, User> {
  LoginUseCase() {
    addValidator((input) {
      if (input.email.isEmpty || !input.email.contains('@')) {
        return Left(ValidationException('Invalid email format'));
      }
      if (input.password.length < 8) {
        return Left(ValidationException('Password too short'));
      }
      return Right(input);
    });
  }

  @override
  Future<Either<Exception, User>> run(LoginInput input) async {
    // Input is pre-validated
    return authService.login(input.email, input.password);
  }
}
```

✅ **Good - Error Handling Without Data Leakage:**
```dart
// Don't include sensitive details in exceptions
if (authFailed) {
  return Left(AuthException('Authentication failed')); // Generic message
}

// Log details server-side, return generic error to client
```

## Known Security Limitations

### 1. JIntent is a Client-Side Library
- **No server-side security:** JIntent runs in the client app
- **Client data can be tampered with:** Never trust client state for authorization
- **Authentication must be server-side:** Use secure tokens, validate on backend

### 2. State Management is Local
- **No encryption:** JState is stored in memory unencrypted
- **Memory dumps:** Sensitive data in state could be extracted from memory
- **Solution:** Don't store sensitive data in state; use secure storage

### 3. Side Effects are Observable
- **Effect streams are not encrypted:** Anyone can observe effects
- **Navigation targets are visible:** Could leak information about app structure
- **Solution:** Don't pass sensitive data through effects

### 4. No Built-In Rate Limiting
- **Intent flooding:** Malicious code could flood controller with intents
- **DoS potential:** Resource exhaustion if intents trigger expensive operations
- **Solution:** Implement rate limiting in your controllers or use cases

## Security Roadmap

### Phase 1 (Completed)
- [x] Security policy established (this document)
- [x] Vulnerability reporting process defined
- [x] Security best practices documented

### Phase 2 (Planned)
- [ ] Automated dependency vulnerability scanning (Dependabot)
- [ ] Security-focused code review checklist
- [ ] Input validation guide with examples
- [ ] OWASP ASVS L1 compliance assessment

### Phase 3 (Future)
- [ ] Security-focused integration tests
- [ ] Penetration testing guidelines
- [ ] Security audit by third party
- [ ] Advanced secure patterns library

## Acknowledgments

We would like to thank the following security researchers for responsibly disclosing vulnerabilities:

- (None reported yet - be the first!)

## References

- [OWASP Top 10 Mobile](https://owasp.org/www-project-mobile-top-10/)
- [OWASP Mobile Application Security Verification Standard (MASVS)](https://github.com/OWASP/owasp-masvs)
- [Flutter Security Best Practices](https://flutter.dev/docs/deployment/security)
- [Dart Security Guidance](https://dart.dev/guides/security)

## Questions?

If you have questions about this security policy or JIntent security in general:
- Open a [GitHub Discussion](https://github.com/GenSoftMX/JIntent/discussions) (for general security questions)
- Email **security@todoflutter.com** (for sensitive security matters)

---

**Last Updated:** 2025-10-15  
**Version:** 1.0.0  
**Next Review:** 2025-04-15 (6 months)
