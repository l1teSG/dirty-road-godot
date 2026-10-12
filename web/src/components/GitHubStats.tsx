/**
 * Componente cliente que muestra estadísticas del repositorio:
 * estrellas, forks y fecha del último commit.
 * Usa getRepoStats de lib/github.ts y se muestra en una tarjeta.
 */

import { useEffect, useState } from 'react';
import { Star, GitFork, Clock } from 'lucide-react';
import { getRepoStats, formatDate } from '../lib/github';
import type { GitHubRepoStats } from '../lib/github';

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
      } catch (err: unknown) {
        if (!cancelled) {
          setError(err instanceof Error ? err.message : 'Error al cargar estadísticas');
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
      <div className="tile flex items-center justify-center gap-6 p-6">
        <div className="h-6 w-20 animate-pulse rounded-[3px] bg-surface-2" />
        <div className="h-6 w-20 animate-pulse rounded-[3px] bg-surface-2" />
        <div className="h-6 w-32 animate-pulse rounded-[3px] bg-surface-2" />
      </div>
    );
  }

  if (error) {
    return <div className="tile p-6 text-center text-sm text-moss">{error}</div>;
  }

  if (!stats) {
    return null;
  }

  return (
    <div className="tile flex flex-wrap items-center justify-center gap-6 p-6 text-sm text-moss">
      <div className="flex items-center gap-2">
        <Star className="h-4 w-4 text-resin" aria-hidden="true" />
        <span className="font-medium tabular-nums text-bone">
          {stats.stargazers_count.toLocaleString()}
        </span>
        <span>estrellas</span>
      </div>

      <span className="hidden h-4 w-px bg-line-strong sm:block" aria-hidden="true" />

      <div className="flex items-center gap-2">
        <GitFork className="h-4 w-4 text-rad" aria-hidden="true" />
        <span className="font-medium tabular-nums text-bone">
          {stats.forks_count.toLocaleString()}
        </span>
        <span>forks</span>
      </div>

      <span className="hidden h-4 w-px bg-line-strong sm:block" aria-hidden="true" />

      <div className="flex items-center gap-2">
        <Clock className="h-4 w-4 text-moss" aria-hidden="true" />
        <span>Último commit:</span>
        <span className="font-medium text-bone">{formatDate(stats.pushed_at)}</span>
      </div>
    </div>
  );
}
