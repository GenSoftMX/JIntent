# JIntent interactive guide

A bilingual (English and Spanish) documentation site built with
[Astro Starlight](https://starlight.astro.build). It is published to
<https://gensoftmx.github.io/JIntent/> by
[`.github/workflows/docs.yml`](../.github/workflows/docs.yml) on every push to
`main`. Pull requests build the site and run the checks without publishing.

The site embeds the real example app, built with Flutter Web, so each demo runs
the library itself. It also links to the `dart doc` API reference.

## Where the content comes from

| Content | Source of truth | Generated page |
| --- | --- | --- |
| Getting started | [`../README.md`](../README.md), up to its `## Documentation` section | `getting-started` |
| Guides | [`../doc/*.md`](../doc/) | `guides/*` |
| Architecture records | [`../doc/adr/`](../doc/adr/) | `adr/*` |
| Spanish translations | [`translations/es/`](translations/es/), mirroring the repository layout | `es/...` |
| Landing page, architecture diagrams, live demos | `src/content/docs/` (hand-written, one file per language) | same path |

`npm run sync-docs` copies the Markdown into `src/content/docs/` (git-ignored),
adds the front matter and rewrites relative links: links between guides become
site links and links to source files become GitHub links. Edit the English
source in `doc/` or the translation in `translations/es/`, never the generated
pages.

## Working on the site

Requires Node 22 and, for the demos, a Flutter SDK (CI uses 3.47.6).

```sh
cd site
npm ci
scripts/build-demo.sh      # builds example/ with Flutter Web into public/demo
npm run dev                     # http://localhost:4321/JIntent/
```

| Command | What it does |
| --- | --- |
| `npm run build` | Checks translations, syncs the docs and builds `dist/`. |
| `npm run check-translations` | Fails if a Spanish page is missing or differs from the English structure, links or code blocks. |
| `npm run check-links` | Fails on broken internal links or anchors in `dist/`. |

The demos use `flutter build web --profile` on purpose: a release build
minifies `runtimeType` names, and the observability demo prints intent types.

## Changing documentation

1. Edit the English page in `doc/` (or `README.md`).
2. Update the same page in `translations/es/`. Keep headings, links and code
   blocks identical; translate prose only. `npm run check-translations` enforces
   this.
3. Run `npm run build` and `npm run check-links`.

Heading ids differ between languages, so an anchor into a translated heading
needs an entry in `ANCHORS` in [`scripts/lib.mjs`](scripts/lib.mjs).

The demo app's own UI is not translated; the Spanish pages quote its English
labels.
