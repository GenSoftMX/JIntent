# .github Directory

This directory contains GitHub-specific configuration files and templates for the JIntent repository.

## Contents

### Configuration Files

#### [LABELS.md](./LABELS.md)
Comprehensive label configuration for GitHub issues and PRs, including:
- Phase labels (phase-0 through phase-4)
- Gate labels (gate-a1, gate-a2, gate-b, gate-c)
- Priority labels (critical, high-priority, medium-priority, low-priority)
- Category labels (adr, ci-cd, testing, coverage, governance, etc.)
- Type labels (bug, feature, enhancement, refactor, chore)
- Status labels (blocked, in-progress, needs-review, etc.)
- Special labels (breaking-change, exception-change, etc.)

### Planned Files (Phase 1)

The following files will be created during Phase 1 execution:

#### Issue Templates (`.github/ISSUE_TEMPLATE/`)
- `bug_report.md` - Bug report template
- `feature_request.md` - Feature request template
- `security_vulnerability.md` - Security vulnerability template
- `documentation.md` - Documentation improvement template
- `exception_change.md` - Exception/error handling change template
- `config.yml` - Issue template chooser configuration

#### Workflows (`.github/workflows/`)
- `ci.yml` - Continuous Integration workflow
  - Runs tests on PR
  - Checks linting
  - Generates coverage reports
  - Enforces quality gates

#### Pull Request Template
- `PULL_REQUEST_TEMPLATE.md` - Standard PR template

#### Dependabot Configuration
- `dependabot.yml` - Dependency update automation

## Setup Instructions

### Creating Labels

Labels can be created manually via GitHub UI or using the GitHub CLI:

```bash
# See LABELS.md for the full script
cd /path/to/JIntent
bash create_labels.sh
```

### Issue Templates

Issue templates will be automatically available once created in `.github/ISSUE_TEMPLATE/`.

### Workflows

GitHub Actions workflows in `.github/workflows/` run automatically on configured events (e.g., PR, push to main).

## Maintenance

This directory is maintained by project maintainers. Changes to configurations should:
1. Be discussed in an issue first
2. Follow governance process (ADR if significant)
3. Be tested before merging

## References

- [GitHub Documentation](https://docs.github.com/en)
- [GitHub Actions](https://docs.github.com/en/actions)
- [Issue Templates](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests)
- [Dependabot](https://docs.github.com/en/code-security/dependabot)

---

**Last Updated:** 2025-10-15  
**Maintained By:** Project Maintainers
