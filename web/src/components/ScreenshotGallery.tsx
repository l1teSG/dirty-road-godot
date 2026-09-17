/**
 * Galería de capturas de pantalla del juego.
 * Mientras no haya imágenes reales, muestra placeholders con la estética
 * del juego usando gradientes y un ícono de imagen.
 *
 * Para añadir capturas reales, reemplaza los objetos del array `screenshots`
 * con { src: '/ruta/a/imagen.png', alt: 'Descripción' }.
 */

import { ImageIcon } from 'lucide-react';

interface Screenshot {
  src: string | null;
  alt: string;
}

const screenshots: Screenshot[] = [
  { src: null, alt: 'Captura de pantalla 1' },
  { src: null, alt: 'Captura de pantalla 2' },
  { src: null, alt: 'Captura de pantalla 3' },
  { src: null, alt: 'Captura de pantalla 4' },
  { src: null, alt: 'Captura de pantalla 5' },
];

export default function ScreenshotGallery() {
  return (
    <section className="px-4 py-16">
      <h2 className="mb-8 text-center text-2xl font-semibold text-text-primary sm:text-3xl">
        Capturas de pantalla
      </h2>

      <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
        {screenshots.map((screenshot, index) => (
          <div
            key={index}
            className="radial-vignette relative flex aspect-video items-center justify-center rounded-lg border border-muted/30 bg-bg-alt p-4"
          >
            {screenshot.src ? (
              <img
                src={screenshot.src}
                alt={screenshot.alt}
                className="h-full w-full rounded object-cover"
                loading="lazy"
              />
            ) : (
              <div className="flex flex-col items-center gap-3 text-text-secondary">
                <ImageIcon className="h-10 w-10 opacity-50" aria-hidden="true" />
                <span className="text-sm">Captura próximamente</span>
              </div>
            )}
          </div>
        ))}
      </div>
    </section>
  );
}
