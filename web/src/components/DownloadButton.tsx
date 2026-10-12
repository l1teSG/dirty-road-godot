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
} from '../lib/github';
import type { GitHubRelease, GitHubAsset } from '../lib/github';

interface Props {
  owner: string;
  repo: string;
}

const primaryBtn =
  'inline-flex items-center rounded-[3px] bg-resin px-6 py-3 text-sm font-semibold text-bg shadow-glow-resin transition-colors hover:bg-[#f0b451] focus:outline-none focus-visible:ring-2 focus-visible:ring-resin focus-visible:ring-offset-2 focus-visible:ring-offset-bg';

const secondaryBtn =
  'inline-flex items-center rounded-[3px] border border-line-strong px-6 py-3 text-sm font-semibold text-bone transition-colors hover:bg-surface focus:outline-none focus-visible:ring-2 focus-visible:ring-resin focus-visible:ring-offset-2 focus-visible:ring-offset-bg';

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
        <div className="h-12 w-64 animate-pulse rounded-[3px] bg-surface-2" />
        <div className="h-4 w-48 animate-pulse rounded-[3px] bg-surface-2" />
      </div>
    );
  }

  // --- Estado: error (fallback a releases) ---
  if (error) {
    return (
      <div className="flex flex-col items-center gap-3">
        <p className="text-sm text-moss">{error}</p>
        <a href={`https://github.com/${owner}/${repo}/releases`} target="_blank" rel="noopener noreferrer" className={secondaryBtn}>
          Ver releases en GitHub
        </a>
      </div>
    );
  }

  // --- Estado: sin releases (defensivo) ---
  if (!release || !asset) {
    return <p className="text-sm text-moss">Disponible pronto</p>;
  }

  // --- Estado: éxito ---
  return (
    <div className="flex flex-col items-center gap-3">
      <a href={asset.browser_download_url} target="_blank" rel="noopener noreferrer" className={primaryBtn}>
        Descargar {asset.name}
      </a>

      <div className="flex flex-wrap items-center justify-center gap-x-3 gap-y-1 text-xs text-moss">
        <span className="tabular-nums">v{release.tag_name}</span>
        <span className="h-3 w-px bg-line-strong" aria-hidden="true" />
        <span>{formatDate(release.published_at)}</span>
        <span className="h-3 w-px bg-line-strong" aria-hidden="true" />
        <span className="tabular-nums">{formatBytes(asset.size)}</span>
      </div>
    </div>
  );
}
