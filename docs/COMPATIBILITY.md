# Compatibility Matrix

**Last Updated:** 2025-10-15  
**Current Version:** 2.1.0

---

## Supported Platforms

JIntent is a **pure Dart package** with no platform-specific code. It supports all Flutter platforms:

| Platform | Status | Notes |
|----------|--------|-------|
| ✅ Android | Fully Supported | Tested on Android 21+ |
| ✅ iOS | Fully Supported | Tested on iOS 12+ |
| ✅ Web | Fully Supported | Works with all modern browsers |
| ✅ Linux | Fully Supported | Desktop application support |
| ✅ macOS | Fully Supported | Desktop application support |
| ✅ Windows | Fully Supported | Desktop application support |

---

## Dart & Flutter SDK Requirements

### Minimum Requirements

| SDK | Minimum Version | Recommended |
|-----|----------------|-------------|
| **Dart** | 3.7.2 | Latest stable |
| **Flutter** | 1.17.0 | Latest stable |

### Tested Flutter Versions

JIntent is tested against the following Flutter versions in CI/CD:

| Version | Status | Support Level |
|---------|--------|---------------|
| **3.27.x** (latest stable) | ✅ Tested | Full support |
| **3.24.x** (N-1) | ✅ Tested | Full support |
| **3.19.x** (N-2) | ✅ Tested | Full support |

**Note:** While JIntent may work on older Flutter versions, we only officially support and test the latest 3 stable releases.

---

## Dependency Compatibility

### Direct Dependencies

| Package | Version Constraint | Status |
|---------|-------------------|--------|
| flutter | sdk: flutter | Core dependency |
| equatable | ^2.0.5 | Stable |
| state_notifier | ^1.0.0 | Stable |

### Dev Dependencies

| Package | Version Constraint | Purpose |
|---------|-------------------|---------|
| flutter_test | sdk: flutter | Testing framework |
| test | ^1.21.0 | Testing utilities |
| mockito | ^5.4.0 | Mocking (tests) |
| mocktail | ^1.0.4 | Alternative mocking |
| build_runner | ^2.4.7 | Code generation |
| flutter_lints | ^2.0.0 | Linting rules |

**Security:** All dependencies are regularly audited for vulnerabilities. Enable Dependabot alerts in your repository to stay informed.

---

## Breaking Changes & Migration

### Version 2.x (Current)

**Released:** June 2024  
**Breaking Changes from 1.x:**
- Removed `get_it` dependency (users must provide own DI)
- Changed side effect API method names
- Updated import paths

**Migration Guide:** See [CHANGELOG.md](../CHANGELOG.md) for detailed migration instructions.

### Version 1.x (Legacy)

**Support Status:** Security patches only until December 2024  
**Recommendation:** Upgrade to 2.x for continued support

---

## Null Safety

✅ JIntent is **fully null-safe** since version 2.0.0

- Requires Dart 3.x (null safety enforced)
- No support for legacy Dart 2.x versions
- All APIs are null-safe by default

---

## Performance Targets

### Documented Benchmarks (SLOs)

| Metric | Target | Measured | Status |
|--------|--------|----------|--------|
| Intent Dispatch | <10ms (p95) | TBD | ⏳ Phase 2 |
| Effect Emission | <5ms overhead (p95) | TBD | ⏳ Phase 2 |
| State Transition | <1ms per transition | TBD | ⏳ Phase 2 |
| Memory Overhead | <50KB per controller | TBD | ⏳ Phase 2 |

**Note:** Performance benchmarks will be added in Phase 2 as part of the observability improvements.

---

## Known Limitations

### Platform-Specific Considerations

1. **Web:**
   - Memory management differs from native platforms
   - Consider effect stream cleanup in single-page apps

2. **Desktop:**
   - No specific limitations
   - Full feature parity with mobile

3. **Mobile (iOS/Android):**
   - No specific limitations
   - Background processing constraints apply (OS-level, not JIntent-specific)

### Flutter Version Specific

- **Flutter 1.17.0-3.0.0:** Minimum support, limited testing
- **Flutter 3.0.0+:** Full feature support and regular testing

---

## Deprecation Policy

### API Deprecation Lifecycle

1. **Announce:** Mark API with `@deprecated` annotation with migration instructions
2. **Support:** Maintain deprecated API for at least 1 minor version cycle
3. **Remove:** Remove in next major version with migration guide

### Example Timeline

```
v2.1.0: API XYZ marked @deprecated
v2.2.0: API XYZ still available (with warning)
v3.0.0: API XYZ removed (breaking change)
```

---

## Compatibility Testing

### CI/CD Test Matrix

```yaml
Flutter Versions: [stable, stable-1, stable-2]
Platforms: [Linux, Web]
Dart SDK: [3.7.2+]
```

### How to Test Your App

To ensure compatibility with JIntent in your application:

1. **Pin Version:**
   ```yaml
   dependencies:
     jintent: ^2.1.0  # Use caret for automatic minor/patch updates
   ```

2. **Test on Target Platforms:**
   ```bash
   flutter test
   flutter test integration_test/  # If you have integration tests
   ```

3. **Check Dependencies:**
   ```bash
   dart pub outdated
   dart pub audit  # Check for security vulnerabilities
   ```

---

## Support Timeline

| Version | Release Date | End of Support | Status |
|---------|-------------|----------------|--------|
| 2.1.x | 2025-08-09 | Current | ✅ Active |
| 2.0.x | 2024-06-10 | Current | ✅ Active |
| 1.0.x | 2024-04-28 | 2024-12-10 | ⚠️ Security Only |
| <1.0 | - | End of Life | ❌ Unsupported |

**Active Support:** Bug fixes, security patches, new features  
**Security Only:** Critical security patches only  
**End of Life:** No updates, community support only

---

## Upgrade Recommendations

### When to Upgrade

✅ **Upgrade Immediately:**
- Security vulnerability in current version
- Critical bug affecting your use case
- Need new features only available in newer versions

⚠️ **Upgrade with Caution:**
- Major version changes (test thoroughly)
- Active development sprint (wait for stable sprint)

🕒 **Upgrade at Convenience:**
- Minor version updates (backward compatible)
- Patch releases (bug fixes only)

### Upgrade Process

1. **Read CHANGELOG.md** for breaking changes and new features
2. **Update pubspec.yaml** with new version
3. **Run tests** to catch any regressions
4. **Review deprecation warnings** and update code
5. **Test on all target platforms**

---

## Community & Support

### Getting Help

- **Issues:** [GitHub Issues](https://github.com/GenSoftMX/JIntent/issues)
- **Discussions:** [GitHub Discussions](https://github.com/GenSoftMX/JIntent/discussions)
- **Security:** See [SECURITY.md](../SECURITY.md)

### Contributing

See [CONTRIBUTING.md](../README.md#contributing-guidelines) for guidelines on:
- Reporting bugs
- Proposing features
- Submitting pull requests

---

## References

- [Semantic Versioning](https://semver.org/)
- [Flutter Release Process](https://github.com/flutter/flutter/wiki/Release-process)
- [Dart Versioning Guide](https://dart.dev/tools/pub/versioning)
- [ADR-008: Compatibility and Platform Support](./adr/ADR-008-compatibility-and-platform-support.md)
- [ADR-009: Semantic Versioning and Release Strategy](./adr/ADR-009-semantic-versioning-release.md)

---

**Questions?** Open a [GitHub Discussion](https://github.com/GenSoftMX/JIntent/discussions)
