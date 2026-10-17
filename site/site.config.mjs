// Shared by astro.config.mjs and the content scripts.
export const SITE = 'https://gensoftmx.github.io';
export const BASE = '/JIntent';
export const REPO = 'https://github.com/GenSoftMX/JIntent';
export const BRANCH = 'main';

// Locale id -> URL prefix and where its Markdown sources live (repo-relative).
export const LOCALES = {
  en: { prefix: '', contentDir: 'src/content/docs', source: '..' },
  es: { prefix: '/es', contentDir: 'src/content/docs/es', source: 'translations/es' },
};
