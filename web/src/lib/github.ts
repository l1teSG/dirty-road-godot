/**
 * Lógica centralizada para interactuar con la API de GitHub.
 *
 * Estrategia de fetching:
 * - Las funciones getLatestRelease y getRepoStats se ejecutan en el cliente
 *   (React) para obtener datos frescos en cada visita.
 * - Si se desea mejorar el rendimiento y reducir llamadas a la API, se puede
 *   mover la obtención de datos al frontmatter de Astro (build-time) usando
 *   fetch estático. Esto cachearía los datos en el HTML generado y evitaría
 *   rate limits en el cliente. La decisión de mantenerlo client-side es para
 *   mostrar siempre la información más reciente sin necesidad de rebuild.
 */

export interface GitHubAsset {
  name: string;
  browser_download_url: string;
  size: number;
  content_type: string;
}

export interface GitHubRelease {
  tag_name: string;
  name: string;
  published_at: string;
  body: string;
  assets: GitHubAsset[];
  html_url: string;
}

export interface GitHubRepoStats {
  stargazers_count: number;
  forks_count: number;
  pushed_at: string;
}

const GITHUB_API_BASE = 'https://api.github.com';

/**
 * Construye los headers para las peticiones a la API de GitHub.
 * Si se define GITHUB_TOKEN en el entorno, se usa para autenticación,
 * lo que aumenta el rate limit de 60 a 5000 peticiones/hora.
 */
function getHeaders(): Record<string, string> {
  const headers: Record<string, string> = {
    Accept: 'application/vnd.github.v3+json',
  };

  if (import.meta.env.GITHUB_TOKEN) {
    headers['Authorization'] = `token ${import.meta.env.GITHUB_TOKEN}`;
  }

  return headers;
}

/**
 * Obtiene el último release del repositorio.
 * @throws Error con mensaje descriptivo según el tipo de error.
 */
export async function getLatestRelease(
  owner: string,
  repo: string
): Promise<GitHubRelease> {
  const url = `${GITHUB_API_BASE}/repos/${owner}/${repo}/releases/latest`;
  const response = await fetch(url, { headers: getHeaders() });

  if (!response.ok) {
    if (response.status === 403) {
      const remaining = response.headers.get('X-RateLimit-Remaining');
      if (remaining === '0') {
        throw new Error(
          'Límite de peticiones a GitHub excedido. Intenta de nuevo más tarde o configura GITHUB_TOKEN.'
        );
      }
      throw new Error('Acceso denegado a la API de GitHub (403).');
    }
    if (response.status === 404) {
      throw new Error(
        'No se encontró el release más reciente. ¿El repositorio tiene releases publicados?'
      );
    }
    throw new Error(
      `Error al obtener el release: ${response.status} ${response.statusText}`
    );
  }

  return response.json();
}

/**
 * Obtiene estadísticas del repositorio (estrellas, forks, último push).
 * @throws Error con mensaje descriptivo según el tipo de error.
 */
export async function getRepoStats(
  owner: string,
  repo: string
): Promise<GitHubRepoStats> {
  const url = `${GITHUB_API_BASE}/repos/${owner}/${repo}`;
  const response = await fetch(url, { headers: getHeaders() });

  if (!response.ok) {
    if (response.status === 403) {
      const remaining = response.headers.get('X-RateLimit-Remaining');
      if (remaining === '0') {
        throw new Error(
          'Límite de peticiones a GitHub excedido. Intenta de nuevo más tarde o configura GITHUB_TOKEN.'
        );
      }
      throw new Error('Acceso denegado a la API de GitHub (403).');
    }
    if (response.status === 404) {
      throw new Error(
        'No se encontró el repositorio. Verifica que el nombre sea correcto.'
      );
    }
    throw new Error(
      `Error al obtener estadísticas: ${response.status} ${response.statusText}`
    );
  }

  return response.json();
}

/**
 * Detecta el sistema operativo del usuario basado en navigator.userAgent.
 * Retorna 'windows', 'mac', 'linux' o 'unknown'.
 * Esta función es pura y testeable por separado.
 */
export function detectOS(): 'windows' | 'mac' | 'linux' | 'unknown' {
  if (typeof navigator === 'undefined') return 'unknown';
  const ua = navigator.userAgent.toLowerCase();
  if (ua.includes('win')) return 'windows';
  if (ua.includes('mac')) return 'mac';
  if (ua.includes('linux') || ua.includes('x11')) return 'linux';
  return 'unknown';
}

/**
 * Filtra los assets del release según el sistema operativo.
 * Función pura y testeable por separado.
 */
export function getAssetForOS(
  assets: GitHubAsset[],
  os: 'windows' | 'mac' | 'linux' | 'unknown'
): GitHubAsset | undefined {
  const patterns: Record<string, RegExp> = {
    windows: /\.exe$/i,
    mac: /\.dmg$/i,
    linux: /\.AppImage$/i,
  };

  const pattern = patterns[os];
  if (!pattern) return undefined;

  return assets.find((asset) => pattern.test(asset.name));
}

/**
 * Formatea bytes a una representación legible.
 */
export function formatBytes(bytes: number): string {
  if (bytes === 0) return '0 B';
  const k = 1024;
  const sizes = ['B', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + sizes[i];
}

/**
 * Formatea una fecha ISO a formato legible en español.
 */
export function formatDate(isoDate: string): string {
  const date = new Date(isoDate);
  return date.toLocaleDateString('es-ES', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  });
}
