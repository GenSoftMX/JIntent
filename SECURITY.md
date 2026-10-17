# Security Policy

## Supported versions

Security fixes target the latest released minor version of JIntent. Older
versions may receive fixes at the maintainers' discretion.

## Reporting a vulnerability

**Do not open public GitHub issues for security vulnerabilities.**

1. **GitHub Security Advisory (preferred):**
   <https://github.com/GenSoftMX/JIntent/security/advisories/new>
2. **Email:** security@todoflutter.com, with "JIntent Security" in the subject.

Include a description, steps to reproduce, potential impact, affected versions
and a suggested fix if you have one.

We acknowledge reports within 3 business days and coordinate disclosure: the fix
is developed privately, released as a patch version, and announced in a GitHub
Security Advisory. Fix timelines depend on severity.

## Library boundary

JIntent manages application state and UI effects. It does not provide
authentication, authorization, encryption or secret storage; those belong to
the consuming application's services and platform integrations. It establishes
no OWASP compliance percentage or security certification.

When building with JIntent:

- Keep credentials and personal data out of state, intent metadata, logs and
  debug overlays.
- Treat validators as operation preconditions, not as server-side authorization.
- Present controlled feedback through effect handlers; log unexpected failures
  without showing raw exception details. See [error handling](doc/error-handling.md).
- Check lifecycle after asynchronous gaps; disposal does not cancel external work.
- Review dependency changes and the [CI checks](.github/workflows/ci.yml).
