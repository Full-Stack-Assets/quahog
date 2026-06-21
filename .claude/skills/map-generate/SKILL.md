---
name: map-generate
description: Generate or refresh the in-game GIS city from real OpenStreetMap data for a real-world area (a bounding box or a place like the New Bedford waterfront). Use when asked to "generate the map", "pull the city", "use real data", "build <place>", or to convert a pasted Overpass/overpass-turbo export into the game. Produces a verified Unity drop-in zip.
---

# Generate the GIS city from real map data

Turns real OpenStreetMap data into the GeoJSON that `GisCity` renders
(`QUAHOG_Unity/Assets/Resources/gis/newbedford.json`), then verifies + packages.

Default area — **New Bedford waterfront** bbox: `41.6330,-70.9270,41.6400,-70.9180`.

## Pick the path based on egress

### A. Egress is open (overpass-api.de allowlisted) — one command
```bash
tools/mapgen/mapgen.sh 41.6330,-70.9270,41.6400,-70.9180
```
This fetches OSM, bakes it into `newbedford.json`, runs the compile+test gate, and
produces `quahog_unity_drop.zip`. Send that zip to the user.

### B. Egress is closed, user pasted a raw Overpass JSON
```bash
python3 tools/mapgen/fetch_osm.py --in <pasted_overpass.json> \
  --out QUAHOG_Unity/Assets/Resources/gis/newbedford.json
tools/csharp/package.sh
```

### C. User pasted an overpass-turbo GeoJSON export (already GeoJSON)
It's already in the right format — copy it into place, then package:
```bash
cp <pasted.geojson> QUAHOG_Unity/Assets/Resources/gis/newbedford.json
tools/csharp/package.sh
```

## After generating
- Confirm the test output shows `live has roads` / `live has buildings` > 0.
- Send the user `quahog_unity_drop.zip` and commit the updated `newbedford.json`.
- Note for the user: `StreetLife` peds/cars are still greybox-tuned and may need
  retargeting to the new road network (separate follow-up).

## Notes
- `fetch_osm.py` passes all OSM tags through as feature properties, so
  `building` / `building:levels` / `height` / `highway` / `name` / `natural` all
  reach `GeoJson.cs` unchanged.
- Bigger bbox = more geometry = heavier WebGL. Start with one district.
- Building courtyards (inner rings) are ignored in v1 (filled solid).
