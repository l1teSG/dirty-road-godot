/**
 * Selector de plataforma (Windows / Mac / Linux) con íconos de lucide-react.
 *
 * Patrón de estado compartido:
 * Se usa un callback prop (onSelect) y el valor actual (selectedOS) que
 * recibe del padre. El padre (index.astro) mantiene el estado y lo pasa
 * tanto a PlatformSelector como a DownloadButton. Esto es más simple que
 * usar Context para solo dos componentes y mantiene el flujo de datos
 * explícito y fácil de seguir.
 */

import { Monitor, Apple, Terminal } from 'lucide-react';

interface Props {
  selectedOS: 'windows' | 'mac' | 'linux' | 'unknown';
  onSelect: (os: 'windows' | 'mac' | 'linux') => void;
}

const platforms = [
  { id: 'windows' as const, label: 'Windows', Icon: Monitor },
  { id: 'mac' as const, label: 'macOS', Icon: Apple },
  { id: 'linux' as const, label: 'Linux', Icon: Terminal },
];

export default function PlatformSelector({ selectedOS, onSelect }: Props) {
  return (
    <div className="flex flex-wrap items-center justify-center gap-2" role="group" aria-label="Seleccionar plataforma">
      {platforms.map(({ id, label, Icon }) => {
        const isSelected = selectedOS === id;
        return (
          <button
            key={id}
            onClick={() => onSelect(id)}
            className={`
              inline-flex items-center gap-2 rounded-lg px-4 py-2 text-sm font-medium transition
              focus:outline-none focus-visible:ring-2 focus-visible:ring-teal focus-visible:ring-offset-2 focus-visible:ring-offset-bg
              ${
                isSelected
                  ? 'bg-teal text-white shadow-glow-teal'
                  : 'bg-bg-alt text-text-secondary hover:bg-muted/30 hover:text-text-primary'
              }
            `}
            aria-pressed={isSelected}
          >
            <Icon className="h-4 w-4" aria-hidden="true" />
            {label}
          </button>
        );
      })}
    </div>
  );
}
