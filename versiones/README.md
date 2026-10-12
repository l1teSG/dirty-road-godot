# 📦 Versiones — Dirty Road

Notas de release y changelog del proyecto **Dirty Road**.

- **Versión actual:** [`v10.1.2`](./v10.1.2.md)
- **Historial completo:** [`CHANGELOG.md`](./CHANGELOG.md)

---

## 🗂️ Índice de versiones

| Versión | Estado | Notas |
| :--- | :--- | :--- |
| **v10.1.2** | ✅ Actual | [Notas de la release](./v10.1.2.md) |
| v10.1.1 | Anterior | Correcciones y ajustes de contenido |
| v10.1.0 | Anterior | Iteración de la versión 10 |
| 10.0.0 beta | Beta | Primera versión etiquetada como 10.x |
| v2.7.0 | Histórica | Rama 2.7 |
| v2.6.x | Histórica | `v2.6.0`, `v2.6.1`, `v2.6.2`, `v2.6.9` |
| v2.5.x | Histórica | `v2.5.0`, `v2.5.1`, `v2.5.2` |
| v2.0.1 | Histórica | Rama 2.0 |

---

## 🚀 Cómo publicar una release en GitHub

1. **Crea el tag** (desde el commit que quieras publicar):
   ```sh
   git tag -a v10.1.2 -m "Dirty Road v10.1.2"
   git push origin v10.1.2
   ```
2. **En GitHub → Releases → Draft a new release**:
   - *Tag*: `v10.1.2`
   - *Title*: `Dirty Road v10.1.2`
   - *Description*: pega el contenido de [`v10.1.2.md`](./v10.1.2.md).
3. **Adjunta el APK** como *asset*: `apk/dirtyRoad_V10.1.2.apk`
   (la carpeta `apk/` **no** está versionada; el binario vive en la release).
4. Publica.

> 🎮 Para PC: se recomienda compilar desde el proyecto (`dirty-road/`) con Godot 4.7.

---

## 📄 Licencia

**Todos los derechos reservados.** Software propietario. No se concede permiso de
uso, copia, modificación ni distribución sin autorización previa por escrito.
Consulta [`../LICENSE`](../LICENSE).
