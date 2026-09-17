/**
 * Componente GitHubStats: muestra estrellas, forks y último commit del repositorio.
 * Usa getRepoStats de lib/github.ts y renderiza una tarjeta con estilo HUD.
 */
import { useState, useEffect } from 'react';
import { getRepoStats, formatDate, type GitHubRepoStats } from '../lib/github';

interface Props {
  owner?: string;
  repo?: string;
}

export default function GitHubStats({ owner = 'usuario', repo = 'repo' }: Props) {
  const [stats, setStats] = useState<GitHubRepoStats | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;
    async function load() {
      try {
        setLoading(true);
        setError(null);
        const data = await getRepoStats(owner, repo);
        if (!cancelled) {
          setStats(data);
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
      <div className="card p-6 space-y-3">
        <div className="h-4 w-32 bg-muted/20 rounded animate-pulse" />
        <div className="h-4 w-24 bg-muted/20 rounded animate-pulse" />
        <div className="h-4 w-40 bg-muted/20 rounded animate-pulse" />
      </div>
    );
  }

  if (error) {
    return (
      <div className="card p-6">
        <p className="text-magenta-bright font-mono text-sm">⚠ {error}</p>
      </div>
    );
  }

  if (!stats) return null;

  return (
    <div className="card p-6 space-y-3">
      <h3 className="text-lg font-bold text-green-bright font-display">Estadísticas del repo</h3>
      <div className="space-y-2 font-mono text-sm text-text-secondary">
        <p>
          <span className="text-text-primary">⭐</span> {stats.stargazers_count.toLocaleString()} estrellas
        </p>
        <p>
          <span className="text-text-primary">⑂</span> {stats.forks_count.toLocaleString()} forks
        </p>
        <p>
          <span className="text-text-primary">⏱</span> Último commit: {formatDate(stats.pushed_at)}
        </p>
      </div>
    </div>
  );
}
