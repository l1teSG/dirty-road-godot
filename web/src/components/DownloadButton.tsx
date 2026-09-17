/**
 * Componente cliente para el botón de descarga principal.
 * Obtiene la última release de GitHub, detecta el SO del usuario
 * y muestra el asset correspondiente con información adicional.
 *
 * Estados:
 * - loading: skeleton
 * - error: fallback con enlace a la página de releases
 * - sin releases: mensaje "Disponible pronto"
 * - éxito: botón de descarga con versión, fecha y tamaño
 */

import { useEffect, useState } from 'react';
import {
  getLatestRelease,
  detectOS,
  getAssetForOS,
  formatBytes,
  formatDate,
  GitHubRelease,
  GitHubAsset,
} from '../lib/github';

interface Props {
  owner: string;
  repo: string;
}

export default function DownloadButton({ owner, repo }: Props) {
  const [release, setRelease] = useState<GitHubRelease | null>(null);
  const [asset, setAsset] = useState<GitHubAsset | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;

    async function load() {
      try {
        setLoading(true);
        setError(null);

        const data = await getLatestRelease(owner, repo);
        if (cancelled) return;

        setRelease(data);

        const os = detectOS();
        const matched = getAssetForOS(data.assets, os);
        setAsset(matched);
      } catch (err: any) {
        if (cancelled) return;
        setError(err.message ?? 'Error desconocido');
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

  // --- Estado: loading (skeleton) ---
  if (loading) {
    return (
      <div className="flex flex-col items-center gap-4">
        <div className="h-14 w-64 animate-pulse rounded-lg bg-bg-alt" />
        <div className="h-4 w-48 animate-pulse rounded bg-bg-alt" />
      </div>
    );
  }

  // --- Estado: error (fallback a releases) ---
  if (error) {
    return (
      <div className="flex flex-col items-center gap-3">
        <p className="text-sm text-text-secondary">{error}</p>
        <a
          href={`https://github.com/${owner}/${repo}/releases`}
          target="_blank"
          rel="noopener noreferrer"
          className="inline-flex items-center gap-2 rounded-lg bg-magenta px-6 py-3 text-sm font-semibold text-white shadow-glow-magenta transition hover:bg-magenta-bright focus:outline-none focus-visible:ring-2 focus-visible:ring-magenta-bright focus-visible:ring-offset-2 focus-visible:ring-offset-bg"
        >
          Ver releases en GitHub
        </a>
      </div>
    );
  }

  // --- Estado: sin releases (defensivo) ---
  if (!release || !asset) {
    return (
      <p className="text-sm text-text-secondary">
        Disponible pronto
      </p>
    );
  }

  // --- Estado: éxito ---
  return (
    <div className="flex flex-col items-center gap-3">
      <a
        href={asset.browser_download_url}
        target="_blank"
        rel="noopener noreferrer"
        className="inline-flex items-center gap-2 rounded-lg bg-magenta px-6 py-3 text-sm font-semibold text-white shadow-glow-magenta transition hover:bg-magenta-bright focus:outline-none focus-visible:ring-2 focus-visible:ring-magenta-bright focus-visible:ring-offset-2 focus-visible:ring-offset-bg"
      >
        Descargar {asset.name}
      </a>

      <div className="flex flex-wrap items-center justify-center gap-x-4 gap-y-1 text-xs text-text-secondary">
        <span>v{release.tag_name}</span>
        <span aria-hidden="true">·</span>
        <span>{formatDate(release.published_at)}</span>
        <span aria-hidden="true">·</span>
        <span>{formatBytes(asset.size)}</span>
      </div>
    </div>
  );
}
