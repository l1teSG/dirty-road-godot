# Folleto · Dirty Road

Dos piezas imprimibles del juego, con el sistema visual del micrositio (turba +
clorofila + ámbar de peligro, tipografía **Chakra Petch**, rejilla y grano):

1. **Folleto A4 a doble cara** — hoja recta, 2 caras (práctica + escrita).
2. **Tríptico A4 horizontal con doblez en zigzag (Z-fold)** — se dobla sin recortar.

## Archivos

```
docs/folleto/
├── dirty-road-folleto.html            Folleto A4 recto (2 caras)
├── DirtyRoad-folleto-oscuro.pdf       → tema oscuro
├── DirtyRoad-folleto-claro.pdf        → tema claro (ahorra tinta)
│
├── dirty-road-triptico.html           Tríptico A4 horizontal, zigzag (2 caras)
├── DirtyRoad-triptico-oscuro.pdf      → tema oscuro
├── DirtyRoad-triptico-claro.pdf       → tema claro (ahorra tinta)
│
├── assets/                            Capturas, banner, icono y fuentes
├── tools/generar-pdf.mjs              Generador de PDF (Brave/Chromium + CDP)
└── README.md                          Este archivo
```

## Tríptico: cómo se dobla (sin recortar)

Es un **Z-fold (zigzag)**: como todos los paneles miden lo mismo, **no hay que
cortar nada**. Imposición estándar:

| Cara | Paneles (izquierda → derecha) |
| :--- | :--- |
| **Exterior** (hoja 1) | panel 3 · panel 2 · **panel 1 (portada)** |
| **Interior** (hoja 2) | **panel 6 (contraportada)** · panel 5 · panel 4 |

**Para imprimir:**
1. A4 **horizontal**, a doble cara, y **voltear por el lado corto**
   (short edge) para que las caras queden alineadas.
2. Si tu impresora no lo permite, imprime una cara, voltea la hoja a mano y
   prueba con una copia en blanco antes de gastar papel bueno.
3. Dobla **en zigzag**: un pliegue hacia delante, otro hacia atrás, por las dos
   líneas discontinuas.
4. El HTML tiene un botón **«Guías de pliegue»** que muestra/oculta esas líneas y
   las etiquetas de panel (útiles para montarlo la primera vez).

## Exportar / regenerar PDF

Con el navegador (lo más simple): abre el `.html` → **«Imprimir / Guardar PDF»**
→ A4, márgenes **ninguno**, **gráficos de fondo** activados.

O por línea de comandos (Brave/Chromium + CDP):

```sh
cd docs/folleto
brave --headless=new --no-sandbox --disable-gpu \
  --remote-debugging-port=9223 --user-data-dir=/tmp/bp \
  "file://$PWD/dirty-road-triptico.html" & sleep 3
node tools/generar-pdf.mjs 9223 dirty-road-triptico.html DirtyRoad-triptico
```

Cambia el HTML y el prefijo para el folleto recto
(`dirty-road-folleto.html DirtyRoad-folleto`).

## Dinamismo (solo pantalla)

En pantalla el HTML está vivo: el **contaminómetro** late, los paneles entran con
animación y las tarjetas reaccionan al pasar el ratón. Al imprimir, todo queda
estático y limpio.

## Personalizar

- **QR de descarga:** sustituye el `<div class="qr">…</div>` por una imagen, p. ej.
  `<img src="assets/mi-qr.png" style="width:100%;height:100%">`.
- **Capturas:** cambia cualquier `assets/etapa_XX.png` manteniendo el nombre.
- **Textos:** contenido en el HTML, en bloques numerados del `01` al `09`.
- **Colores:** el bloque `:root` al inicio de cada HTML concentra la paleta.

## Sincronía

Los datos de las etapas espejan `web/src/lib/etapas.ts` y
`scripts/education/education_data_stages.gd`. Si cambian en el juego, actualiza
también estas piezas.
