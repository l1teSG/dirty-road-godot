/**
 * Selector de plataforma: botones Windows/Mac/Linux con iconos SVG inline simplificados.
 * Usa un patrón de props callback para comunicar la selección a DownloadButton.
 * Se eligió este patrón por simplicidad: los componentes son hermanos en el
 * mismo padre (index.astro), por lo que no se necesita Context ni estado global.
 */

interface Props {
  selectedOS: 'windows' | 'mac' | 'linux' | 'unknown';
  onSelect: (os: 'windows' | 'mac' | 'linux') => void;
}

const platforms = [
  {
    id: 'windows' as const,
    label: 'Windows',
    icon: (
      <svg className="w-5 h-5" viewBox="0 0 24 24" fill="currentColor">
        <path d="M3 12V6.5l8-1.1V12H3zm0 .5h8v6.6l-8-1.1V12.5zm9.5-7.1L21 3v9h-8.5V5.4zm0 13.2V12H21v9l-8.5-1.1v-1.2z" />
      </svg>
    ),
  },
  {
    id: 'mac' as const,
    label: 'macOS',
    icon: (
      <svg className="w-5 h-5" viewBox="0 0 24 24" fill="currentColor">
        <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.8-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z" />
      </svg>
    ),
  },
  {
    id: 'linux' as const,
    label: 'Linux',
    icon: (
      <svg className="w-5 h-5" viewBox="0 0 24 24" fill="currentColor">
        <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm0 18c-4.41 0-8-3.59-8-8s3.59-8 8-8 8 3.59 8 8-3.59 8-8 8zm-1-13h2v6h-2zm0 8h2v2h-2z" />
      </svg>
    ),
  },
];

export default function PlatformSelector({ selectedOS, onSelect }: Props) {
  return (
    <div className="flex flex-wrap justify-center gap-3" role="radiogroup" aria-label="Seleccionar plataforma">
      {platforms.map((platform) => {
        const isSelected = selectedOS === platform.id;
        return (
          <button
            key={platform.id}
            onClick={() => onSelect(platform.id)}
            role="radio"
            aria-checked={isSelected}
            className={`flex items-center gap-2 px-4 py-2 rounded-lg border transition-colors focus:outline-none focus:ring-2 focus:ring-green-bright focus:ring-offset-2 focus:ring-offset-bg ${
              isSelected
                ? 'border-green-bright bg-green/10 text-green-bright'
                : 'border-muted text-text-secondary hover:border-green/50 hover:text-text-primary'
            }`}
          >
            {platform.icon}
            <span className="font-mono text-sm">{platform.label}</span>
          </button>
        );
      })}
    </div>
  );
}
