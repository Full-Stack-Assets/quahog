#!/usr/bin/env python3
"""
Derive island land polygons for the web slice.

Some small islands (Fish Island, Pope's Island in the Acushnet, etc.) carry roads
but are NOT cut out of the OSM water polygons, so in-game they render as open water
with a road floating on top — and (before the road-corridor fix) you'd sink on them.
This finds clusters of non-bridge road vertices that sit inside a water polygon,
convex-hulls each cluster and buffers it outward, and writes the hulls to
public/islands-<name>.json. The web app subtracts these as holes from the water
mesh (so they read as land) and treats them as land in the water barrier.

Usage: derive_islands.py public/slice-newbedford.json public/islands-newbedford.json
"""
import json
import math
import sys

GRID = 45.0       # clustering cell size (m): vertices within ~this distance merge
BUFFER = 16.0     # how far to grow each hull outward past its roads (m)
MIN_PTS = 5       # ignore clusters smaller than this (stray road over a pond)
MIN_SPAN = 35.0   # ignore clusters whose bbox diagonal is under this (m)
DRIVABLE = {"motorway", "trunk", "primary", "secondary", "tertiary", "residential",
            "unclassified", "living_street", "service", "motorway_link", "trunk_link",
            "primary_link", "secondary_link"}


def ring_bbox(ring):
    xs = [p[0] for p in ring]; ns = [p[1] for p in ring]
    return min(xs), max(xs), min(ns), max(ns)


def point_in_ring(px, pn, ring):
    inside = False
    n = len(ring); j = n - 1
    for i in range(n):
        xi, ni = ring[i]; xj, nj = ring[j]
        if ((ni > pn) != (nj > pn)) and (px < (xj - xi) * (pn - ni) / ((nj - ni) or 1e-9) + xi):
            inside = not inside
        j = i
    return inside


def convex_hull(pts):
    pts = sorted(set(pts))
    if len(pts) < 3:
        return pts
    def cross(o, a, b):
        return (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0])
    lower = []
    for p in pts:
        while len(lower) >= 2 and cross(lower[-2], lower[-1], p) <= 0:
            lower.pop()
        lower.append(p)
    upper = []
    for p in reversed(pts):
        while len(upper) >= 2 and cross(upper[-2], upper[-1], p) <= 0:
            upper.pop()
        upper.append(p)
    return lower[:-1] + upper[:-1]


def buffer_hull(hull, d):
    cx = sum(p[0] for p in hull) / len(hull)
    cn = sum(p[1] for p in hull) / len(hull)
    out = []
    for x, n in hull:
        dx, dn = x - cx, n - cn
        r = math.hypot(dx, dn) or 1.0
        out.append([round(cx + dx * (1 + d / r), 1), round(cn + dn * (1 + d / r), 1)])
    return out


def main():
    src, dst = sys.argv[1], sys.argv[2]
    s = json.load(open(src))
    water = s["water"]
    wb = [(*ring_bbox(r), r) for r in water]

    def in_any_water(px, pn):
        for x0, x1, n0, n1, ring in wb:
            if x0 <= px <= x1 and n0 <= pn <= n1 and point_in_ring(px, pn, ring):
                return True
        return False

    # collect non-bridge road vertices that sit over water
    verts = []
    for r in s["roads"]:
        if r.get("bridge") or r["highway"] not in DRIVABLE:
            continue
        for p in r["points"]:
            if in_any_water(p[0], p[1]):
                verts.append((p[0], p[1]))
    sys.stderr.write(f"[islands] {len(verts)} over-water road vertices\n")

    # grid clustering via union-find on occupied cells
    cell = {}
    for v in verts:
        cell.setdefault((int(v[0] // GRID), int(v[1] // GRID)), []).append(v)
    keys = list(cell.keys())
    idx = {k: i for i, k in enumerate(keys)}
    parent = list(range(len(keys)))
    def find(a):
        while parent[a] != a:
            parent[a] = parent[parent[a]]; a = parent[a]
        return a
    def union(a, b):
        parent[find(a)] = find(b)
    for (cx, cy) in keys:
        for dx in (-1, 0, 1):
            for dy in (-1, 0, 1):
                nb = (cx + dx, cy + dy)
                if nb in idx:
                    union(idx[(cx, cy)], idx[nb])

    clusters = {}
    for k in keys:
        clusters.setdefault(find(idx[k]), []).extend(cell[k])

    islands = []
    for pts in clusters.values():
        if len(pts) < MIN_PTS:
            continue
        x0, x1, n0, n1 = ring_bbox(pts)
        if math.hypot(x1 - x0, n1 - n0) < MIN_SPAN:
            continue
        hull = convex_hull([(round(p[0], 1), round(p[1], 1)) for p in pts])
        if len(hull) < 3:
            continue
        islands.append(buffer_hull(hull, BUFFER))

    json.dump(islands, open(dst, "w"))
    sys.stderr.write(f"[islands] wrote {len(islands)} island polygons to {dst}\n")
    for isl in sorted(islands, key=lambda h: -len(h))[:8]:
        x0, x1, n0, n1 = ring_bbox(isl)
        sys.stderr.write(f"   island {len(isl)} pts  x[{x0:.0f},{x1:.0f}] n[{n0:.0f},{n1:.0f}]\n")


if __name__ == "__main__":
    main()
