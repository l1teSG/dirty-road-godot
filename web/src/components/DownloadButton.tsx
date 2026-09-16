/**
 * Botón de descarga principal.
 * Detecta el SO del usuario, obtiene el último release de GitHub
 * y muestra el asset correspondiente con versión, fecha y tamaño.
 * Maneja estados de carga, error y rate limiting.
 */
import { useState, useEffect } from 'react';
import {
  getLatestRelease,
  detectOS,
  getAssetForOS,
  formatBytes,
  formatDate,
  type GitHubRelease,
  type GitHubAsset,
} from '../lib/github';

interface Props {
  owner?: string;
  repo?: string;
}

export default function DownloadButton({
  owner = 'usuario',
  repo = 'repo',
}: Props) {
  const [release, setRelease] = useState<GitHubRelease | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [selectedOS, setSelectedOS] = useState<'windows' | 'mac' | 'linux' | 'unknown'>('unknown');
  const [selectedAsset, setSelectedAsset] = useState<GitHubAsset | null>(null);

  // Detectar SO al montar
  useEffect(() => {
    setSelectedOS(detectOS());
  }, []);

  // Obtener release de GitHub
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

  // Actualizar asset cuando cambia el SO o el release
  useEffect(() => {
    if (!release) {
      setSelectedAsset(null);
      return;
    }
    const asset = getAssetForOS(release.assets, selectedOS);
    setSelectedAsset(asset || null);
  }, [release, selectedOS]);

  // Fallback: link a la página de releases
  const fallbackUrl = `https://github.com/${owner}/${repo}/releases`;

  // Estado de carga: skeleton
  if (loading) {
    return (
      <div className="text-center py-8 space-y-4">
        <div className="inline-block w-48 h-14 bg-muted/20 rounded-xl animate-pulse" />
        <div className="space-y-2">
          <div className="inline-block w-32 h-4 bg-muted/20 rounded animate-pulse" />
          <div className="inline-block w-40 h-4 bg-muted/20 rounded animate-pulse" />
        </div>
      </div>
    );
  }

  // Estado de error
  if (error) {
    return (
      <div className="text-center py-8 space-y-4">
        <p className="text-magenta-bright font-mono text-sm">⚠ {error}</p>
        <a
          href={fallbackUrl}
          target="_blank"
          rel="noopener noreferrer"
          className="inline-block px-6 py-3 bg-magenta text-white font-bold rounded-lg hover:bg-magenta-bright transition-colors focus:outline-none focus:ring-2 focus:ring-magenta-bright focus:ring-offset-2 focus:ring-offset-bg"
        >
          Ir a releases en GitHub
        </a>
      </div>
    );
  }

  if (!release) return null;

  const downloadUrl = selectedAsset?.browser_download_url || fallbackUrl;
  const version = release.tag_name;
  const date = formatDate(release.published_at);
  const size = selectedAsset ? formatBytes(selectedAsset.size) : null;

  const osLabel =
    selectedOS === 'mac'
      ? 'macOS'
      : selectedOS === 'unknown'
        ? ''
        : selectedOS.charAt(0).toUpperCase() + selectedOS.slice(1);

  return (
    <div className="text-center space-y-4">
      <a
        href={downloadUrl}
        target="_blank"
        rel="noopener noreferrer"
        className="inline-block px-8 py-4 bg-magenta text-white font-bold text-lg rounded-xl shadow-glow-magenta hover:bg-magenta-bright transition-all focus:outline-none focus:ring-2 focus:ring-magenta-bright focus:ring-offset-2 focus:ring-offset-bg"
      >
        Descargar {osLabel ? `para ${osLabel}` : 'ahora'}
      </a>
      <div className="text-text-secondary font-mono text-sm space-y-1">
        <p>Versión {version}</p>
        <p>{date}</p>
        {size && <p>{size}</p>}
      </div>
    </div>
  );
}
