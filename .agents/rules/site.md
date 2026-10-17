# Interactive guide (`site/`)

The guide in `site/` (Astro Starlight, English and Spanish) is published to
GitHub Pages by `.github/workflows/docs.yml`. It is generated from the
repository, so documentation changes must keep it in sync in the same change.
Follow the [update-site skill](../skills/update-site/SKILL.md) for the steps.

## When the site must be updated
- `README.md` (above `## Documentation`), `doc/*.md` or `doc/adr/*.md` change:
  update the Spanish mirror in `site/translations/es/` with the same path.
- A guide or ADR is added, renamed or removed: register it in `GUIDES`/`ADRS`
  (`site/scripts/lib.mjs`), the sidebar (`site/astro.config.mjs`) and the
  translations.
- A demo in `example/` changes its behavior, labels or route, or a demo is
  added: update its page under `site/src/content/docs/demos/` in both languages
  and check it in the browser.
- The public API, entry points or core flow change: review
  `site/src/content/docs/concepts/architecture.mdx` and its Spanish copy.

## Rules
- English in `README.md` and `doc/` is the source of truth. Translate prose only;
  headings, links and code blocks stay identical to the English source.
- Never edit generated pages (`site/src/content/docs/guides/`, `adr/`,
  `getting-started.md` and their `es/` copies). They are git-ignored.
- Do not hand-write internal links in generated content: write relative links as
  in `doc/` and let `sync-docs` rewrite them.
- Do not publish, push or change the Pages configuration without explicit
  authorization. Deploys happen only from `main`.
- Do not claim the site is updated without running `npm run build` and
  `npm run check-links` in `site/`; report them as passed, failed or not run.
  Demos also need `site/scripts/build-demo.sh` and a browser check.
- `site/` is excluded from the published package (`.pubignore`); keep it so.
