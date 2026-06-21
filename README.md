# QUAHOG (working title — name TBD)

An original 3D open-world game set on the **real Massachusetts South Coast**
(New Bedford, Fall River, Brockton, Cape Cod) — walk real streets and real
landmarks, populated by original characters, with GTA-style walk/drive
mechanics. *GTA: Vice City is only a tonal reference; this is original work.*

> The project name still needs to change off "Quahog" (Family Guy collision).
> Seeds under consideration: Quequechan, Spindle City, Mount Hope.

## Engines — canonical vs. legacy

The project has consolidated on a **single canonical engine**. Earlier Unity and
Godot tracks (and a second, parallel web attempt in Unity) are kept as
**reference only** — not actively developed. See [`ENGINES.md`](ENGINES.md) for
the full reconciliation.

### ✅ `QUAHOG_Web/` — canonical (active)
The browser-playable game: **Three.js / React Three Fiber** + Rapier physics.
Third-person walk, car enter/drive, collision, on the **real New Bedford
waterfront** street grid + auto-extruded OSM building blockout, with ambient
pedestrians and traffic. Buildable live and deployed.
**Live:** https://projectsouthcoast.vercel.app · setup: [`QUAHOG_Web/README.md`](QUAHOG_Web/README.md)

### Map data — `quahog-project-files/mapdata/`
The canonical OpenStreetMap pipeline feeding the web game: real road/water/
building geometry for New Bedford & Fall River → GeoJSON / PMTiles / OBJ and the
slice blockout JSON. See [`quahog-project-files/mapdata/README.md`](quahog-project-files/mapdata/README.md).

### `quahog-project-files/`
Design and pitch materials: the Game Design Document, Master Plan, pitch
one-pager, and system-design PDFs.

## Legacy / reference (not active)

- `QUAHOG_Godot/` — earlier Godot (GDScript) port. See [`QUAHOG_Godot/LEGACY.md`](QUAHOG_Godot/LEGACY.md).
- `QUAHOG_Unity/` — earlier Unity (C#) project, incl. a parallel Unity→WebGL slice. See [`QUAHOG_Unity/LEGACY.md`](QUAHOG_Unity/LEGACY.md).
- `tools/csharp/`, `tools/mapgen/` — tooling for the Unity track (headless C# compile/test; a Unity-targeted OSM fetcher). Superseded for web by `quahog-project-files/mapdata/`.
- `prototypes/Quahog3D.html` — standalone offline Three.js prototype.

---

**Unofficial fan parody / original work.** Not affiliated with, endorsed by, or
connected to Rockstar Games or Take-Two Interactive. Map data ©
OpenStreetMap contributors, ODbL.
