import { readFileSync, statSync, existsSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { BASE, BRANCH, REPO } from '../site.config.mjs';

export const siteRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
export const repoRoot = path.resolve(siteRoot, '..');

// Guides generated from `doc/*.md`; the README becomes the getting-started page.
export const GUIDES = [
  'effects',
  'error-handling',
  'concurrency',
  'undo-redo',
  'widgets',
  'observability',
  'testing',
  'domain-helpers',
  'migration',
];

export const ADRS = [
  'ADR-000-context-and-high-level-decisions',
  'ADR-001-optional-entry-points-and-core-refinements',
  'ADR-002-stable-undo-redo',
  'ADR-003-equatable-2-and-3',
];

/** Repo-relative path of a Markdown source -> site path (no base, no locale). */
function siteSlugFor(repoPath) {
  if (repoPath === 'README.md') return 'getting-started';
  if (repoPath === 'doc/adr/README.md') return 'adr';
  const adr = repoPath.match(/^doc\/adr\/(.+)\.md$/);
  if (adr) return `adr/${adr[1].toLowerCase()}`;
  const guide = repoPath.match(/^doc\/([^/]+)\.md$/);
  if (guide) return `guides/${guide[1]}`;
  return null;
}

/**
 * Rewrites one relative Markdown link target. `fromRepoPath` is the
 * repo-relative path of the English source the text mirrors, so translations
 * resolve links exactly like the original.
 */
// Heading ids differ in translations, so anchors into site pages are remapped.
const ANCHORS = {
  '/es': {
    'migration-from-experimental': 'migración-desde-experimental',
    'extension-points': 'puntos-de-extensión',
  },
};

export function rewriteTarget(target, fromRepoPath, prefix) {
  if (/^([a-z][a-z0-9+.-]*:|#|\/)/i.test(target)) return target;
  const [rawPath, anchor] = target.split('#');
  const resolved = path
    .normalize(path.join(path.dirname(fromRepoPath), rawPath))
    .replace(/\\/g, '/');
  const slug = siteSlugFor(resolved);
  if (slug) {
    const id = ANCHORS[prefix]?.[anchor] ?? anchor;
    return `${BASE}${prefix}/${slug}/${id ? `#${id}` : ''}`;
  }
  const frag = anchor ? `#${anchor}` : '';
  const abs = path.join(repoRoot, resolved);
  const isDir = existsSync(abs) && statSync(abs).isDirectory();
  const kind = isDir || rawPath.endsWith('/') ? 'tree' : 'blob';
  return `${REPO}/${kind}/${BRANCH}/${resolved.replace(/\/$/, '')}${frag}`;
}

/** Applies [rewriteTarget] to every inline link outside fenced code blocks. */
export function rewriteLinks(markdown, fromRepoPath, prefix) {
  let fenced = false;
  return markdown
    .split('\n')
    .map((line) => {
      if (/^\s*(```|~~~)/.test(line)) fenced = !fenced;
      if (fenced) return line;
      return line.replace(/(\]\()([^)\s]+)(\))/g, (_, open, target, close) =>
        `${open}${rewriteTarget(target, fromRepoPath, prefix)}${close}`);
    })
    .join('\n');
}

export function read(file) {
  return readFileSync(file, 'utf8');
}

/** Splits the first `# Title` off the body. */
export function splitTitle(markdown) {
  const match = markdown.match(/^# (.+)\n+/);
  if (!match) throw new Error('Missing H1 title');
  return { title: match[1].trim(), body: markdown.slice(match[0].length) };
}
