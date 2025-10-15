# Security Policy

## Supported Versions

We provide security updates for the following versions of JIntent:

| Version | Supported          |
| ------- | ------------------ |
| 2.1.x   | ✅ Yes             |
| 2.0.x   | ✅ Yes             |
| 1.x     | ❌ No              |

## Reporting a Vulnerability

If you discover a security vulnerability in JIntent, please report it responsibly:

### How to Report

**1. GitHub Security Advisory (Preferred)**
- Go to: https://github.com/GenSoftMX/JIntent/security/advisories/new
- Create a private security advisory
- Include all details listed below

**2. Email (Alternative)**
- Email: security@todoflutter.com
- Include "JIntent Security" in the subject line

### What to Include

Please provide:
- Description of the vulnerability
- Steps to reproduce
- Potential impact (confidentiality, integrity, availability)
- Affected versions
- Suggested fix (if you have one)

**⚠️ Do NOT open public GitHub issues for security vulnerabilities.**

## Response Timeline

We take security seriously and will respond as follows:

- **Acknowledgment:** Within 24 hours
- **Initial Assessment:** Within 72 hours (3 business days)
- **Fix Timeline:** Based on severity
  - **Critical:** 7 days
  - **High:** 14 days
  - **Medium:** 30 days
  - **Low:** 90 days

## Disclosure Policy

We follow coordinated disclosure:

1. **Private Fix:** We develop and test the fix privately
2. **Security Advisory:** We publish a GitHub Security Advisory
3. **Release:** We release a patched version
4. **Public Announcement:** We announce the fix after giving users time to upgrade

## Security Updates

Security fixes are released as **patch versions** (e.g., 2.1.1) and follow Semantic Versioning.

To receive security updates:
- Watch the repository and enable notifications
- Subscribe to releases on GitHub
- Follow the [CHANGELOG](./CHANGELOG.md)

## Security Best Practices

For developers using JIntent, we provide comprehensive security guidance:

- **[Security Guide](./docs/SECURITY_GUIDE.md)** - Complete security documentation
- **[Error Handling Guide](./docs/ERROR_HANDLING_GUIDE.md)** - Secure error handling patterns
- **[Validation Examples](./docs/examples/validation_examples.md)** - Input validation patterns

### Quick Security Checklist

When building with JIntent:
- ✅ Validate all user inputs using `UseCaseInputValidator`
- ✅ Never store sensitive data (passwords, tokens) in state
- ✅ Use `Either` pattern for expected errors
- ✅ Sanitize data before logging
- ✅ Keep dependencies up to date
- ✅ Follow the principle of least privilege

## Security Audit

JIntent targets **OWASP ASVS Level 2** compliance:
- Current compliance: **79%** (see [Security Guide](./docs/SECURITY_GUIDE.md))
- Target: **95%** by Phase 4

## Hall of Fame

We appreciate security researchers who help make JIntent safer. Acknowledged researchers:

- _(None yet - be the first!)_

Thank you for helping keep JIntent secure!

---

For more details, see our complete [Security Guide](./docs/SECURITY_GUIDE.md).
