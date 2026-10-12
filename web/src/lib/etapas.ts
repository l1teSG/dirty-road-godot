// Datos de las 10 etapas del juego (temas ambientales + enemigos).
// Extraídos de education_data_stages.gd.

export interface Etapa {
  n: number;
  nombre: string;
  color: string;
  enemigos: string[];
}

export const etapas: Etapa[] = [
  {
    n: 1,
    nombre: 'Contaminación del suelo y el aire',
    color: '#d9d1b8',
    enemigos: ['Microplástico', 'Nube de Gas', 'Petróleo', 'Excavadora Tóxica'],
  },
  {
    n: 2,
    nombre: 'Basura y vertederos',
    color: '#c2c9b3',
    enemigos: ['Lata Oxidada', 'Neumático Quemado', 'Bolsa Plástica', 'Vertedero Viviente'],
  },
  {
    n: 3,
    nombre: 'Océanos y plástico',
    color: '#9ec7f5',
    enemigos: ['Botella de Plástico', 'Botella Lanzadora', 'Red Fantasma', 'Isla de Plástico'],
  },
  {
    n: 4,
    nombre: 'Contaminación industrial',
    color: '#ccc9cc',
    enemigos: ['Humo de Fábrica', 'Chimenea', 'Hollín', 'Chimenea Gigante'],
  },
  {
    n: 5,
    nombre: 'Lluvia ácida',
    color: '#ccdb99',
    enemigos: ['Gota Ácida', 'Charco Ácido', 'Nube Ácida', 'Géiser Ácido'],
  },
  {
    n: 6,
    nombre: 'Residuos electrónicos',
    color: '#b8ccdb',
    enemigos: ['Basura Electrónica', 'Cable Eléctrico', 'Batería Tóxica', 'Montaña de Chatarra'],
  },
  {
    n: 7,
    nombre: 'Energía nuclear y radiación',
    color: '#bfe0b8',
    enemigos: ['Residuo Radiactivo', 'Barril Explosivo', 'Mutante', 'Reactor Roto'],
  },
  {
    n: 8,
    nombre: 'Pesticidas y agricultura',
    color: '#cfd49e',
    enemigos: ['Dron Pesticida', 'Nube de Fumigación', 'Plaga', 'Helicóptero Fumigador'],
  },
  {
    n: 9,
    nombre: 'Deforestación',
    color: '#dbba94',
    enemigos: ['Talador', 'Motosierra', 'Incendio', 'Aserradero Andante'],
  },
  {
    n: 10,
    nombre: 'Cambio climático',
    color: '#ebbd9e',
    enemigos: ['Ola de Calor', 'Tormenta', 'Deshielo', 'Calentamiento Global'],
  },
];
