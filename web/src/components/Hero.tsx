/**
 * Componente Hero para la página de descarga de Dirty Road.
 * Muestra el título, subtítulo y el botón de descarga principal.
 * No contiene lógica de fetch propia; solo estructura y estilos.
 */

import DownloadButton from './DownloadButton';

export default function Hero() {
  return (
    <section className="radial-vignette relative flex min-h-[80vh] flex-col items-center justify-center px-4 py-20 text-center">
      {/* Elemento decorativo que alude a la torreta del juego */}
      <div
        className="glow-pulse absolute top-10 right-10 h-24 w-24 rounded-full bg-green/20 blur-2xl"
        aria-hidden="true"
      />

      <h1 className="text-5xl font-bold tracking-tight text-text-primary sm:text-6xl lg:text-7xl">
        Dirty Road
      </h1>
      <p className="mt-6 max-w-2xl text-lg text-text-secondary sm:text-xl">
        Videojuego educativo 2D que fomenta la conciencia ambiental.
        Recolecta, recicla y reforesta con Renata.
      </p>

      <div className="mt-10">
        <DownloadButton owner="l1teSG" repo="dirty-road-godot" />
      </div>
    </section>
  );
}
