#!/usr/bin/env bash
# Generate the in-game GIS city from REAL OpenStreetMap data for a bounding box,
# then verify + package it. One command: data -> game -> verified zip.
#
#   tools/mapgen/mapgen.sh S,W,N,E [outfile]
#   e.g. New Bedford waterfront:
#   tools/mapgen/mapgen.sh 41.6330,-70.9270,41.6400,-70.9180
#
# Requires the sandbox network allowlist (Custom egress) to include overpass-api.de.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$DIR/../.." && pwd)"

BBOX="${1:-}"
OUT="${2:-$ROOT/QUAHOG_Unity/Assets/Resources/gis/newbedford.json}"
[ -z "$BBOX" ] && { echo "usage: mapgen.sh S,W,N,E [outfile]"; exit 1; }

echo "########## fetch OSM ($BBOX) ##########"
python3 "$DIR/fetch_osm.py" --bbox "$BBOX" --out "$OUT"

echo "########## verify + package ##########"
"$ROOT/tools/csharp/package.sh"
