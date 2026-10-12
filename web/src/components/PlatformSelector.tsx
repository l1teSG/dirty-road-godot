/**
 * Selector de plataforma (Windows / Mac / Linux) con íconos de lucide-react.
 *
 * Patrón de estado compartido:
 * Se usa un callback prop (onSelect) y el valor actual (selectedOS) que
 * recibe del padre. El padre mantiene el estado y lo pasa tanto a
 * PlatformSelector como a DownloadButton. Esto es más simple que usar
 * Context para solo dos componentes y mantiene el flujo de datos explícito.
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
              inline-flex items-center gap-2 rounded-[3px] px-4 py-2 text-sm font-medium transition-colors
              focus:outline-none focus-visible:ring-2 focus-visible:ring-resin focus-visible:ring-offset-2 focus-visible:ring-offset-bg
              ${
                isSelected
                  ? 'bg-leaf text-bg'
                  : 'border border-line-strong text-moss hover:bg-surface hover:text-bone'
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
