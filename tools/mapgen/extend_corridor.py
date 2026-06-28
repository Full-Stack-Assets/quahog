#!/usr/bin/env python3
"""Extend the Godot SouthCoast slice NORTH along the RT-140 / RT-24 corridor to
Brockton. Fetches major highways (and, with --buildings, building footprints) from
Overpass in latitude strips, projects them onto the existing New Bedford origin,
and merges them into QUAHOG_GODOT1/data/map (slice-newbedford.json + tiles/).

Only geometry north of SEAM_N metres is added, so it cleanly continues past the
existing data's northern edge (~+12.7 km) instead of duplicating it.
"""
import argparse, json, math, os, time, urllib.parse, urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
MAP = os.path.normpath(os.path.join(HERE, "..", "..", "QUAHOG_GODOT1", "data", "map"))
SLICE = os.path.join(MAP, "slice-newbedford.json")
TILES = os.path.join(MAP, "tiles")
TILE = 500.0
SEAM_N = 11500.0  # only add geometry north of this (m); existing data ends ~12.7k

OLAT, OLON = 41.636, -70.9205
M_LAT = 111320.0
M_LON = 111320.0 * math.cos(math.radians(OLAT))
def proj(lon, lat): return [round((lon - OLON) * M_LON, 2), round((lat - OLAT) * M_LAT, 2)]

ROAD_W = {"motorway": 16, "trunk": 14, "primary": 12, "secondary": 10, "tertiary": 8,
          "residential": 7, "unclassified": 7, "service": 4.5, "living_street": 5,
          "pedestrian": 5, "footway": 2.5, "path": 2, "steps": 2, "cycleway": 2.5,
          "motorway_link": 8, "trunk_link": 7, "primary_link": 7, "secondary_link": 6,
          "tertiary_link": 6}
HOSTS = ["https://overpass-api.de/api/interpreter",
         "https://overpass.kumi.systems/api/interpreter"]

def fetch(query):
    for host in HOSTS:
        url = host + "?data=" + urllib.parse.quote(query)
        for attempt in range(3):
            try:
                req = urllib.request.Request(url, headers={"User-Agent": "quahog-gamedev/1.0"})
                return json.loads(urllib.request.urlopen(req, timeout=180).read())
            except Exception as e:
                print(f"  ! {host} attempt {attempt+1}: {type(e).__name__} {e}")
                time.sleep(5 * (attempt + 1))
    return None

def way_xy(el): return [proj(p["lon"], p["lat"]) for p in el.get("geometry", [])]

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--s", type=float, required=True)
    ap.add_argument("--w", type=float, required=True)
    ap.add_argument("--n", type=float, required=True)
    ap.add_argument("--e", type=float, required=True)
    ap.add_argument("--strip", type=float, default=0.10)
    ap.add_argument("--buildings", action="store_true")
    ap.add_argument("--roadclass", default="motorway|trunk|primary|secondary|tertiary|motorway_link|trunk_link|primary_link|secondary_link")
    args = ap.parse_args()

    slice_obj = json.load(open(SLICE))
    roads = slice_obj["roads"]
    landmarks = slice_obj.get("landmarks", [])
    known_lm = set(l["name"] for l in landmarks)
    r0 = len(roads)

    tile_buckets = {}     # key -> list of buildings to append
    n_b = 0

    lat = args.s
    while lat < args.n - 1e-9:
        lat2 = min(lat + args.strip, args.n)
        bbox = f"{lat:.4f},{args.w:.4f},{lat2:.4f},{args.e:.4f}"
        parts = [f'way({bbox})[highway~"^({args.roadclass})$"];']
        if args.buildings:
            parts.append(f'way({bbox})[building];')
        q = "[out:json][timeout:180];(" + "".join(parts) + ");out geom;"
        print(f"strip {lat:.3f}..{lat2:.3f} ...")
        data = fetch(q)
        if data is None:
            print("  FAILED strip, skipping"); lat = lat2; continue
        added_r = 0
        for el in data.get("elements", []):
            t = el.get("tags", {})
            if el.get("type") != "way":
                continue
            if t.get("highway"):
                pts = way_xy(el)
                if len(pts) < 2: continue
                if max(p[1] for p in pts) < SEAM_N:  # below the seam = already covered
                    continue
                roads.append({"highway": t["highway"], "width": ROAD_W.get(t["highway"], 6),
                              "name": t.get("name"), "points": pts})
                added_r += 1
                if t.get("name") and t.get("ref"):
                    pass
            elif args.buildings and t.get("building"):
                ring = way_xy(el)
                if len(ring) < 4: continue
                if ring[0] == ring[-1]: ring = ring[:-1]
                if len(ring) < 3: continue
                cx = sum(p[0] for p in ring) / len(ring)
                cn = sum(p[1] for p in ring) / len(ring)
                if cn < SEAM_N: continue
                lvls = t.get("building:levels")
                try: h = float(lvls) * 3.5 if lvls else 8.0
                except ValueError: h = 8.0
                if t.get("height"):
                    try: h = float(str(t["height"]).split()[0])
                    except ValueError: pass
                b = {"footprint": ring, "height": round(h, 1)}
                if t.get("name"): b["name"] = t["name"]
                key = f"{math.floor(cx / TILE)}_{math.floor(cn / TILE)}"
                tile_buckets.setdefault(key, []).append(b)
                n_b += 1
            # town / civic landmarks
            if t.get("name") and (t.get("place") in ("city", "town") or t.get("amenity") == "townhall"):
                g = way_xy(el)
                pt = [sum(p[0] for p in g) / len(g), sum(p[1] for p in g) / len(g)] if g else None
                if pt and pt[1] >= SEAM_N and t["name"] not in known_lm:
                    landmarks.append({"name": t["name"], "kind": "town", "pos": pt})
                    known_lm.add(t["name"])
        print(f"  +{added_r} roads")
        lat = lat2
        time.sleep(2)

    slice_obj["roads"] = roads
    slice_obj["landmarks"] = landmarks
    json.dump(slice_obj, open(SLICE, "w"))
    print(f"ROADS added: {len(roads) - r0} (total {len(roads)})  slice={os.path.getsize(SLICE)/1024:.0f}KB")

    if args.buildings and tile_buckets:
        # merge into existing tile files
        for key, blds in tile_buckets.items():
            path = os.path.join(TILES, f"b_{key}.json")
            existing = []
            if os.path.exists(path):
                try: existing = json.load(open(path))
                except Exception: existing = []
            existing.extend(blds)
            json.dump(existing, open(path, "w"))
        print(f"BUILDINGS added: {n_b} across {len(tile_buckets)} tiles")

if __name__ == "__main__":
    main()
