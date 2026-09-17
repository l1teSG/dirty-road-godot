/**
 * Componente cliente que muestra el changelog (body en markdown) de la
 * última release de GitHub.
 *
 * Librería usada: marked
 * - Es ligera (~20 KB minificada), rápida y sin dependencias.
 * - Convierte Markdown a HTML de forma segura (escapa HTML por defecto).
 * - Ampliamente usada y mantenida.
 *
 * Instalación: npm install marked
 */

import { useEffect, useState } from 'react';
import { marked } from 'marked';
import { getLatestRelease, GitHubRelease } from '../lib/github';

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
      } catch (err: any) {
        if (!cancelled) {
          setError(err.message ?? 'Error al cargar el changelog');
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
        <div className="h-6 w-48 animate-pulse rounded bg-bg-alt" />
        <div className="h-4 w-full animate-pulse rounded bg-bg-alt" />
        <div className="h-4 w-3/4 animate-pulse rounded bg-bg-alt" />
        <div className="h-4 w-5/6 animate-pulse rounded bg-bg-alt" />
      </div>
    );
  }

  if (error) {
    return (
      <p className="text-sm text-text-secondary">{error}</p>
    );
  }

  if (!release) {
    return null;
  }

  const htmlContent = marked.parse(release.body ?? '') as string;

  return (
    <div className="prose prose-invert max-w-none">
      <h2 className="text-xl font-semibold text-text-primary">
        {release.name || release.tag_name}
      </h2>
      <div
        className="mt-4 text-sm leading-relaxed text-text-secondary"
        dangerouslySetInnerHTML={{ __html: htmlContent }}
      />
    </div>
  );
}
