/**
 * Componente Hero alternativo (no usado por la landing actual, que usa
 * sections/Hero.astro). Se mantiene alineado con el sistema visual.
 */

import DownloadButton from './DownloadButton';

export default function Hero() {
  return (
    <section className="field-grid relative flex min-h-[80vh] flex-col items-center justify-center px-4 py-20 text-center">
      <h1 className="text-5xl font-bold tracking-tight text-bone sm:text-6xl lg:text-7xl">
        Dirty Road
      </h1>
      <p className="mt-6 max-w-2xl text-lg text-moss sm:text-xl">
        Videojuego educativo 2D que fomenta la conciencia ambiental. Recolecta, recicla y reforesta
        con Renata.
      </p>

      <div className="mt-10">
        <DownloadButton owner="l1teSG" repo="dirty-road-godot" />
      </div>
    </section>
  );
}
