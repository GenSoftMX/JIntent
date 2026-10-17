# Repository automation

- [CI](workflows/ci.yml): dependency resolution, formatting, analysis, tests and
  the configured coverage threshold.
- [Dependabot](dependabot.yml): dependency update configuration.

The workflow files define executable behavior. Check them before changing
validation instructions; the library and example require separate analysis.
See the [task workflow](../.agents/workflows/task.md).

## Labels

| Group | Labels |
| --- | --- |
| Type | `bug`, `feature`, `enhancement`, `refactor`, `chore`, `documentation` |
| Area | `ci-cd`, `testing`, `security`, `observability`, `performance`, `dependencies` |
| Priority | `critical`, `high-priority`, `medium-priority`, `low-priority` |
| Status | `blocked`, `in-progress`, `needs-review`, `needs-feedback` |
| Contributors | `help-wanted`, `good-first-issue` |
| Special | `breaking-change`, `wontfix`, `duplicate`, `invalid`, `question` |
