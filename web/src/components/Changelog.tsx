/**
 * Componente Changelog: renderiza el campo "body" (markdown) del último release.
 * Usa la librería "marked" para convertir markdown a HTML de forma segura.
 * Se eligió "marked" por ser ligera (~20KB), sin dependencias, con soporte
 * para GitHub Flavored Markdown y ampliamente usada en proyectos Astro/React.
 * Instalar con: npm install marked
 */
import { useState, useEffect } from 'react';
import { marked } from 'marked';
import { getLatestRelease, type GitHubRelease } from '../lib/github';

interface Props {
  owner?: string;
  repo?: string;
}

export default function Changelog({ owner = 'usuario', repo = 'repo' }: Props) {
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
          setError(err.message || 'Error desconocido');
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
      <div className="space-y-4">
        <div className="h-6 w-48 bg-muted/20 rounded animate-pulse" />
        <div className="space-y-2">
          <div className="h-4 w-full bg-muted/20 rounded animate-pulse" />
          <div className="h-4 w-3/4 bg-muted/20 rounded animate-pulse" />
          <div className="h-4 w-1/2 bg-muted/20 rounded animate-pulse" />
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="text-center py-8">
        <p className="text-magenta-bright font-mono text-sm">⚠ {error}</p>
      </div>
    );
  }

  if (!release) return null;

  const htmlContent = marked.parse(release.body) as string;

  return (
    <section className="space-y-4">
      <h2 className="text-2xl font-bold text-green-bright font-display">
        Novedades de {release.tag_name}
      </h2>
      <div
        className="prose prose-invert max-w-none font-mono text-text-secondary text-sm
          prose-headings:text-green-bright prose-headings:font-display
          prose-a:text-teal prose-a:no-underline hover:prose-a:underline
          prose-code:text-green-bright prose-code:bg-bg-alt prose-code:px-1 prose-code:rounded
          prose-ul:list-disc prose-ul:pl-5"
        dangerouslySetInnerHTML={{ __html: htmlContent }}
      />
    </section>
  );
}
