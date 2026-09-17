/**
 * Componente cliente que muestra estadísticas del repositorio:
 * estrellas, forks y fecha del último commit.
 * Usa getRepoStats de lib/github.ts y se muestra en una tarjeta.
 */

import { useEffect, useState } from 'react';
import { Star, GitFork, Clock } from 'lucide-react';
import { getRepoStats, formatDate, GitHubRepoStats } from '../lib/github';

interface Props {
  owner: string;
  repo: string;
}

export default function GitHubStats({ owner, repo }: Props) {
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
          setError(err.message ?? 'Error al cargar estadísticas');
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
      <div className="card flex items-center justify-center gap-4 p-6">
        <div className="h-8 w-20 animate-pulse rounded bg-bg-alt" />
        <div className="h-8 w-20 animate-pulse rounded bg-bg-alt" />
        <div className="h-8 w-32 animate-pulse rounded bg-bg-alt" />
      </div>
    );
  }

  if (error) {
    return (
      <div className="card p-6 text-center text-sm text-text-secondary">
        {error}
      </div>
    );
  }

  if (!stats) {
    return null;
  }

  return (
    <div className="card flex flex-wrap items-center justify-center gap-6 p-6 text-sm text-text-secondary">
      <div className="flex items-center gap-2">
        <Star className="h-4 w-4 text-yellow-400" aria-hidden="true" />
        <span className="font-mono font-medium text-text-primary">
          {stats.stargazers_count.toLocaleString()}
        </span>
        <span>estrellas</span>
      </div>

      <div className="flex items-center gap-2">
        <GitFork className="h-4 w-4 text-teal" aria-hidden="true" />
        <span className="font-mono font-medium text-text-primary">
          {stats.forks_count.toLocaleString()}
        </span>
        <span>forks</span>
      </div>

      <div className="flex items-center gap-2">
        <Clock className="h-4 w-4 text-muted" aria-hidden="true" />
        <span>Último commit:</span>
        <span className="font-mono font-medium text-text-primary">
          {formatDate(stats.pushed_at)}
        </span>
      </div>
    </div>
  );
}
