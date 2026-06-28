#!/usr/bin/env python3
"""Split the slice's roads into per-500 m tile pieces (tiles/r_X_Y.json), so the
Godot world can STREAM road meshes near the player instead of building all ~38k
roads at load. Polylines are cut at tile boundaries by segment-midpoint tile and
grouped into contiguous pieces, so each tile self-contains the roads passing
through it (original road endpoints are preserved, which the stop-bar / crosswalk
junction logic relies on). Roads stay in the slice too (the minimap / big map
read them); this only adds the tiled copy for 3D streaming.
"""
import json, math, os
from collections import defaultdict

HERE = os.path.dirname(os.path.abspath(__file__))
MAP = os.path.normpath(os.path.join(HERE, "..", "..", "QUAHOG_GODOT1", "data", "map"))
SLICE = os.path.join(MAP, "slice-newbedford.json")
TILES = os.path.join(MAP, "tiles")
TILE = 500.0

s = json.load(open(SLICE))
roads = s["roads"]

# clear old road tiles
for f in os.listdir(TILES):
    if f.startswith("r_") and f.endswith(".json"):
        os.remove(os.path.join(TILES, f))

buckets = defaultdict(list)
pieces = 0
for r in roads:
    pts = r.get("points") or []
    if len(pts) < 2:
        continue
    hw = r.get("highway", "residential")
    width = r.get("width", 6)
    name = r.get("name")
    cur_key = None
    cur = []
    for i in range(len(pts) - 1):
        a = pts[i]; b = pts[i + 1]
        mx = (a[0] + b[0]) * 0.5; mn = (a[1] + b[1]) * 0.5
        key = (int(math.floor(mx / TILE)), int(math.floor(mn / TILE)))
        if key != cur_key:
            if len(cur) >= 2:
                buckets[cur_key].append({"highway": hw, "width": width, "name": name, "points": cur})
                pieces += 1
            cur = [a]
            cur_key = key
        cur.append(b)
    if len(cur) >= 2:
        buckets[cur_key].append({"highway": hw, "width": width, "name": name, "points": cur})
        pieces += 1

for (kx, ky), arr in buckets.items():
    json.dump(arr, open(os.path.join(TILES, f"r_{kx}_{ky}.json"), "w"))

print(f"road tiles={len(buckets)} pieces={pieces} from {len(roads)} roads")
