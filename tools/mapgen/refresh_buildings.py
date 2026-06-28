#!/usr/bin/env python3
"""Re-pull building footprints for a bbox with full OSM tags and REWRITE the
affected 500 m tiles (tiles/b_X_Y.json) with realistic heights, so a city reads
like the real world instead of a field of identical 8 m boxes.

Height model: use building:levels / height when tagged; otherwise infer from the
building TYPE (house / triple-decker / mill / church / downtown commercial …),
the footprint AREA, and proximity to the city's downtown anchor, with a little
deterministic per-footprint jitter so rows of houses vary. Projection is locked
to the New Bedford origin so it lines up with the existing world.
"""
import argparse, json, math, os, time, urllib.parse, urllib.request
from collections import defaultdict

HERE = os.path.dirname(os.path.abspath(__file__))
MAP = os.path.normpath(os.path.join(HERE, "..", "..", "QUAHOG_GODOT1", "data", "map"))
TILES = os.path.join(MAP, "tiles")
TILE = 500.0
OLAT, OLON = 41.636, -70.9205
M_LAT = 111320.0
M_LON = 111320.0 * math.cos(math.radians(OLAT))
def proj(lon, lat): return [round((lon - OLON) * M_LON, 2), round((lat - OLAT) * M_LAT, 2)]
HOSTS = ["https://overpass-api.de/api/interpreter", "https://overpass.kumi.systems/api/interpreter"]


def fetch(q):
    for host in HOSTS:
        for attempt in range(3):
            try:
                req = urllib.request.Request(host + "?data=" + urllib.parse.quote(q),
                                             headers={"User-Agent": "quahog-gamedev/1.0"})
                return json.loads(urllib.request.urlopen(req, timeout=180).read())
            except Exception as e:
                print(f"  ! {host} #{attempt+1}: {type(e).__name__} {e}"); time.sleep(5 * (attempt + 1))
    return None


def area_m2(ring):
    a = 0.0
    n = len(ring)
    for i in range(n):
        x1, y1 = ring[i]; x2, y2 = ring[(i + 1) % n]
        a += x1 * y2 - x2 * y1
    return abs(a) * 0.5


def infer_height(tags, area, dist, seedv):
    lv = tags.get("building:levels")
    if lv:
        try: return round(min(max(float(str(lv).split(";")[0]) * 3.3 + 1.0, 3.0), 140.0), 1)
        except ValueError: pass
    if tags.get("height"):
        try: return round(float(str(tags["height"]).split()[0]), 1)
        except ValueError: pass
    bt = tags.get("building", "yes")
    base = {
        "house": 7.5, "detached": 7.5, "bungalow": 6.5, "cabin": 5.0,
        "semidetached_house": 9.0, "terrace": 9.0, "townhouse": 9.5,
        "residential": 11.0, "apartments": 13.0, "dormitory": 13.0,
        "retail": 8.0, "commercial": 9.0, "kiosk": 4.0, "supermarket": 8.0,
        "office": 16.0, "hotel": 18.0,
        "industrial": 12.0, "warehouse": 11.0, "factory": 13.0, "manufacture": 13.0,
        "church": 16.0, "cathedral": 22.0, "chapel": 11.0, "mosque": 14.0, "temple": 14.0,
        "hospital": 18.0, "school": 11.0, "university": 16.0, "college": 14.0,
        "public": 12.0, "civic": 12.0, "government": 14.0,
        "garage": 3.0, "garages": 3.0, "shed": 3.0, "hut": 3.0, "roof": 3.0,
        "carport": 2.8, "greenhouse": 3.5, "service": 3.5,
    }.get(bt, 8.0)
    if area > 3000: base = max(base, 14.0)
    elif area > 1500: base = max(base, 11.0)
    elif area < 55: base = min(base, 4.0)
    if dist < 700.0: base *= 1.6
    elif dist < 1400.0: base *= 1.25
    base *= 0.85 + (seedv % 30) / 100.0
    return round(min(max(base, 3.0), 140.0), 1)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--s", type=float, required=True)
    ap.add_argument("--w", type=float, required=True)
    ap.add_argument("--n", type=float, required=True)
    ap.add_argument("--e", type=float, required=True)
    ap.add_argument("--ax", type=float, required=True, help="downtown anchor x (slice m)")
    ap.add_argument("--ay", type=float, required=True, help="downtown anchor y_north (slice m)")
    ap.add_argument("--strip", type=float, default=0.03)
    args = ap.parse_args()

    # tile range covered by the bbox (clear these b_ tiles, then rewrite)
    cs = proj(args.w, args.s); cn = proj(args.e, args.n)
    tx0, tx1 = int(math.floor(cs[0] / TILE)), int(math.floor(cn[0] / TILE))
    ty0, ty1 = int(math.floor(cs[1] / TILE)), int(math.floor(cn[1] / TILE))
    cleared = 0
    for f in os.listdir(TILES):
        if not (f.startswith("b_") and f.endswith(".json")):
            continue
        try:
            kx, ky = f[2:-5].split("_"); kx = int(kx); ky = int(ky)
        except ValueError:
            continue
        if tx0 <= kx <= tx1 and ty0 <= ky <= ty1:
            os.remove(os.path.join(TILES, f)); cleared += 1
    print(f"cleared {cleared} old b_ tiles in range x[{tx0}..{tx1}] y[{ty0}..{ty1}]")

    buckets = defaultdict(list)
    total = 0
    lat = args.s
    while lat < args.n - 1e-9:
        lat2 = min(lat + args.strip, args.n)
        q = f"[out:json][timeout:180];way({lat:.4f},{args.w:.4f},{lat2:.4f},{args.e:.4f})[building];out geom;"
        print(f"strip {lat:.3f}..{lat2:.3f} ...")
        data = fetch(q)
        if data is None:
            print("  FAILED"); lat = lat2; continue
        added = 0
        for el in data.get("elements", []):
            if el.get("type") != "way":
                continue
            t = el.get("tags", {})
            if not t.get("building"):
                continue
            ring = [proj(p["lon"], p["lat"]) for p in el.get("geometry", [])]
            if len(ring) >= 4 and ring[0] == ring[-1]:
                ring = ring[:-1]
            if len(ring) < 3:
                continue
            cx = sum(p[0] for p in ring) / len(ring)
            cn2 = sum(p[1] for p in ring) / len(ring)
            ar = area_m2(ring)
            dist = math.hypot(cx - args.ax, cn2 - args.ay)
            seedv = int(abs(ring[0][0] * 73856.0 + ring[0][1] * 19349.0))
            h = infer_height(t, ar, dist, seedv)
            b = {"footprint": ring, "height": h}
            if t.get("name"):
                b["name"] = t["name"]
            key = f"{int(math.floor(cx / TILE))}_{int(math.floor(cn2 / TILE))}"
            buckets[key].append(b)
            added += 1
            total += 1
        print(f"  +{added} buildings")
        lat = lat2
        time.sleep(2)

    for key, blds in buckets.items():
        json.dump(blds, open(os.path.join(TILES, f"b_{key}.json"), "w"))
    print(f"wrote {total} buildings across {len(buckets)} tiles")


if __name__ == "__main__":
    main()
