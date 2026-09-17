/**
 * Lógica centralizada para consumir la API pública de GitHub.
 *
 * ¿Qué se podría mover a build‑time (Astro frontmatter) y qué mantener client‑side?
 * ---------------------------------------------------------------------------------
 * - Las llamadas a getLatestRelease() y getRepoStats() se ejecutan en el cliente
 *   porque la página es estática (output: 'static') y queremos que los datos
 *   reflejen el estado más reciente del repositorio sin necesidad de re‑build.
 *   Si en el futuro se desea una carga instantánea sin peticiones en runtime,
 *   se podría mover la lógica a un endpoint de Astro (SSR) o a un paso de
 *   pre‑renderizado que inyecte los datos en el HTML.
 * - Las funciones puras (detectOS, getAssetForOS, formatBytes, formatDate) no
 *   dependen de la red y pueden usarse tanto en cliente como en build‑time.
 * - El manejo de rate‑limit y errores de red es inherentemente client‑side; en
 *   build‑time se manejaría con reintentos y caché en el servidor de build.
 */

// ---------------------------------------------------------------------------
// Tipos
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// Helpers de autenticación (opcional, para evitar rate‑limit en desarrollo)
// ---------------------------------------------------------------------------

function getHeaders(): Record<string, string> {
  const headers: Record<string, string> = {
    Accept: 'application/vnd.github.v3+json',
  };

  // Si se define GITHUB_TOKEN en el entorno (Astro lo expone como import.meta.env)
  // se añade para aumentar el límite de peticiones.
  if (import.meta.env.GITHUB_TOKEN) {
    headers['Authorization'] = `token ${import.meta.env.GITHUB_TOKEN}`;
  }

  return headers;
}

// ---------------------------------------------------------------------------
// Errores tipados
// ---------------------------------------------------------------------------

export class GitHubError extends Error {
  constructor(
    message: string,
    public readonly status?: number,
    public readonly rateLimitRemaining?: number,
  ) {
    super(message);
    this.name = 'GitHubError';
  }
}

// ---------------------------------------------------------------------------
// Funciones de fetch
// ---------------------------------------------------------------------------

/**
 * Obtiene la release más reciente del repositorio.
 * Lanza GitHubError con mensajes descriptivos según el tipo de fallo.
 */
export async function getLatestRelease(
  owner: string,
  repo: string,
): Promise<GitHubRelease> {
  const url = `https://api.github.com/repos/${owner}/${repo}/releases/latest`;
  let response: Response;

  try {
    response = await fetch(url, { headers: getHeaders() });
  } catch {
    throw new GitHubError(
      'No se pudo conectar con GitHub. Verifica tu conexión a internet.',
    );
  }

  // Rate limit
  if (response.status === 403) {
    const remaining = response.headers.get('X-RateLimit-Remaining');
    if (remaining === '0') {
      throw new GitHubError(
        'Límite de peticiones a GitHub alcanzado. Intenta de nuevo en unos minutos.',
        403,
        0,
      );
    }
  }

  // Repositorio o release no encontrados
  if (response.status === 404) {
    throw new GitHubError(
      'No se encontró el repositorio o no tiene releases publicadas.',
      404,
    );
  }

  if (!response.ok) {
    throw new GitHubError(
      `Error inesperado de GitHub (${response.status}).`,
      response.status,
    );
  }

  const data: GitHubRelease = await response.json();

  // Caso defensivo: la API devolvió 200 pero el array de assets está vacío
  // (puede ocurrir si se borraron los binarios de una release).
  if (!data.assets || data.assets.length === 0) {
    throw new GitHubError(
      'La release más reciente no contiene archivos descargables. Disponible pronto.',
    );
  }

  return data;
}

/**
 * Obtiene estadísticas básicas del repositorio (estrellas, forks, último push).
 */
export async function getRepoStats(
  owner: string,
  repo: string,
): Promise<GitHubRepoStats> {
  const url = `https://api.github.com/repos/${owner}/${repo}`;
  let response: Response;

  try {
    response = await fetch(url, { headers: getHeaders() });
  } catch {
    throw new GitHubError(
      'No se pudo conectar con GitHub. Verifica tu conexión a internet.',
    );
  }

  if (response.status === 403) {
    const remaining = response.headers.get('X-RateLimit-Remaining');
    if (remaining === '0') {
      throw new GitHubError(
        'Límite de peticiones a GitHub alcanzado. Intenta de nuevo en unos minutos.',
        403,
        0,
      );
    }
  }

  if (response.status === 404) {
    throw new GitHubError('Repositorio no encontrado.', 404);
  }

  if (!response.ok) {
    throw new GitHubError(
      `Error inesperado de GitHub (${response.status}).`,
      response.status,
    );
  }

  const data: GitHubRepoStats = await response.json();
  return data;
}

// ---------------------------------------------------------------------------
// Detección de SO (cliente)
// ---------------------------------------------------------------------------

/**
 * Detecta el sistema operativo a partir del userAgent.
 * Retorna 'unknown' si no se puede determinar (p. ej. en SSR).
 */
export function detectOS(): 'windows' | 'mac' | 'linux' | 'unknown' {
  if (typeof navigator === 'undefined') return 'unknown';
  const ua = navigator.userAgent.toLowerCase();
  if (ua.includes('win')) return 'windows';
  if (ua.includes('mac')) return 'mac';
  if (ua.includes('linux') || ua.includes('x11')) return 'linux';
  return 'unknown';
}

// ---------------------------------------------------------------------------
// Selección de asset por SO (función pura)
// ---------------------------------------------------------------------------

/**
 * Dado un array de assets y un SO, devuelve el asset que corresponda.
 * La lógica de matching es pura y no depende del DOM, por lo que es
 * fácilmente testeable.
 */
export function getAssetForOS(
  assets: GitHubAsset[],
  os: 'windows' | 'mac' | 'linux' | 'unknown',
): GitHubAsset | null {
  if (!assets || assets.length === 0) return null;

  const lowerAssets = assets.map((a) => ({
    ...a,
    nameLower: a.name.toLowerCase(),
  }));

  const matchers: Record<string, (name: string) => boolean> = {
    windows: (n) => n.includes('win') || n.endsWith('.exe') || n.endsWith('.msi'),
    mac: (n) => n.includes('mac') || n.includes('darwin') || n.endsWith('.dmg'),
    linux: (n) =>
      n.includes('linux') ||
      n.endsWith('.appimage') ||
      n.endsWith('.deb') ||
      n.endsWith('.rpm') ||
      n.endsWith('.tar.gz') ||
      n.endsWith('.tar.xz'),
  };

  if (os !== 'unknown' && matchers[os]) {
    const match = lowerAssets.find((a) => matchers[os](a.nameLower));
    if (match) return match;
  }

  // Fallback: devolver el primer asset (si existe)
  return lowerAssets[0] ?? null;
}

// ---------------------------------------------------------------------------
// Utilidades de formato
// ---------------------------------------------------------------------------

/**
 * Convierte bytes a una cadena legible (ej. "12.3 MB").
 */
export function formatBytes(bytes: number): string {
  if (bytes === 0) return '0 B';
  const k = 1024;
  const sizes = ['B', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + sizes[i];
}

/**
 * Formatea una fecha ISO a un formato legible en español.
 */
export function formatDate(isoDate: string): string {
  const date = new Date(isoDate);
  return date.toLocaleDateString('es-ES', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  });
}
