/**
 * Componente Hero: título principal, subtítulo y elemento decorativo con glow.
 * Usa el fondo radial-vignette y un pulso sutil en el elemento central.
 * Incluye el botón de descarga dentro del layout.
 */
import { useEffect, useState } from 'react';
import DownloadButton from './DownloadButton';

export default function Hero() {
  const [prefersReducedMotion, setPrefersReducedMotion] = useState(false);

  useEffect(() => {
    const mq = window.matchMedia('(prefers-reduced-motion: reduce)');
    setPrefersReducedMotion(mq.matches);
    const handler = (e: MediaQueryListEvent) => setPrefersReducedMotion(e.matches);
    mq.addEventListener('change', handler);
    return () => mq.removeEventListener('change', handler);
  }, []);

  return (
    <section className="radial-vignette min-h-[80vh] flex flex-col items-center justify-center text-center px-4 relative">
      {/* Elemento decorativo con glow aludiendo a la torreta del juego */}
      <div
        className={`absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-72 h-72 rounded-full bg-teal/10 blur-3xl ${
          prefersReducedMotion ? '' : 'glow-pulse'
        }`}
        aria-hidden="true"
      />

      <div className="relative z-10 space-y-8 max-w-3xl mx-auto">
        <div className="space-y-4">
          <h1 className="text-5xl md:text-7xl font-bold tracking-tight">
            <span className="text-green-bright">Dirty</span>{' '}
            <span className="text-teal">Road</span>
          </h1>
          <p className="text-xl md:text-2xl text-text-secondary max-w-2xl mx-auto font-mono">
            Sobrevive a la contaminación. Un shooter minimalista con conciencia ecológica.
          </p>
        </div>

        <DownloadButton />
      </div>
    </section>
  );
}
