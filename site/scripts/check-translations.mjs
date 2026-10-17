// Fails when a translation is missing or drifts from its English source:
// same headings, same links and byte-identical code blocks.
import { existsSync } from 'node:fs';
import path from 'node:path';
import { LOCALES } from '../site.config.mjs';
import { ADRS, GUIDES, read, repoRoot, siteRoot } from './lib.mjs';

const FILES = [
  'README.md',
  ...GUIDES.map((g) => `doc/${g}.md`),
  'doc/adr/README.md',
  ...ADRS.map((a) => `doc/adr/${a}.md`),
];

function shape(markdown, file) {
  // The README keeps contributor sections that never reach the site.
  const text = file === 'README.md' ? markdown.split(/^## (?:Documentation|Documentaci[oó]n)/m)[0] : markdown;
  const fences = [...text.matchAll(/^```[^\n]*\n[\s\S]*?^```/gm)].map((m) => m[0]);
  const headings = (text.replace(/^```[\s\S]*?^```/gm, '').match(/^#{1,6} /gm) ?? []).length;
  const links = [...text.matchAll(/\]\(([^)\s]+)\)/g)].map((m) => m[1].replace(/#.*/, ''));
  return { fences, headings, links };
}

let failures = 0;
const fail = (msg) => { failures++; console.error(`✗ ${msg}`); };

for (const [locale, cfg] of Object.entries(LOCALES)) {
  if (locale === 'en') continue;
  for (const file of FILES) {
    const target = path.join(siteRoot, cfg.source, file);
    if (!existsSync(target)) { fail(`[${locale}] missing translation: ${file}`); continue; }
    const en = shape(read(path.join(repoRoot, file)), file);
    const tr = shape(read(target), file);
    if (en.headings !== tr.headings) fail(`[${locale}] ${file}: ${tr.headings} headings, expected ${en.headings}`);
    if (en.fences.length !== tr.fences.length) fail(`[${locale}] ${file}: ${tr.fences.length} code blocks, expected ${en.fences.length}`);
    else en.fences.forEach((f, i) => { if (f !== tr.fences[i]) fail(`[${locale}] ${file}: code block ${i + 1} differs from the English source`); });
    if (JSON.stringify(en.links) !== JSON.stringify(tr.links)) fail(`[${locale}] ${file}: link targets differ from the English source`);
  }
}

if (failures) { console.error(`\n${failures} translation problem(s).`); process.exit(1); }
console.log(`Translations OK (${FILES.length} files).`);
