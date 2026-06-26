# Mount Hope (QUAHOG)

An original 3D open-world game set on the real Massachusetts South Coast. See
`README.md` and `ENGINES.md` for the full picture.

## Cursor Cloud specific instructions

### What is canonical vs. legacy

- **`QUAHOG_Web/` is the only canonical, runnable product** (Three.js / React
  Three Fiber + Rapier, Vite + TypeScript). This is what to run/test for an
  end-to-end check.
- **`MountHope_Unreal/` is a separate UE5 PC/console scaffold**, not runnable in
 this sandbox without a local Unreal editor install. Keep it aligned with the
 existing OSM/map concept, but validate it here with repo-local scripts unless
 an Unreal workstation is available.
- `QUAHOG_Unity/` (Unity 6 C#) and `QUAHOG_Godot/` (Godot GDScript) are
  **legacy/reference only**. They require the Unity/Godot editors and **cannot
  be built or run in this sandbox**. The Unity WebGL CI workflow
  (`.github/workflows/deploy-webgl.yml`) is dormant and needs Unity license
  secrets.

### Running / building the web game (commands live in `QUAHOG_Web/README.md`)

- All web commands run from `QUAHOG_Web/`: `npm run dev` (Vite dev server on
  http://localhost:5173), `npm run build`, `npm run preview`.
- **There is no separate lint script.** The type-check IS `tsc`, which runs as
  the first half of `npm run build` (`tsc && vite build`). Use `npm run build`
  to lint/type-check.
- `predev`/`prebuild` automatically run `node scripts/gen_manifests.mjs` (music
  manifests). It is zero-dependency and safe.

### Non-obvious gameplay/runtime notes

- The game starts on a title screen — you must click **NEW GAME**, then click
  the 3D canvas, before keyboard input (WASD move, `E` enter car, etc.) is
  captured. Without canvas focus, movement keys do nothing.
- The world loads from the committed `QUAHOG_Web/public/slice-newbedford.json`
  (real OSM New Bedford waterfront). **No map-data regeneration is needed to
  run the game.** Regen pipelines under `quahog-project-files/mapdata/` and
  `tools/mapgen/` are optional and require network egress to `overpass-api.de`.
- In local `vite dev` the ground often renders as a bright/over-exposed white
  plane. This is expected: the Google Static Maps satellite drape is served by
  a Vercel function (`api/staticmap.ts`) that does NOT run under `vite dev`, so
  it falls back to the procedural ground under dusk lighting + bloom. It is not
  a bug or a crash.
- The Vercel serverless functions in `QUAHOG_Web/api/` (satellite, ElevenLabs
  TTS/VO, music) only activate on a Vercel deploy with the keys in
  `QUAHOG_Web/ENV.md`. All of them degrade gracefully when keys are absent, so
  local dev needs no secrets.

### Legacy C# tooling (optional)

- `tools/csharp/` headless-compiles/tests the legacy Unity C# without Unity. Its
  scripts (`compile-check.sh`, `run-tests.sh`) self-install the .NET 8 SDK on
  first run via `tools/csharp/setup.sh`. Only relevant when touching
  `QUAHOG_Unity/Assets/Scripts` (see the `compile-check` skill).
