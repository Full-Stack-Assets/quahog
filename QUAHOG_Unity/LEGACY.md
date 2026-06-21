# ⚠️ Legacy / reference — not actively developed

The canonical engine is **`QUAHOG_Web/`** (Three.js / React Three Fiber).
See [`../ENGINES.md`](../ENGINES.md).

This Unity (C#) project — including the parallel Unity→WebGL vertical slice added
in PR #18 (`Assets/Scripts/Player`, `Vehicles`, `World/Gis`, `World/StreetLife`,
`World/TownGreybox`) — is kept for reference only. Its New Bedford GIS data was a
placeholder grid, and it requires the Unity editor to build.

The valuable parts (street life, car feel) were ported to the web engine; the
rest stays here as reference. Don't build new features on this track without
first revisiting the engine decision in `ENGINES.md`.
