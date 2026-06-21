#!/usr/bin/env python3
"""
Map generation: fetch real OpenStreetMap data for a bounding box and convert it to
the GeoJSON FeatureCollection that GisCity (Assets/Scripts/World/Gis) consumes.

Two modes:
  Fetch:    fetch_osm.py --bbox S,W,N,E --out path.json
  Offline:  fetch_osm.py --in overpass_raw.json --out path.json   (convert a saved
            Overpass response; useful for testing or when fetched elsewhere)

Output schema (consumed directly by GeoJson.cs):
  - building footprints -> Polygon, properties keep building / building:levels / height
  - highways            -> LineString, properties keep highway / name
  - natural=water       -> Polygon
All OSM tags are passed through as feature properties, so nothing is lost.
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
    return f"""[out:json][timeout:120];
(
  way["building"]({bbox});
  way["highway"]({bbox});
  way["natural"="water"]({bbox});
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


def to_geojson(overpass):
    """Convert an Overpass 'out geom' response to our GeoJSON FeatureCollection."""
    features = []
    for el in overpass.get("elements", []):
        if el.get("type") != "way":
            continue
        geom = el.get("geometry")
        if not geom or len(geom) < 2:
            continue
        tags = el.get("tags") or {}
        coords = [[p["lon"], p["lat"]] for p in geom if "lon" in p and "lat" in p]
        if len(coords) < 2:
            continue

        is_building = "building" in tags
        is_water = tags.get("natural") == "water" or "water" in tags
        is_highway = "highway" in tags

        if is_building or (is_water and not is_highway):
            # Close the ring for a polygon.
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
