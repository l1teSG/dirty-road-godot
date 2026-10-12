# 🧾 Changelog — Dirty Road

Todos los cambios relevantes del proyecto. Formato inspirado en
[Keep a Changelog](https://keepachangelog.com/es/1.0.0/).

## [10.1.2] — 2026-10

Versión enfocada en **pulido de contenido, presentación e interfaz**.

### Añadido
- **Figuras vectoriales de las 84 cartas** de mejora (antes la mitad salían en blanco).
- **Feedback visual de biomasa** al comprar una mejora en la pantalla de cartas
  (destello + `-coste` flotante).
- **Nuevos ajustes** y pestaña **Accesibilidad**:
  - General: FPS, flecha al árbol, cartel de oleada, confirmar compra, pausar al
    perder el foco, pantalla completa.
  - Combate: disparo continuo manual, asistencia de apuntado, zoom de cámara.
  - Accesibilidad: reducir destellos, reducir partículas, vibración, silenciar
    audio en segundo plano.
- **Modo zurdo** y escalas separadas de botones/joystick del HUD.
- **Icono del juego** (escritorio + Android) y **material promocional**
  (banner, imagen social, feature graphic, favicon).

### Cambiado
- La **selección de mejoras** ahora espera a que se recojan todos los orbes de fin
  de oleada antes de aparecer.
- Los mensajes del arranque se muestran **en orden**: primero el popup de etapa
  ("ETAPA 1"), después el cartel "HORDA".

### Corregido
- **Modo sin disparo automático**: la mira ya no se engancha a los enemigos;
  respeta el joystick de apuntado (también en modo zurdo).

---

## Historial de versiones anteriores

> El detalle fino de estas versiones no está documentado aquí; se listan por los
> APK generados en `apk/` y los tags del repositorio.

| Versión | Notas |
| :--- | :--- |
| **10.1.1** | Iteración previa de la rama 10.x (APK `dirtyRoad_V10.1.1.apk`). |
| **10.1.0** | Primera iteración estable de la rama 10.x (APK `dirtyRoad_V10.1.0.apk`). |
| **10.0.0 beta** | Versión beta etiquetada 10.0.0. |
| **2.7.0** | Rama 2.7 (tag `v2.7`). |
| **2.6.x** | `v2.6.0`, `v2.6.1`, `v2.6.2`, `v2.6.9`. |
| **2.5.x** | `v2.5.0` (tag), `v2.5.1`, `v2.5.2`. |
| **2.0.1** | Rama 2.0 (tag `v2`). |

---

## Convención de versiones

- Formato `MAYOR.MENOR.PARCHE`.
- El número vive en `dirty-road/project.godot` (`config/version`).
- Los **APK** se nombran `dirtyRoad_V<versión>.apk` y **no** se versionan en git.
