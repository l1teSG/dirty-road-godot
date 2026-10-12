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
import { getLatestRelease } from '../lib/github';
import type { GitHubRelease } from '../lib/github';

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

  const htmlContent = marked.parse(release.body ?? '') as string;

  return (
    <div className="max-w-none">
      <h2 className="text-xl font-semibold text-bone">{release.name || release.tag_name}</h2>
      <div
        className="mt-4 space-y-3 text-sm leading-relaxed text-moss [&_a]:text-leaf [&_a]:underline [&_a]:underline-offset-4 [&_strong]:text-bone [&_ul]:list-disc [&_ul]:pl-5"
        dangerouslySetInnerHTML={{ __html: htmlContent }}
      />
    </div>
  );
}
