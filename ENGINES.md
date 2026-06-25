# Engine reconciliation

This repo accumulated **three** engine tracks for the same vertical slice. As of
this reconciliation, there is one canonical engine; the rest are reference.

## Decision

**Canonical: `QUAHOG_Web/` — Three.js / React Three Fiber.**

Rationale:
- It matches the locked engine decision: *Web 3D, buildable live in-session,
  browser-playable.*
- It runs on **real** OpenStreetMap data for the New Bedford waterfront (316
  buildings, 561 roads, 15 landmarks) and is **already deployed**
  (https://projectsouthcoast.vercel.app).

## New PC/console track

`MountHope_Unreal/` is a separate Unreal Engine 5 vertical-slice scaffold for
the premium PC/console direction. It does not replace the current runnable web
slice in this sandbox; it captures the next product direction: single-player,
GTA-like open-world crime structure, photoreal presentation, heavy cinematic
vehicles, OSM-grounded map import, missions, NPCs, economy, and dialogue.

## What the other tracks were

| Track | Engine | Status | Notes |
|-------|--------|--------|-------|
| `QUAHOG_Web/` | Three.js / R3F + Rapier | **canonical** | real data, deployed, walk/drive/collision + street life |
| `MountHope_Unreal/` | Unreal Engine 5 | PC/console scaffold | separate vertical-slice track; requires Unreal editor |
| `QUAHOG_Unity/` (PR #18) | Unity C# → WebGL | legacy | same slice idea; data was a placeholder grid; needs the Unity editor to build |
| `QUAHOG_Godot/` | Godot GDScript | legacy | earlier port; predates the web decision |

## What was salvaged from the Unity slice (PR #18)

Ported forward into `QUAHOG_Web/` rather than kept as C#:

- **Street life** — `StreetLife.cs` (kinematic wandering pedestrians + decorative
  patrol cars) → `QUAHOG_Web/src/world/StreetLife.tsx`, retargeted to follow the
  real OSM road network.
- **Car feel** — arcade tuning constants from `CarController.cs` (top/reverse
  speed, steering rate, lateral grip) informed the web car's tuning.

Not ported (Unity-specific, kept only as reference):
- `GisCity.cs` / `GeoJson.cs` / `EarClipping.cs` — the web pipeline does this in
  Python (`quahog-project-files/mapdata/make_slice.py`) + R3F.
- `tools/csharp/` headless compile/test sandbox and the `compile-check` skill.
- `tools/mapgen/fetch_osm.py` — same Overpass source as the canonical pipeline.

## Map pipeline

Canonical: `quahog-project-files/mapdata/` (`split_layers.py`, `bake_meshes.py`,
`make_slice.py`) → real geometry for both cities, plus the web slice blockout.
`tools/mapgen/` is the older Unity-targeted fetcher and is superseded for web.
