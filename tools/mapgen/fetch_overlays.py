#!/usr/bin/env python3
"""
Fetch real OpenStreetMap "overlay" features for the New Bedford slice and bake
them to QUAHOG_Web/public/<layer>-<name>.json (slice-local metres), which the web
slice loader picks up. These are the ground/area/line overlays that ground the
map in reality: parks, parking, beaches, railways, cemeteries, woods, piers,
churches, and the hurricane-barrier breakwaters.

Each output is either a list of rings ([[ [e,n], ... ], ...]) for area/line
features, or a list of points ([[e,n], ...]) for churches.

Usage:
  fetch_overlays.py --name newbedford --origin 41.636,-70.9205 \
                    --bbox 41.61,-70.95,41.66,-70.86 --out ../../QUAHOG_Web/public

Requires outbound access to an Overpass endpoint (overpass-api.de).
"""
import argparse
import json
import math
import os
import sys
import urllib.parse
import urllib.request

OVERPASS = "https://overpass-api.de/api/interpreter"
UA = "quahog-mapgen/1.0 (New Bedford overlays)"

# layer -> (overpass selectors, geometry kind: "poly" | "line" | "point")
LAYERS = {
    "parks":     (['way["leisure"="park"]', 'way["leisure"="garden"]', 'way["landuse"="grass"]',
                   'way["landuse"="recreation_ground"]', 'way["leisure"="pitch"]'], "poly"),
    "parking":   (['way["amenity"="parking"]'], "poly"),
    "beach":     (['way["natural"="beach"]', 'way["natural"="sand"]'], "poly"),
    "rail":      (['way["railway"="rail"]', 'way["railway"="disused"]', 'way["railway"="abandoned"]'], "line"),
    "cemetery":  (['way["landuse"="cemetery"]', 'way["amenity"="grave_yard"]'], "poly"),
    "wood":      (['way["natural"="wood"]', 'way["landuse"="forest"]', 'way["natural"="scrub"]'], "poly"),
    "pier":      (['way["man_made"="pier"]'], "line"),
    "barrier":   (['way["man_made"="breakwater"]', 'way["man_made"="dyke"]'], "line"),
    "church":    (['way["amenity"="place_of_worship"]', 'node["amenity"="place_of_worship"]'], "point"),
}


def overpass(query):
    body = urllib.parse.urlencode({"data": query}).encode()
    req = urllib.request.Request(OVERPASS, data=body, headers={"User-Agent": UA, "Accept": "application/json"})
    with urllib.request.urlopen(req, timeout=90) as r:
        return json.loads(r.read().decode("utf-8", "replace"))


def projector(lat0, lon0):
    m_lat = 111320.0
    m_lon = 111320.0 * math.cos(lat0 * math.pi / 180)
    return lambda lon, lat: [round((lon - lon0) * m_lon, 1), round((lat - lat0) * m_lat, 1)]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--name", default="newbedford")
    ap.add_argument("--origin", required=True, help="lat,lon of slice origin")
    ap.add_argument("--bbox", required=True, help="S,W,N,E")
    ap.add_argument("--out", required=True, help="output dir (QUAHOG_Web/public)")
    ap.add_argument("--max-dist", type=float, default=6000.0, help="cull features whose centroid is beyond this (m)")
    args = ap.parse_args()

    lat0, lon0 = (float(x) for x in args.origin.split(","))
    proj = projector(lat0, lon0)
    bbox = args.bbox

    for layer, (selectors, kind) in LAYERS.items():
        clause = "".join(f"{s}({bbox});" for s in selectors)
        out_kind = "out center;" if kind == "point" else "out geom;"
        q = f"[out:json][timeout:90];({clause});{out_kind}"
        try:
            data = overpass(q)
        except Exception as e:  # noqa: BLE001
            sys.stderr.write(f"[warn] {layer}: fetch failed ({e})\n")
            continue

        feats = []
        for el in data.get("elements", []):
            if kind == "point":
                c = el.get("center") or {"lon": el.get("lon"), "lat": el.get("lat")}
                if c.get("lon") is None:
                    continue
                p = proj(c["lon"], c["lat"])
                if abs(p[0]) <= args.max_dist and abs(p[1]) <= args.max_dist:
                    feats.append(p)
                continue
            g = el.get("geometry")
            if not g:
                continue
            pts = [proj(p["lon"], p["lat"]) for p in g if "lon" in p and "lat" in p]
            if len(pts) < (4 if kind == "poly" else 2):
                continue
            cx = sum(p[0] for p in pts) / len(pts)
            cn = sum(p[1] for p in pts) / len(pts)
            if abs(cx) <= args.max_dist and abs(cn) <= args.max_dist:
                feats.append(pts)

        path = os.path.join(args.out, f"{layer}-{args.name}.json")
        with open(path, "w") as fh:
            json.dump(feats, fh)
        sys.stderr.write(f"[ok] {layer}: {len(feats)} -> {path}\n")


if __name__ == "__main__":
    main()
