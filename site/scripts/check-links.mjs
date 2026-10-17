// Verifies internal links and anchors in the built site (dist/).
// `/JIntent/api/` is produced by `dart doc` in CI, so it is checked only when
// present. Everything else under the base path must resolve.
import { existsSync, readFileSync, readdirSync, statSync } from 'node:fs';
import path from 'node:path';
import { BASE } from '../site.config.mjs';
import { siteRoot } from './lib.mjs';

const dist = path.join(siteRoot, 'dist');
if (!existsSync(dist)) { console.error('dist/ not found. Run `npm run build` first.'); process.exit(1); }

const htmlFiles = [];
(function walk(dir) {
  for (const name of readdirSync(dir)) {
    const full = path.join(dir, name);
    if (statSync(full).isDirectory()) { if (!full.startsWith(path.join(dist, 'demo')) && !full.startsWith(path.join(dist, 'api'))) walk(full); }
    else if (name.endsWith('.html')) htmlFiles.push(full);
  }
})(dist);

const idsCache = new Map();
const idsOf = (file) => {
  if (!idsCache.has(file)) {
    const html = readFileSync(file, 'utf8');
    idsCache.set(file, new Set([...html.matchAll(/\bid="([^"]+)"/g)].map((m) => m[1])));
  }
  return idsCache.get(file);
};

function resolve(urlPath) {
  const rel = decodeURIComponent(urlPath.slice(BASE.length)).replace(/^\//, '');
  const candidates = [path.join(dist, rel, 'index.html'), path.join(dist, rel)];
  return candidates.find((c) => existsSync(c) && statSync(c).isFile());
}

let checked = 0;
const problems = [];
for (const file of htmlFiles) {
  const html = readFileSync(file, 'utf8');
  const page = '/' + path.relative(dist, file);
  for (const m of html.matchAll(/\b(?:href|src)="([^"]+)"/g)) {
    const url = m[1].replace(/&amp;/g, '&');
    if (/^(https?:|mailto:|data:|javascript:)/.test(url)) continue;
    const [rawPath, anchor] = url.split('#');
    const target = rawPath === '' ? file : rawPath.startsWith('/') ? rawPath : null;
    if (target === null) continue; // relative asset URLs are emitted by Astro itself
    if (target !== file && !target.startsWith(BASE + '/') && target !== BASE) continue;
    if (target !== file && target.startsWith(`${BASE}/api/`) && !existsSync(path.join(dist, 'api'))) continue;
    if (target !== file && target.startsWith(`${BASE}/demo/`)) {
      if (!existsSync(path.join(dist, 'demo', 'index.html'))) problems.push(`${page}: demo build missing for ${url} (run scripts/build-demo.sh)`);
      checked++;
      continue;
    }
    checked++;
    const resolved = target === file ? file : resolve(target);
    if (!resolved) { problems.push(`${page}: broken link ${url}`); continue; }
    if (anchor && resolved.endsWith('.html') && !idsOf(resolved).has(decodeURIComponent(anchor))) {
      problems.push(`${page}: missing anchor #${anchor} in ${url}`);
    }
  }
}

if (problems.length) {
  console.error([...new Set(problems)].map((p) => `✗ ${p}`).join('\n'));
  console.error(`\n${new Set(problems).size} link problem(s) in ${htmlFiles.length} pages.`);
  process.exit(1);
}
console.log(`Links OK (${checked} internal links in ${htmlFiles.length} pages).`);
