#!/usr/bin/env python3
"""Monta un trailer MP4 (1080p) a partir de clips de vídeo.

Une clips con crossfades (xfade), añade portada y cierre (drawtext) y, si se
indica, un rótulo por clip. Normaliza cada clip a la misma duración/ tamaño.

Uso:
  tools/montaje_clips.py salida.mp4 clip1 clip2 ... \
      [--titulos "T1;T2;..."] [--dur 2.8] [--xfade 0.6] [--fps 30]
"""
import argparse
import os
import subprocess
import sys
import tempfile

FONT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "themes",
                                    "Chakra_Petch", "ChakraPetch-Bold.ttf"))
W, H = 1920, 1080


def card(path, titulo, sub):
    vf = (
        f"drawtext=fontfile='{FONT}':text='{titulo}':fontcolor=0x99ff33:"
        f"fontsize=170:x=(w-text_w)/2:y=(h-text_h)/2-60:"
        f"borderw=7:bordercolor=0x06120b,"
        f"drawtext=fontfile='{FONT}':text='{sub}':fontcolor=0xcfd8d3:"
        f"fontsize=54:x=(w-text_w)/2:y=(h-text_h)/2+120:"
        f"borderw=4:bordercolor=0x06120b"
    )
    subprocess.run(["ffmpeg", "-y", "-f", "lavfi",
                    "-i", f"color=c=0x0a1a12:s={W}x{H}",
                    "-vf", vf, "-frames:v", "1", path],
                   check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("salida")
    ap.add_argument("clips", nargs="+")
    ap.add_argument("--titulos", default="")
    ap.add_argument("--dur", type=float, default=2.8)
    ap.add_argument("--xfade", type=float, default=0.6)
    ap.add_argument("--fps", type=int, default=30)
    args = ap.parse_args()

    titulos = args.titulos.split(";") if args.titulos else []
    if titulos and len(titulos) != len(args.clips):
        print("[montaje] nº de titulos != nº de clips"); sys.exit(1)

    tmp = tempfile.mkdtemp(prefix="trailer_")
    inicio = os.path.join(tmp, "00.png")
    cierre = os.path.join(tmp, "99.png")
    card(inicio, "DIRTY ROAD", "SALVA EL BOSQUE")
    card(cierre, "DIRTY ROAD", "UN ECOSISTEMA QUE RESISTE")

    entradas = [(inicio, "img", None)]
    for i, c in enumerate(args.clips):
        entradas.append((c, "vid", titulos[i] if titulos else None))
    entradas.append((cierre, "img", None))

    cmd = ["ffmpeg", "-y"]
    for path, kind, _ in entradas:
        if kind == "img":
            cmd += ["-loop", "1", "-t", str(args.dur), "-i", path]
        else:
            cmd += ["-i", path]

    D, XF = args.dur, args.xfade
    filtros = []
    for i, (_, kind, tit) in enumerate(entradas):
        f = (f"[{i}:v]scale={W}:{H}:force_original_aspect_ratio=increase,"
             f"crop={W}:{H},setsar=1")
        if kind == "vid":
            f += f",trim=duration={D},setpts=PTS-STARTPTS"
        f += f",fps={args.fps}"
        if tit:
            f += (f",drawtext=fontfile='{FONT}':text='{tit}':"
                  f"fontcolor=0xffffff:fontsize=44:x=(w-text_w)/2:y=h-150:"
                  f"box=1:boxcolor=0x06120b@0.55:boxborderw=18:"
                  f"borderw=3:bordercolor=0x06120b")
        f += f"[v{i}]"
        filtros.append(f)

    actual = "v0"
    paso = D - XF
    for i in range(1, len(entradas)):
        offset = i * paso
        out = f"x{i}"
        filtros.append(f"[{actual}][v{i}]xfade=transition=fade:"
                       f"duration={XF}:offset={offset:.3f}[{out}]")
        actual = out

    cmd += ["-filter_complex", ";".join(filtros), "-map", f"[{actual}]",
            "-c:v", "libx264", "-pix_fmt", "yuv420p", "-crf", "20",
            "-preset", "medium", "-r", str(args.fps),
            "-movflags", "+faststart", args.salida]

    print(f"[montaje] {len(entradas)} piezas → {args.salida}")
    subprocess.run(cmd, check=True)


if __name__ == "__main__":
    main()