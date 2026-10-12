#!/usr/bin/env python3
"""Monta un trailer MP4 (1080p) a partir de capturas PNG.

Genera una portada y un cierre con drawtext, aplica Ken Burns (zoompan) a
cada imagen y las une con crossfades (xfade). Usa ffmpeg.

Uso:
  tools/montaje_trailer.py <carpeta_imagenes> <salida.mp4> [--dur 2.6] [--fps 30]

Las imágenes se ordenan por nombre. Se buscan *.png de forma recursiva.
"""
import argparse
import glob
import os
import subprocess
import sys

FONT = os.path.join(os.path.dirname(__file__), "..", "themes",
                    "Chakra_Petch", "ChakraPetch-Bold.ttf")


def card(path, titulo, sub, color_t="#99ff33"):
    """Genera un PNG de portada/cierre con ffmpeg drawtext."""
    font = os.path.abspath(FONT)
    vf = (
        f"drawtext=fontfile='{font}':text='{titulo}':fontcolor={color_t}:"
        f"fontsize=180:x=(w-text_w)/2:y=(h-text_h)/2-70:"
        f"borderw=6:bordercolor=0x06120b,"
        f"drawtext=fontfile='{font}':text='{sub}':fontcolor=0xcfd8d3:"
        f"fontsize=58:x=(w-text_w)/2:y=(h-text_h)/2+120:"
        f"borderw=4:bordercolor=0x06120b"
    )
    subprocess.run([
        "ffmpeg", "-y", "-f", "lavfi",
        "-i", "color=c=0x0a1a12:s=1920x1080",
        "-vf", vf, "-frames:v", "1", path,
    ], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("carpeta")
    ap.add_argument("salida")
    ap.add_argument("--dur", type=float, default=2.6)
    ap.add_argument("--fps", type=int, default=30)
    ap.add_argument("--xfade", type=float, default=0.7)
    args = ap.parse_args()

    W, H = 1920, 1080
    todos = glob.glob(os.path.join(args.carpeta, "**", "*.png"), recursive=True)
    # Etapas primero, luego enemigos/jefes; cada grupo ordenado por nombre.
    imgs = sorted(todos, key=lambda p: (0 if "etapas" in p else 1, p))
    if not imgs:
        print("No hay PNG en", args.carpeta)
        sys.exit(1)

    tmp = os.path.join(os.path.dirname(os.path.abspath(args.salida)), "_cards")
    os.makedirs(tmp, exist_ok=True)
    inicio = os.path.join(tmp, "00_inicio.png")
    cierre = os.path.join(tmp, "99_cierre.png")
    card(inicio, "DIRTY ROAD", "SALVA EL BOSQUE")
    card(cierre, "DIRTY ROAD", "UN ECOSISTEMA QUE RESISTE")

    entradas = [inicio] + imgs + [cierre]
    n = len(entradas)
    frames = max(1, int(args.dur * args.fps))

    cmd = ["ffmpeg", "-y"]
    for p in entradas:
        cmd += ["-i", p]

    filtros = []
    for i in range(n):
        filtros.append(
            f"[{i}:v]scale={W}:{H}:force_original_aspect_ratio=increase,"
            f"crop={W}:{H},setsar=1,"
            f"zoompan=z='min(zoom+0.0006,1.12)':"
            f"x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':"
            f"d={frames}:s={W}x{H}:fps={args.fps},format=yuv420p[v{i}]"
        )

    # Cadena de crossfades.
    paso = args.dur - args.xfade
    actual = "v0"
    for i in range(1, n):
        offset = i * paso
        out = f"x{i}"
        filtros.append(
            f"[{actual}][v{i}]xfade=transition=fade:"
            f"duration={args.xfade}:offset={offset:.3f}[{out}]"
        )
        actual = out

    cmd += ["-filter_complex", ";".join(filtros), "-map", f"[{actual}]",
            "-c:v", "libx264", "-pix_fmt", "yuv420p", "-crf", "20",
            "-preset", "medium", "-r", str(args.fps),
            "-movflags", "+faststart", args.salida]

    print(f"[montaje] {n} piezas → {args.salida}")
    subprocess.run(cmd, check=True)


if __name__ == "__main__":
    main()