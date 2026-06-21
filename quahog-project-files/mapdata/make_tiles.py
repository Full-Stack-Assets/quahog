import json, os, math
from collections import defaultdict

# Split the baked slice's BUILDINGS into a tile grid so the web client can stream
# only the tiles near the player (Step 19). Roads/water/landmarks stay in the
# main slice (comparatively light). Reads the already-baked slice; writes a
# manifest + one file per non-empty tile under QUAHOG_Web/public/tiles/.

_HERE = os.path.dirname(os.path.abspath(__file__))
SLICE = os.path.normpath(os.path.join(_HERE, "..", "..", "QUAHOG_Web", "public", "slice-newbedford.json"))
OUTDIR = os.path.normpath(os.path.join(_HERE, "..", "..", "QUAHOG_Web", "public", "tiles"))
TILE = 500  # metres

s = json.load(open(SLICE))
os.makedirs(OUTDIR, exist_ok=True)
# clear old tiles
for f in os.listdir(OUTDIR):
    if f.endswith(".json"):
        os.remove(os.path.join(OUTDIR, f))

def centroid(fp):
    n = len(fp)
    return (sum(p[0] for p in fp) / n, sum(p[1] for p in fp) / n)

buckets = defaultdict(list)
for b in s["buildings"]:
    cx, cn = centroid(b["footprint"])
    key = f"{math.floor(cx / TILE)}_{math.floor(cn / TILE)}"
    buckets[key].append(b)

for key, blds in buckets.items():
    json.dump(blds, open(os.path.join(OUTDIR, f"b_{key}.json"), "w"))

manifest = {
    "tile": TILE,
    "origin": s["origin"],
    "keys": sorted(buckets.keys()),
    "count": sum(len(v) for v in buckets.values()),
}
json.dump(manifest, open(os.path.join(OUTDIR, "manifest.json"), "w"))

# slim the main slice: buildings now stream from tiles, so drop them from the
# monolithic file (roads/water/landmarks stay) — big load-time win.
nb = len(s["buildings"])
s["buildings"] = []
s["buildingsStreamed"] = True
json.dump(s, open(SLICE, "w"))
print(f"tiles={len(buckets)} buildings={manifest['count']} (stripped {nb} from slice) TILE={TILE}m")
print(f"slice now: {os.path.getsize(SLICE)/1024:.0f} KB")
