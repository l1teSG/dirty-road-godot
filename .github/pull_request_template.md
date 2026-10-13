# Plantilla de Pull Request · Pull Request Template

<!--
🇪🇸 Rellena las secciones aplicables y borra las que no lo sean.
🇬🇧 Fill in the applicable sections and delete the rest.
-->

## 📝 Descripción · Description

<!-- ¿Qué cambia y por qué? / What changes and why? -->

## 🔗 Issue relacionada · Related issue

<!-- Closes #... / Refs #... -->

## 🧩 Tipo de cambio · Type of change

- [ ] `feature:` — Nueva funcionalidad · New feature
- [ ] `fix:` — Corrección de errores · Bug fix
- [ ] `add:` — Contenido/archivos nuevos · New content/files
- [ ] `chore:` — Mantenimiento/limpieza · Maintenance/cleanup
- [ ] 🚨 Cambio que rompe compatibilidad · Breaking change
- [ ] 📄 Solo documentación · Docs only

## 📦 Ámbito · Scope

- [ ] Juego (`dirty-road/`) · Game
- [ ] Web (`web/`)
- [ ] Documentación / repositorio · Docs / repository

## 🧪 Cómo se probó · How it was tested

<!-- Pasos para verificar el cambio. / Steps to verify the change. -->

- [ ] El juego arranca sin errores · Game boots without errors
- [ ] `godot --headless --script res://tools/verificar_enemigos.gd` pasa
- [ ] `npm run build` en `web/` pasa · passes
- [ ] Probado en dispositivo/emulador Android · Tested on Android

## ✅ Checklist

- [ ] Rama `feature/<tema>` creada desde `main` actualizada · Branch from up-to-date `main`
- [ ] *Commits* atómicos y con prefijo correcto · Atomic commits with correct prefix
- [ ] Sin archivos ignorados (`apk/`, `assets/`, `addons/`, `.godot/`) · No ignored files
- [ ] No se editaron `*.uid` · `*.uid` files untouched
- [ ] Se respetaron las reglas duras (`WaveManager`, `SaveManager`, `EtapaConfig`)
- [ ] Código/datos documentados (por qué y contratos) · Documented code/data

## 📸 Capturas / Evidencia · Screenshots / Evidence

<!-- Antes/Después si aplica. / Before/after if applicable. -->
