# Task workflow

1. Review the request and Git status. Distinguish analysis from implementation.
2. Define goal, limits and success criteria. For minor documentation a brief
   scope is enough; for functional changes use the scope template fields, in the
   conversation or a file if it adds value.
3. For architecture, security, infrastructure, critical dependencies or
   cross-cutting refactors: present scope, plan and impact and confirm
   authorization before implementing. Resolve missing decisions without
   repeating valid approvals.
4. Discover nearby sources: applicable instructions, code, tests and contracts.
   Evaluate relevance, authority and currency; read the rules of the affected
   domain. Load Knowledge or ADRs only for a concrete question. For doubts about
   external APIs or versions, apply `../rules/documentation.md` and query
   Context7 when available.
5. Make the minimal authorized change. If scope must widen, report the cause and
   get authorization before doing it.
6. Apply the testing rules. On failure, diagnose before repairing and bound the
   attempts. Distinguish static verification, execution and native evidence.
7. Review the final diff and close with the result, key context used, files,
   validations run, blockers and pending risks. Do not invent metrics.
8. If work remains for another session, use the handoff template with the
   minimum necessary context and one concrete next step.

Dependencies, as scope requires: `../rules/architecture.md`,
`../rules/code-style.md`, `../rules/testing.md`, `../rules/git.md`.
