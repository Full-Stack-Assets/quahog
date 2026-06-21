# Map data — New Bedford & Fall River, MA

Real-world OpenStreetMap geometry for the two anchor cities of Project QUAHOG
(*GTA: South Coast*), pulled to seed the world layout and the GeoAware
Traffic / Pedestrian spawner.

## Files

| City | Raw OSM JSON | GeoJSON |
|------|--------------|---------|
| Fall River, MA | `fall-river.osm.json` | `fall-river.geojson` |
| New Bedford, MA | `new-bedford.osm.json` | `new-bedford.geojson` |

- `*.osm.json` — raw [Overpass API](https://overpass-api.de/) response (OSM JSON,
  `out geom` — node coordinates inlined on every way/relation member).
- `*.geojson` — converted `FeatureCollection`. Ways → `LineString`
  (`Polygon` for closed `natural=water` areas); relations → `MultiLineString`.

## What was pulled

Everything clipped to each city's `admin_level=8` administrative boundary:

| Layer | Filter | Fall River | New Bedford |
|-------|--------|-----------:|------------:|
| Roads | `highway=*` | 6570 | 5725 |
| Railways | `railway=*` | 115 | 63 |
| Waterways | `waterway=*` | 242 | 27 |
| Water bodies | `natural=water` (way + relation) | 55 | 29 |
| Coastline | `natural=coastline` | 5 | 1 |
| City boundary | `boundary=administrative` | 1 | 1 |

## Source boundaries

| City | OSM relation | Bounding box (minlat, minlon → maxlat, maxlon) |
|------|-------------:|------------------------------------------------|
| Fall River | [2396246](https://www.openstreetmap.org/relation/2396246) | `41.6036774, -71.2013109 → 41.7689808, -71.0095415` |
| New Bedford | [2396248](https://www.openstreetmap.org/relation/2396248) | `41.5913890, -70.9775124 → 41.7446715, -70.8993923` |

## How it was generated

Overpass query, per city (`<area>` = relation id + `3600000000`):

```overpassql
[out:json][timeout:300];
area(<area>)->.a;
(
  way["highway"](area.a);
  way["railway"](area.a);
  way["waterway"](area.a);
  way["natural"="water"](area.a);
  relation["natural"="water"](area.a);
  way["natural"="coastline"](area.a);
  relation["boundary"="administrative"](area.a);
);
out geom;
```

Pulled 2026-06-21 from `overpass-api.de`. To refresh, re-run the query above and
re-convert the OSM JSON to GeoJSON.

## License / attribution

Data © [OpenStreetMap](https://www.openstreetmap.org/copyright) contributors,
made available under the [Open Database License (ODbL)](https://opendatacommons.org/licenses/odbl/).
Any product using this data must credit OpenStreetMap contributors and keep the
data under ODbL.
