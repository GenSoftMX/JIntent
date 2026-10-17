# Git and security

- Check status and diff before editing; preserve the user's existing changes.
- Do not discard files, rewrite history or run destructive cleanup without
  explicit authorization. Do not include files unrelated to the goal in commits.
- Create commits, publish, push or open PRs when the user requests it or it is
  part of the authorized scope; do not publish a version by inference.
- Do not introduce secrets, credentials, private data or personal paths into
  portable documentation. Avoid exposing them in logs or tool output.
- Changes to CI, permissions, security or critical dependencies require
  authorization covering that impact. Do not re-request an authorization
  already granted.
