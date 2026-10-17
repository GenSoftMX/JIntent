# Verification

- Documentation: review content, paths and `git diff --check`; Flutter need not
  run if no code or configuration changes.
- Code: run `dart format --output=none --set-exit-if-changed` on affected files,
  `flutter analyze` and relevant `flutter test` suites.
- Logic bugs: add a regression that reproduces the failure and checks the
  expected result. For async code, cover errors and relevant lifecycle; prefer
  deterministic synchronization over arbitrary waits.
- Before delivering library changes, run `flutter test --coverage`. CI currently
  checks repository formatting, analysis, tests and the global 80% threshold;
  check `.github/workflows/ci.yml` if it changes.
- Root analysis excludes `example/**`. A root result does not prove the example
  compiles or that a native platform works. Validate separately when relevant.
- Do not alter tests or lower gates to hide failures. Distinguish pre-existing
  failures from introduced ones; do not fix them out of scope.
- If an SDK, dependency or service is missing, report the blocker and the
  commands not run; do not install or update global tools without authorization.
- On failures: diagnose, repair within scope and verify again. After three
  attempts on the same cause, report the evidence and ask for the needed
  decision or information; do not repeat indefinitely.
- Do not claim coverage, compatibility or CI success without execution evidence.
