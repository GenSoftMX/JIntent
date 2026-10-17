import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';
import mermaid from 'astro-mermaid';
import { BASE, BRANCH, REPO, SITE } from './site.config.mjs';

const t = (en, es) => ({ label: en, translations: { es } });
const page = (slug, en, es) => ({ slug, ...t(en, es) });

export default defineConfig({
  site: SITE,
  base: BASE,
  integrations: [
    // Must come before Starlight so it can process the Markdown.
    mermaid({ autoTheme: true }),
    starlight({
      title: 'JIntent',
      description:
        'Explicit intents, immutable state and one-time UI effects for Flutter.',
      defaultLocale: 'root',
      locales: {
        root: { label: 'English', lang: 'en' },
        es: { label: 'Español', lang: 'es' },
      },
      social: [{ icon: 'github', label: 'GitHub', href: REPO }],
      editLink: { baseUrl: `${REPO}/edit/${BRANCH}/` },
      lastUpdated: false,
      sidebar: [
        page('getting-started', 'Getting started', 'Primeros pasos'),
        {
          ...t('Concepts', 'Conceptos'),
          items: [page('concepts/architecture', 'Architecture', 'Arquitectura')],
        },
        {
          ...t('Live demos', 'Demos en vivo'),
          items: [
            page('demos/counter', 'Counter', 'Contador'),
            page('demos/concurrency', 'Concurrency Lab', 'Laboratorio de concurrencia'),
            page('demos/effects', 'Startup & effects', 'Arranque y effects'),
            page('demos/observability', 'Observability Lab', 'Laboratorio de observabilidad'),
            page('demos/undo', 'Undo notes', 'Notas con undo'),
          ],
        },
        {
          ...t('Guides', 'Guías'),
          items: [
            page('guides/effects', 'Effects', 'Effects'),
            page('guides/error-handling', 'Error handling', 'Manejo de errores'),
            page('guides/concurrency', 'Concurrency strategies', 'Estrategias de concurrencia'),
            page('guides/undo-redo', 'Undo and redo', 'Undo y redo'),
            page('guides/widgets', 'Widgets', 'Widgets'),
            page('guides/observability', 'Observability', 'Observabilidad'),
            page('guides/testing', 'Testing', 'Pruebas'),
            page('guides/domain-helpers', 'Domain helpers', 'Helpers de dominio'),
          ],
        },
        page('guides/migration', 'Migrating from 2.x', 'Migrar desde 2.x'),
        {
          ...t('Reference', 'Referencia'),
          items: [
            { ...t('API reference', 'Referencia de API'), // Absolute so Starlight does not prepend the base path or the locale.
            link: `${SITE}${BASE}/api/`, attrs: { target: '_blank' } },
            { ...t('Changelog', 'Changelog'), link: `${REPO}/blob/${BRANCH}/CHANGELOG.md`, attrs: { target: '_blank' } },
            page('adr', 'Architecture records', 'Registros de arquitectura'),
          ],
        },
      ],
    }),
  ],
});
