#!/usr/bin/env python3
"""
Map generation: fetch real OpenStreetMap data for a bounding box and convert it to
the GeoJSON FeatureCollection that GisCity (Assets/Scripts/World/Gis) consumes.

Two modes:
  Fetch:    fetch_osm.py --bbox S,W,N,E --out path.json
  Offline:  fetch_osm.py --in overpass_raw.json --out path.json   (convert a saved
            Overpass response; useful for testing or when fetched elsewhere)

Output schema (consumed directly by GeoJson.cs):
  - building footprints -> Polygon / MultiPolygon, properties keep building / building:levels / height
  - highways            -> LineString, properties keep highway / name
  - natural=water       -> Polygon / MultiPolygon
All OSM tags are passed through as feature properties, so nothing is lost.

Multipolygon relations (large/complex buildings, water bodies with islands, and
any footprint with a courtyard) are assembled here: member ways are stitched into
closed outer/inner rings and emitted with holes ([outer, inner, ...]), so GisCity
renders courtyards and lakes-with-islands correctly instead of filling them solid.
"""
import argparse
import json
import sys
import urllib.parse
import urllib.request

# Public Overpass endpoints, tried in order. Add hosts to the sandbox network
# allowlist (Custom egress) for fetching to work.
OVERPASS_HOSTS = [
    "https://overpass-api.de/api/interpreter",
    "https://overpass.kumi.systems/api/interpreter",
]
USER_AGENT = "quahog-gamedev/1.0 (map generation for QUAHOG)"


def build_query(s, w, n, e):
    bbox = f"{s},{w},{n},{e}"
    # Relations carry multipolygons (complex buildings, courtyards, water with
    # islands). `out geom` attaches coordinates to ways *and* relation members so
    # we can stitch rings client-side without a second id->geometry lookup.
    return f"""[out:json][timeout:180];
(
  way["building"]({bbox});
  relation["building"]({bbox});
  way["highway"]({bbox});
  way["natural"="water"]({bbox});
  relation["natural"="water"]({bbox});
);
out geom;"""


def fetch(query):
    body = urllib.parse.urlencode({"data": query}).encode()
    last_err = None
    for url in OVERPASS_HOSTS:
        try:
            req = urllib.request.Request(url, data=body, headers={"User-Agent": USER_AGENT})
            with urllib.request.urlopen(req, timeout=150) as r:
                raw = r.read().decode("utf-8", "replace")
            if "Host not in allowlist" in raw:
                last_err = f"{url}: blocked by sandbox egress allowlist"
                continue
            data = json.loads(raw)
            if "elements" in data:
                sys.stderr.write(f"[fetch] {url}: {len(data['elements'])} elements\n")
                return data
            last_err = f"{url}: no 'elements' in response"
        except Exception as ex:  # noqa: BLE001
            last_err = f"{url}: {ex}"
    raise RuntimeError(
        "Could not fetch OSM data.\n  " + str(last_err) +
        "\n  -> Open the sandbox network allowlist (Custom egress) for overpass-api.de, "
        "or export GeoJSON from overpass-turbo.eu and feed it to GisCity directly."
    )


def _close(a, b, tol=1e-7):
    """Two lon/lat points coincide (endpoint match when stitching ways)."""
    return abs(a[0] - b[0]) <= tol and abs(a[1] - b[1]) <= tol


def _closed(ring):
    return len(ring) >= 4 and _close(ring[0], ring[-1])


def stitch_rings(ways):
    """Connect a bag of polylines (each a list of [lon,lat]) into closed rings by
    matching endpoints. A multipolygon's boundary is often split across several
    member ways in arbitrary order/direction, so we greedily weld them."""
    segs = [list(w) for w in ways if len(w) >= 2]
    rings = []
    while segs:
        ring = segs.pop(0)
        extended = True
        while extended and not _close(ring[0], ring[-1]):
            extended = False
            for i, s in enumerate(segs):
                if _close(ring[-1], s[0]):
                    ring += s[1:]
                elif _close(ring[-1], s[-1]):
                    ring += list(reversed(s))[1:]
                elif _close(ring[0], s[-1]):
                    ring = s[:-1] + ring
                elif _close(ring[0], s[0]):
                    ring = list(reversed(s))[:-1] + ring
                else:
                    continue
                segs.pop(i)
                extended = True
                break
        if not _close(ring[0], ring[-1]):
            ring.append(ring[0])  # force-close a ring we couldn't fully weld
        if _closed(ring):
            rings.append(ring)
    return rings


def _point_in_ring(pt, ring):
    """Ray-cast test: is [lon,lat] pt inside the (closed) ring?"""
    x, y = pt
    inside = False
    n = len(ring)
    j = n - 1
    for i in range(n):
        xi, yi = ring[i]
        xj, yj = ring[j]
        if ((yi > y) != (yj > y)) and (x < (xj - xi) * (y - yi) / (yj - yi + 1e-30) + xi):
            inside = not inside
        j = i
    return inside


def relation_polygons(members):
    """Assemble a multipolygon relation's outer/inner member ways into a list of
    GeoJSON polygons (each = [outer_ring, *hole_rings]). Inner rings are matched to
    the outer ring that contains them."""
    outer_ways, inner_ways = [], []
    for m in members:
        if m.get("type") != "way":
            continue
        geom = m.get("geometry")
        if not geom:
            continue
        coords = [[p["lon"], p["lat"]] for p in geom if "lon" in p and "lat" in p]
        if len(coords) < 2:
            continue
        (inner_ways if m.get("role") == "inner" else outer_ways).append(coords)

    outers = stitch_rings(outer_ways)
    inners = stitch_rings(inner_ways)
    polys = []
    for outer in outers:
        holes = [h for h in inners if _point_in_ring(h[0], outer)]
        polys.append([outer] + holes)
    return polys


def _classify(tags):
    is_building = "building" in tags
    is_water = tags.get("natural") == "water" or "water" in tags
    is_highway = "highway" in tags
    return is_building, is_water, is_highway


def to_geojson(overpass):
    """Convert an Overpass 'out geom' response to our GeoJSON FeatureCollection."""
    features = []
    elements = overpass.get("elements", [])

    # Member ways of relations are emitted again as standalone ways; skip those so
    # a courtyard outline isn't drawn twice (once with a hole, once solid).
    member_way_ids = set()
    for el in elements:
        if el.get("type") == "relation":
            for m in el.get("members", []):
                if m.get("type") == "way" and "ref" in m:
                    member_way_ids.add(m["ref"])

    for el in elements:
        etype = el.get("type")
        tags = el.get("tags") or {}
        is_building, is_water, is_highway = _classify(tags)

        if etype == "relation":
            if not (is_building or (is_water and not is_highway)):
                continue
            polys = relation_polygons(el.get("members", []))
            polys = [p for p in polys if len(p[0]) >= 4]
            if not polys:
                continue
            if len(polys) == 1:
                geometry = {"type": "Polygon", "coordinates": polys[0]}
            else:
                geometry = {"type": "MultiPolygon", "coordinates": polys}
            features.append({"type": "Feature", "properties": tags, "geometry": geometry})
            continue

        if etype != "way":
            continue
        if el.get("id") in member_way_ids and not (is_building or is_highway):
            continue  # bare boundary way already consumed by its relation
        geom = el.get("geometry")
        if not geom or len(geom) < 2:
            continue
        coords = [[p["lon"], p["lat"]] for p in geom if "lon" in p and "lat" in p]
        if len(coords) < 2:
            continue

        if is_building or (is_water and not is_highway):
            if coords[0] != coords[-1]:
                coords = coords + [coords[0]]
            if len(coords) < 4:
                continue
            geometry = {"type": "Polygon", "coordinates": [coords]}
        elif is_highway:
            geometry = {"type": "LineString", "coordinates": coords}
        else:
            continue

        features.append({"type": "Feature", "properties": tags, "geometry": geometry})

    return {"type": "FeatureCollection", "features": features}


def summarize(fc):
    roads = buildings = water = 0
    for f in fc["features"]:
        p = f["properties"]
        if "building" in p:
            buildings += 1
        elif "highway" in p:
            roads += 1
        elif p.get("natural") == "water" or "water" in p:
            water += 1
    return roads, buildings, water


def main():
    ap = argparse.ArgumentParser(description="Fetch/convert OSM data to GisCity GeoJSON.")
    ap.add_argument("--bbox", help="S,W,N,E (e.g. 41.6330,-70.9270,41.6400,-70.9180)")
    ap.add_argument("--in", dest="infile", help="Convert a saved Overpass JSON instead of fetching")
    ap.add_argument("--out", required=True, help="Output GeoJSON path")
    args = ap.parse_args()

    if args.infile:
        with open(args.infile, "r", encoding="utf-8") as fh:
            overpass = json.load(fh)
    elif args.bbox:
        parts = [x.strip() for x in args.bbox.split(",")]
        if len(parts) != 4:
            ap.error("--bbox must be S,W,N,E")
        overpass = fetch(build_query(*parts))
    else:
        ap.error("provide --bbox to fetch or --in to convert")

    fc = to_geojson(overpass)
    roads, buildings, water = summarize(fc)
    if roads + buildings == 0:
        sys.stderr.write("[warn] no roads or buildings produced — check the bbox/data.\n")

    with open(args.out, "w", encoding="utf-8") as fh:
        json.dump(fc, fh)
    sys.stderr.write(f"[ok] wrote {args.out}: {roads} roads, {buildings} buildings, {water} water\n")


if __name__ == "__main__":
    main()
