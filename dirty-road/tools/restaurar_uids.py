#!/usr/bin/env python3
"""Restaura los `uid` de recursos (.tres/.tscn) tras regenerarlos.

El generador (ejecutado con `godot --script`) guarda con `ResourceSaver` fuera
del editor, que NO escribe el atributo `uid="uid://..."`. Eso deja referencias
por UID inválidas (warnings). Este script copia el uid del encabezado y de cada
`[ext_resource]` (emparejando por `path`) desde la versión de git HEAD.

Uso:  tools/restaurar_uids.py [rutas...]
      (sin rutas: todos los .tres/.tscn modificados bajo ecenes/enemies)
"""
import os
import re
import subprocess
import sys

PROJ = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
GITROOT = subprocess.check_output(
    ["git", "-C", PROJ, "rev-parse", "--show-toplevel"], text=True).strip()

HEADER_RE = re.compile(r'^\[gd_(?:resource|scene)[^\]]*\]', re.M)
EXT_RE = re.compile(r'^\[ext_resource\b[^\]]*\]', re.M)
NODE_RE = re.compile(r'^\[node\b[^\]]*\]', re.M)
UID_RE = re.compile(r'\buid="(uid://[^"]+)"')
PATH_RE = re.compile(r'\bpath="([^"]+)"')
NAME_RE = re.compile(r'\bname="([^"]+)"')
PARENT_RE = re.compile(r'\bparent="([^"]+)"')
UNIQUE_RE = re.compile(r'\bunique_id=(\d+)')


def head_content(path):
    rel = os.path.relpath(path, GITROOT)
    try:
        return subprocess.check_output(
            ["git", "-C", GITROOT, "show", f"HEAD:{rel}"], text=True)
    except subprocess.CalledProcessError:
        return None


def header_uid(text):
    m = HEADER_RE.search(text)
    if not m:
        return None
    u = UID_RE.search(m.group(0))
    return u.group(1) if u else None


def ext_uid_map(text):
    out = {}
    for m in EXT_RE.finditer(text):
        line = m.group(0)
        u = UID_RE.search(line)
        p = PATH_RE.search(line)
        if u and p:
            out[p.group(1)] = u.group(1)
    return out


def node_unique_map(text):
    """(name, parent) -> unique_id, para conservar la identidad de nodos."""
    out = {}
    for m in NODE_RE.finditer(text):
        line = m.group(0)
        n = NAME_RE.search(line)
        u = UNIQUE_RE.search(line)
        if not (n and u):
            continue
        p = PARENT_RE.search(line)
        out[(n.group(1), p.group(1) if p else "")] = u.group(1)
    return out


def patch(new, old):
    changed = False
    # 1) uid del encabezado [gd_resource]/[gd_scene].
    h_old = header_uid(old)
    if h_old:
        m = HEADER_RE.search(new)
        if m and 'uid="' not in m.group(0):
            new = HEADER_RE.sub(lambda mm: mm.group(0)[:-1] + f' uid="{h_old}"]',
                                new, count=1)
            changed = True
    # 2) uid de cada [ext_resource] (por path).
    emap = ext_uid_map(old)
    if emap:
        lines = new.splitlines(keepends=True)
        for i, ln in enumerate(lines):
            if ln.startswith("[ext_resource") and 'uid="' not in ln:
                p = PATH_RE.search(ln)
                if p and p.group(1) in emap:
                    lines[i] = re.sub(r'(\[ext_resource\s+type="[^"]*")',
                                      r'\1 uid="%s"' % emap[p.group(1)], ln, count=1)
                    changed = True
        new = "".join(lines)
    # 3) unique_id de nodos (el script los reasigna al azar → churn).
    nmap = node_unique_map(old)
    if nmap:
        byname = {}
        for (nm, _par), uid in nmap.items():
            byname.setdefault(nm, uid)
        lines = new.splitlines(keepends=True)
        for i, ln in enumerate(lines):
            if not ln.startswith("[node"):
                continue
            n = NAME_RE.search(ln)
            u = UNIQUE_RE.search(ln)
            if not (n and u):
                continue
            p = PARENT_RE.search(ln)
            key = (n.group(1), p.group(1) if p else "")
            objetivo = nmap.get(key, byname.get(n.group(1)))
            if objetivo is not None and u.group(1) != objetivo:
                lines[i] = re.sub(r'\bunique_id=\d+', f'unique_id={objetivo}', ln, count=1)
                changed = True
        new = "".join(lines)
    return new, changed


def archivos_objetivo(args):
    if args:
        return [os.path.abspath(a) for a in args]
    # core.quotepath=false: sin escapar rutas no-ASCII (p. ej. "montaña").
    rels = subprocess.check_output(
        ["git", "-C", GITROOT, "-c", "core.quotepath=false",
         "diff", "--name-only", "HEAD"],
        text=True).splitlines()
    out = []
    for rel in rels:
        if not (rel.endswith(".tres") or rel.endswith(".tscn")):
            continue
        if "ecenes/enemies" not in rel:
            continue
        out.append(os.path.join(GITROOT, rel))
    return out


def main():
    total = cambios = 0
    for path in archivos_objetivo(sys.argv[1:]):
        if not os.path.isfile(path):
            continue
        total += 1
        old = head_content(path)
        with open(path, encoding="utf-8") as f:
            new = f.read()
        if old is None:
            continue
        nuevo, changed = patch(new, old)
        if changed:
            with open(path, "w", encoding="utf-8") as f:
                f.write(nuevo)
            cambios += 1
    print(f"[uids] revisados={total}  reescritos={cambios}")


if __name__ == "__main__":
    main()