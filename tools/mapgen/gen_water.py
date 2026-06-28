#!/usr/bin/env python3
"""Fetch OSM water bodies (harbors, rivers, ponds, bays) for the map extent and
write them as a blue land-use overlay (overlays/water.json.gz). The whole world
is otherwise one grey ground plane, so without this the ocean/rivers render as
drivable grey nothing. MapLoader draws this overlay blue, so water reads as water.

Pulls closed `natural=water` / `water=*` ways (polygons). Coastline lines are not
polygonised here; the named bays/rivers/harbor basins that the cities sit on are
tagged as water polygons, which is what the player actually sees.
"""
import gzip, json, math, os, time, urllib.parse, urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
MAP = os.path.normpath(os.path.join(HERE, "..", "..", "QUAHOG_GODOT1", "data", "map"))
OVERLAYS = os.path.join(MAP, "overlays")
OLAT, OLON = 41.636, -70.9205
M_LAT = 111320.0
M_LON = 111320.0 * math.cos(math.radians(OLAT))
HOSTS = ["https://overpass-api.de/api/interpreter", "https://overpass.kumi.systems/api/interpreter"]

# Full map extent in lat/lon (matches MapLoader.FULL_BBOX with margin).
S, N, W, E = 41.55, 42.40, -71.21, -70.76
STRIP = 0.05


def proj(lon, lat):
    return [round((lon - OLON) * M_LON, 1), round((lat - OLAT) * M_LAT, 1)]


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


def main():
    os.makedirs(OVERLAYS, exist_ok=True)
    rings = []
    lat = S
    while lat < N - 1e-9:
        lat2 = min(lat + STRIP, N)
        q = (f"[out:json][timeout:180];"
             f"(way[natural=water]({lat:.3f},{W:.3f},{lat2:.3f},{E:.3f});"
             f"way[water]({lat:.3f},{W:.3f},{lat2:.3f},{E:.3f});"
             f"way[waterway=riverbank]({lat:.3f},{W:.3f},{lat2:.3f},{E:.3f}););out geom;")
        print(f"strip {lat:.3f}..{lat2:.3f} ...")
        data = fetch(q)
        if data is None:
            print("  FAILED"); lat = lat2; continue
        added = 0
        for el in data.get("elements", []):
            geom = el.get("geometry")
            if not geom or len(geom) < 4:
                continue
            ring = [proj(p["lon"], p["lat"]) for p in geom]
            if ring[0] != ring[-1]:          # only closed ways (polygons)
                continue
            ring = ring[:-1]
            if len(ring) >= 3:
                rings.append(ring)
                added += 1
        print(f"  +{added} water polygons")
        lat = lat2
        time.sleep(2)

    with gzip.open(os.path.join(OVERLAYS, "water.json.gz"), "wt", compresslevel=9) as f:
        json.dump(rings, f)
    print(f"wrote {len(rings)} water polygons -> overlays/water.json.gz")


if __name__ == "__main__":
    main()
