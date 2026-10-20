#!/usr/bin/env python3
"""Genera los guiones JSON del modo trailer a partir de las escenas reales.

Salida: dirty-road/tools/trailers/*.json
  · general.json          (~42 s)  menú + HUD + horda + ajustes + cartas + jefes
  · etapa_01..10.json     (~14 s)  enemigos de la etapa + su jefe
  · jefe_01..10.json      (~9 s)   presentación del jefe

Uso:  python3 tools/generar_guiones_trailers.py
"""
import json
import os
import glob

AQUI = os.path.dirname(os.path.abspath(__file__))
RAIZ = os.path.dirname(AQUI)
SALIDA = os.path.join(AQUI, "trailers")

TEMAS = [
    "Contaminación del suelo y el aire", "Basura y vertederos", "Océanos y plástico",
    "Contaminación industrial", "Lluvia ácida", "Residuos electrónicos",
    "Energía nuclear y radiación", "Pesticidas y agricultura", "Deforestación",
    "Cambio climático",
]
RANGOS = ["1-10", "11-20", "21-30", "31-40", "41-50",
          "51-60", "61-70", "71-80", "81-90", "91-100"]


def res(p):
    """Ruta de un archivo del proyecto a 'res://...'."""
    rel = os.path.relpath(os.path.abspath(p), RAIZ).replace(os.sep, "/")
    return "res://" + rel


def titulo_de(ruta):
    return os.path.basename(ruta).replace(".tscn", "").replace("_enemi", "").replace("_boss", "")


def catalogo():
    cat = []
    base = os.path.join(RAIZ, "ecenes", "enemies", "main")
    for i, rango in enumerate(RANGOS):
        enemis = sorted(glob.glob(os.path.join(base, rango, "*", "*_enemi.tscn")))
        boss = sorted(glob.glob(os.path.join(base, rango, "boss", "*_boss.tscn")))
        cat.append({
            "num": i + 1,
            "tema": TEMAS[i],
            "enemigos": [res(e) for e in enemis],
            "jefe": res(boss[0]) if boss else "",
            "jefe_nombre": titulo_de(boss[0]) if boss else "Jefe",
        })
    return cat


def guion(nombre, pasos, fps=60):
    pasos = sorted(pasos, key=lambda p: p["t"])
    dur = round(pasos[-1]["t"] + 3.0, 2)
    return {"nombre": nombre, "fps": fps, "duracion": dur, "pasos": pasos}


def paso(t, accion, **kw):
    p = {"t": round(t, 2), "accion": accion}
    p.update(kw)
    return p


def guion_general(cat):
    p = [
        paso(0.0, "fundido", color="negro", dur=0.6, salir=True),
        paso(0.2, "hud", valor=False),
        paso(0.3, "pantalla", valor="menu"),
        paso(0.4, "titulo", texto="DIRTY ROAD", sub="SALVA EL BOSQUE", dur=2.6),
        paso(3.4, "pantalla", valor="off"),
        # ── gameplay / horda ──
        paso(3.6, "hud", valor=True),
        paso(3.7, "camara", pos=[0, -40], zoom=1.30, dur=2.2, ease="out"),
        paso(3.9, "formacion", escena=cat[0]["enemigos"][0], n=6, radio=210,
             pos=[0, 40], congelado=False),
        paso(4.3, "formacion", escena=cat[1]["enemigos"][0], n=4, radio=320,
             pos=[0, 40], congelado=False),
        paso(5.0, "spawn", escena=cat[0]["enemigos"][1], pos=[140, -120], congelado=False),
        paso(5.4, "spawn", escena=cat[0]["enemigos"][2], pos=[-150, -90], congelado=False),
        paso(7.4, "slowmo", valor=0.4, dur=1.0),
        paso(9.4, "matar_todos"),
        # ── ajustes ──
        paso(9.9, "hud", valor=False),
        paso(10.1, "pantalla", valor="ajustes"),
        paso(12.1, "pantalla", valor="off"),
        paso(12.3, "hud", valor=True),
        # ── cartas ──
        paso(12.5, "camara", pos=[0, -30], zoom=1.15, dur=1.6, ease="out"),
        paso(12.7, "cartas", valor=True),
        paso(15.8, "cartas", valor=False),
        # ── jefe 1 en acción ──
        paso(16.1, "hud", valor=False),
        paso(16.2, "spawn", escena=cat[0]["jefe"], pos=[0, -280], congelado=False),
        paso(16.4, "camara", pos=[0, -280], zoom=1.15, dur=1.8, ease="out"),
        paso(17.0, "titulo", texto="JEFE", sub=cat[0]["jefe_nombre"], dur=1.8),
        paso(20.0, "matar_todos"),
        # ── montaje de jefes 2..10 ──
        paso(20.4, "hud", valor=True),
    ]
    t = 20.6
    for etapa in cat[1:]:
        p.append(paso(t, "fundido", color="negro", dur=0.4))
        p.append(paso(t + 0.4, "spawn", escena=etapa["jefe"], pos=[0, -260], congelado=True))
        p.append(paso(t + 0.4, "camara", pos=[0, -260], zoom=1.12, dur=1.2, ease="out"))
        p.append(paso(t + 0.5, "titulo", texto="ETAPA %d" % etapa["num"], sub=etapa["tema"], dur=1.0))
        p.append(paso(t + 2.0, "matar_todos"))
        t += 2.1
    p.append(paso(t + 0.2, "camara", pos=[0, 0], zoom=1.0, dur=1.4, ease="out"))
    p.append(paso(t + 0.3, "titulo", texto="DIRTY ROAD", sub="Mantén vivo el ecosistema", dur=2.0))
    p.append(paso(t + 2.6, "fundido", color="negro", dur=1.0))
    p.append(paso(t + 3.8, "fin"))
    return guion("general", p)


def guion_etapa(cat):
    e = cat
    return guion("etapa_%02d" % e["num"], [
        paso(0.0, "fundido", color="negro", dur=0.5, salir=True),
        paso(0.2, "hud", valor=True),
        paso(0.3, "titulo", texto="ETAPA %d" % e["num"], sub=e["tema"], dur=2.2),
        paso(0.5, "camara", pos=[0, -50], zoom=1.30, dur=2.0, ease="out"),
        paso(0.7, "formacion", escena=e["enemigos"][0], n=5, radio=200,
             pos=[0, 40], congelado=False),
        paso(1.1, "formacion", escena=e["enemigos"][1], n=4, radio=300,
             pos=[0, 40], congelado=False),
        paso(1.6, "spawn", escena=e["enemigos"][2], pos=[150, -130], congelado=False),
        paso(3.6, "hud", valor=False),
        paso(3.7, "camara", pos=[0, 20], zoom=1.05, dur=2.0, ease="out"),
        paso(5.2, "slowmo", valor=0.4, dur=1.2),
        paso(7.4, "matar_todos"),
        paso(7.9, "hud", valor=True),
        paso(8.0, "spawn", escena=e["jefe"], pos=[0, -270], congelado=True),
        paso(8.1, "camara", pos=[0, -270], zoom=1.14, dur=1.6, ease="out"),
        paso(8.4, "titulo", texto="JEFE", sub=e["jefe_nombre"], dur=1.8),
        paso(11.0, "fundido", color="negro", dur=0.8),
        paso(12.0, "fin"),
    ])


def guion_jefe(cat):
    e = cat
    return guion("jefe_%02d" % e["num"], [
        paso(0.0, "fundido", color="negro", dur=0.5, salir=True),
        paso(0.1, "hud", valor=True),
        paso(0.2, "camara", pos=[0, -330], zoom=1.18, dur=1.6, ease="out"),
        paso(0.4, "spawn", escena=e["jefe"], pos=[0, -300], congelado=False),
        paso(0.5, "titulo", texto="JEFE", sub=e["jefe_nombre"], dur=2.0),
        paso(3.4, "camara", pos=[0, -230], zoom=1.30, dur=1.6, ease="out"),
        paso(3.6, "slowmo", valor=0.35, dur=1.6),
        paso(5.6, "camara", pos=[0, -120], zoom=1.45, dur=1.6, ease="out"),
        paso(7.6, "fundido", color="negro", dur=0.8),
        paso(8.8, "fin"),
    ])


def main():
    os.makedirs(SALIDA, exist_ok=True)
    cat = catalogo()
    escritos = []
    for nombre, g in (
        [("general", guion_general(cat))]
        + [("etapa_%02d" % c["num"], guion_etapa(c)) for c in cat]
        + [("jefe_%02d" % c["num"], guion_jefe(c)) for c in cat]
    ):
        ruta = os.path.join(SALIDA, nombre + ".json")
        with open(ruta, "w", encoding="utf-8") as f:
            json.dump(g, f, ensure_ascii=False, indent=2)
        escritos.append((nombre, g["duracion"], len(g["pasos"])))
    for n, d, k in escritos:
        print("  %-12s %5.1fs  %2d pasos" % (n, d, k))
    print("Guiones escritos en", SALIDA)


if __name__ == "__main__":
    main()
