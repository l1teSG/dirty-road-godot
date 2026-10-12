/**
 * Componente cliente que muestra el changelog (body en markdown) de la
 * última release de GitHub.
 *
 * Librería usada: marked
 * - Convierte Markdown a HTML de forma ligera y sin dependencias.
 *
 * Nota de seguridad: `marked` NO sanea ni escapa el HTML por defecto. Como el
 * body de una release puede contener HTML crudo (y las releases del proyecto se
 * exportan desde Obsidian, que duplica el contenido en HTML + Markdown), aquí:
 *   1. `cleanReleaseBody()` descarta el bloque HTML exportado por Obsidian y
 *      conserva solo la mitad en Markdown.
 *   2. DOMPurify limpia el resultado antes de inyectarlo con
 *      `dangerouslySetInnerHTML`.
 */

import { useEffect, useState } from 'react';
import { marked } from 'marked';
import DOMPurify from 'dompurify';
import { getLatestRelease } from '../lib/github';
import type { GitHubRelease } from '../lib/github';

/**
 * Las releases escritas/exportadas desde Obsidian pueden empezar con un bloque
 * HTML completo seguido del mismo contenido en Markdown. Si detectamos ese
 * artefacto, conservamos solo la parte Markdown (a partir del primer `# `).
 */
function cleanReleaseBody(body: string): string {
  if (!body) return '';

  if (body.includes('<!-- obsidian -->')) {
    const markdownStart = body.indexOf('# ');
    if (markdownStart !== -1) return body.slice(markdownStart);
  }

  return body;
}

/**
 * Reescribe los enlaces relativos del body (`./` y `../`) a URLs absolutas del
 * repositorio, para que las imágenes y referencias no salgan rotas en la web.
 * Las imágenes apuntan a `raw`; los enlaces, a `blob`.
 */
function absolutizeRepoLinks(md: string, owner: string, repo: string, ref: string): string {
  const repoUrl = (path: string, kind: 'raw' | 'blob') =>
    `https://github.com/${owner}/${repo}/${kind}/${ref}/${path.replace(/^(\.\.?\/)+/, '')}`;

  return md
    .replace(
      /!\[([^\]]*)\]\((\.{1,2}\/[^)\s]+)\)/g,
      (_m, alt: string, path: string) => `![${alt}](${repoUrl(path, 'raw')})`,
    )
    .replace(
      /\[([^\]]*)\]\((\.{1,2}\/[^)\s]+)\)/g,
      (_m, text: string, path: string) => `[${text}](${repoUrl(path, 'blob')})`,
    );
}

function renderChangelog(body: string, owner: string, repo: string, ref: string): string {
  const clean = absolutizeRepoLinks(cleanReleaseBody(body), owner, repo, ref);
  const html = marked.parse(clean) as string;
  return DOMPurify.sanitize(html);
}

interface Props {
  owner: string;
  repo: string;
}

export default function Changelog({ owner, repo }: Props) {
  const [release, setRelease] = useState<GitHubRelease | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;

    async function load() {
      try {
        setLoading(true);
        setError(null);
        const data = await getLatestRelease(owner, repo);
        if (!cancelled) {
          setRelease(data);
        }
      } catch (err: unknown) {
        if (!cancelled) {
          setError(err instanceof Error ? err.message : 'Error al cargar el changelog');
        }
      } finally {
        if (!cancelled) {
          setLoading(false);
        }
      }
    }

    load();

    return () => {
      cancelled = true;
    };
  }, [owner, repo]);

  if (loading) {
    return (
      <div className="space-y-3">
        <div className="h-6 w-48 animate-pulse rounded-[3px] bg-surface-2" />
        <div className="h-4 w-full animate-pulse rounded-[3px] bg-surface-2" />
        <div className="h-4 w-3/4 animate-pulse rounded-[3px] bg-surface-2" />
        <div className="h-4 w-5/6 animate-pulse rounded-[3px] bg-surface-2" />
      </div>
    );
  }

  if (error) {
    return <p className="text-sm text-moss">{error}</p>;
  }

  if (!release) {
    return null;
  }

  const htmlContent = renderChangelog(release.body ?? '', owner, repo, release.tag_name);

  return (
    <div className="max-w-none">
      <h2 className="text-xl font-semibold text-bone">{release.name || release.tag_name}</h2>
      <div
        className="mt-4 space-y-3 text-sm leading-relaxed text-moss [&_a]:text-leaf [&_a]:underline [&_a]:underline-offset-4 [&_blockquote]:border-l-2 [&_blockquote]:border-line-strong [&_blockquote]:pl-4 [&_h1]:text-lg [&_h1]:font-semibold [&_h1]:text-bone [&_h2]:text-base [&_h2]:font-semibold [&_h2]:text-bone [&_h3]:font-semibold [&_h3]:text-bone [&_hr]:border-line [&_img]:rounded-[3px] [&_li]:ml-1 [&_strong]:text-bone [&_ul]:list-disc [&_ul]:pl-5"
        dangerouslySetInnerHTML={{ __html: htmlContent }}
      />
    </div>
  );
}
