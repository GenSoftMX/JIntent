---
name: update-site
description: Keep the JIntent interactive guide (site/, English and Spanish) in sync after changing README.md, doc/, the ADRs, the example demos or the public API. Use whenever a documentation or demo change must reach the published site, or when adding a guide, demo page or translation.
---

# Update the interactive guide

Rules live in `.agents/rules/site.md`. The site is built by `site/` and published
by `.github/workflows/docs.yml`; the full workflow is described in
`site/README.md`. Run commands from `site/` unless stated.

## 1. Decide what changed

| Changed | Update |
| --- | --- |
| Prose in `README.md` (above `## Documentation`) or `doc/*.md` | `site/translations/es/<same path>` |
| `doc/adr/*.md` | `site/translations/es/doc/adr/<same file>` |
| New guide or ADR | Register it (step 3), translate it |
| Demo in `example/` (labels, behavior, route) | `src/content/docs/demos/<demo>.mdx` and `es/demos/<demo>.mdx` |
| New demo | New page in both languages + sidebar + route check |
| Public API, entry points, core flow | `concepts/architecture.mdx` and `es/concepts/architecture.mdx` |

Nothing to do for the English guides themselves: `npm run sync-docs` regenerates
them from the repository.

## 2. Update the Spanish translation

1. Open the English file and its mirror in `translations/es/`.
2. Translate prose only. Keep headings count, link targets and every fenced code
   block (comments included) identical to the English source.
3. Terminology: keep `intent`, `effect`, `dispatcher`, `handler`, `listener`,
   `timeout`, `fire-and-forget` and all identifiers in English; use *estado*,
   *controlador*, *observador*, *caso de uso*, *liberar* (dispose), *instantánea*
   (snapshot). Be consistent with the existing translations.
4. If a link points to a heading that exists in both languages, the Spanish
   heading id differs. Add the pair to `ANCHORS` in `scripts/lib.mjs`.
5. `npm run check-translations` must pass: it fails on a missing file or on any
   difference in headings, links or code blocks.

## 3. Add or rename a page

- Guide or ADR: add the name to `GUIDES` or `ADRS` in `scripts/lib.mjs`, add the
  slug to the sidebar in `astro.config.mjs` with its Spanish label, and create
  the translation. `sync-docs` maps `README.md` to `getting-started`,
  `doc/<x>.md` to `guides/<x>` and `doc/adr/<f>.md` to `adr/<f lowercase>`.
- Hand-written page (landing, concepts, demos): create it in
  `src/content/docs/` and `src/content/docs/es/`, and add it to the sidebar.
  Demo pages use `<DemoFrame route="/..." title="..." />` (see an existing one;
  the Spanish pages pass `openLabel` and `loadingLabel`). The route is a
  GoRouter path in `example/lib/navigation/router.dart`.

## 4. Check demo pages against the real demo

Write the "Try it" steps from what the demo does, not from memory.

1. `scripts/build-demo.sh` (needs Flutter on PATH; CI uses 3.47.6).
2. `npm run build`, then `npx astro preview --port 4321`.
3. Open `http://localhost:4321/JIntent/demo/#<route>` and run each step. Flutter
   Web is a canvas: use screenshots, and wait several seconds on first load.
   The counter demo throttles presses by 200 ms.
4. Fix the page if a step, label or behavior differs.

The demo is built with `--profile` so `runtimeType` names are not minified; do
not switch it to `--release`.

## 5. Verify

```sh
npm run build          # runs check-translations, sync-docs and astro build
npm run check-links    # internal links and anchors in dist/
```

For the API reference link to be checked, run `dart doc --output site/dist/api`
from the repository root after `npm run build`. Also run `git diff --check`.
Report each command as passed, failed or not run.

## What is automatic

- Publishing: `docs.yml` builds and deploys from `main` when `site/`, `doc/`,
  `README.md`, `lib/` or `example/` change. Pull requests build and check
  without publishing.
- English guides, links and the API reference are regenerated on every build.
- Spanish text is not machine-translated in CI. A missing or drifting
  translation fails `check-translations`, which fails the pull request build.
