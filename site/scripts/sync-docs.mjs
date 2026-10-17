// Generates Starlight pages from the repository Markdown (English) and from
// site/translations/<locale> (mirrors the repo layout). Output is git-ignored.
import { mkdirSync, rmSync, writeFileSync } from 'node:fs';
import path from 'node:path';
import { LOCALES, REPO, BRANCH } from '../site.config.mjs';
import { ADRS, GUIDES, read, repoRoot, rewriteLinks, siteRoot, splitTitle } from './lib.mjs';

const TITLES = { en: { 'getting-started': 'Getting started' }, es: { 'getting-started': 'Primeros pasos' } };

// [repo path of the source, output slug, sidebar order]
const PAGES = [
  ['README.md', 'getting-started'],
  ...GUIDES.map((g) => [`doc/${g}.md`, `guides/${g}`]),
  ['doc/adr/README.md', 'adr'],
  ...ADRS.map((a) => [`doc/adr/${a}.md`, `adr/${a.toLowerCase()}`]),
];

function frontmatter(fields) {
  const lines = Object.entries(fields).map(([k, v]) => `${k}: ${JSON.stringify(v)}`);
  return `---\n${lines.join('\n')}\n---\n\n`;
}

// `LOCALE=en node scripts/sync-docs.mjs` syncs a single locale.
const only = process.env.LOCALE;

for (const [locale, cfg] of Object.entries(LOCALES)) {
  if (only && only !== locale) continue;
  const out = path.join(siteRoot, cfg.contentDir);
  for (const dir of ['guides', 'adr']) rmSync(path.join(out, dir), { recursive: true, force: true });
  rmSync(path.join(out, 'getting-started.md'), { force: true });

  for (const [repoPath, slug] of PAGES) {
    const sourceRoot = locale === 'en' ? repoRoot : path.join(siteRoot, cfg.source);
    let text = read(path.join(sourceRoot, repoPath));

    // The README keeps contributor sections that belong to the repository.
    if (repoPath === 'README.md') text = text.split(/^## Documentation|^## Documentaci[oó]n/m)[0].trimEnd() + '\n';

    const { title, body } = splitTitle(text);
    const editPath = locale === 'en' ? repoPath : `site/translations/${locale}/${repoPath}`;
    const meta = {
      title: TITLES[locale]?.[slug] ?? title,
      editUrl: `${REPO}/edit/${BRANCH}/${editPath}`,
    };
    const file = path.join(out, `${slug}.md`);
    mkdirSync(path.dirname(file), { recursive: true });
    writeFileSync(file, frontmatter(meta) + rewriteLinks(body, repoPath, cfg.prefix));
  }
}
console.log('Synced documentation pages.');
