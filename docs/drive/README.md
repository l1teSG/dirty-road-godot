# Drive · Dirty Road — paquete de entrega

Copias listas para subir o entregar, una carpeta por entregable. Las **fuentes
editables** viven fuera de `drive/` (en `docs/`), así que aquí solo se toca lo que
se entrega.

```
docs/drive/
├── apa/           APA.docx (vigente) · APA-word.docx (editable para subir)
├── rae/           RAE.docx
├── folleto/       folleto.pdf (A4 doble cara) · triptico.pdf (zigzag)
├── manual/        Manual-de-Usuario.pdf
├── poster/        Poster-DirtyRoad-2026.pdf
└── presentacion/  presentacion.pptx
```

## Versiones vigentes y de dónde salen

| Archivo | Fuente | Nota |
| :--- | :--- | :--- |
| `apa/APA.docx` | venía del Drive del proyecto | La **vigente**: portada 2026, "Godot Engine 4.7" y licencia MIT. Ya no trae la tabla de controles obsoleta ("Sembrar · Espacio", "Inventario · Tab"). |
| `apa/APA-word.docx` | venía del Drive del proyecto | Versión editable para entregar; conserva las fuentes incrustadas (Inter, Liberation Serif…) a propósito, para que se vea igual en cualquier equipo. |
| `rae/RAE.docx` | venía del Drive del proyecto | Resumen en el formato RAE institucional. Se le quitaron las fuentes incrustadas de LibreOffice (18 MB → 46 KB). |
| `folleto/folleto.pdf` | `docs/folleto/DirtyRoad-folleto-claro.pdf` | **Corregido**: el PDF que había aquí era en realidad el tríptico. Ahora es el folleto A4 a doble cara (versión clara, ahorra tinta). |
| `folleto/triptico.pdf` | `docs/folleto/DirtyRoad-triptico-claro.pdf` | Tríptico A4 con doblez en zigzag (Z-fold), versión clara. |
| `manual/Manual-de-Usuario.pdf` | `docs/manual/Manual-de-Usuario.pdf` | **Actualizado** a la versión corregida ("rewrite the user manual to match the game"). La copia anterior era una exportación vieja con la mitad del texto. |
| `presentacion/presentacion.pptx` | `docs/presentacion/presentacion.pptx` | **Actualizada** a la versión que coincide con el juego (22 diapositivas). |
| `poster/Poster-DirtyRoad-2026.pdf` | `docs/poster/Poster-DirtyRoad-2026.pdf` | No había póster en la carpeta de entrega. |

## Notas

- **Fuentes incrustadas**: si guardas los `.docx` desde LibreOffice, revisa
  *Archivo → Propiedades → Fuente → “Incrustar fuentes en el documento”*. Con esa
  opción activa el archivo crece a decenas de MB.
- **`*.odt` y `.~lock.*#`** están en `.gitignore`: no se versionan.
- `docs/APA.docx` (raíz) es la versión de **2025**: se conserva como histórico, pero
  lo vigente para entregar es `drive/apa/APA.docx`.
- Para regenerar el folleto y el tríptico: `docs/folleto/README.md`.