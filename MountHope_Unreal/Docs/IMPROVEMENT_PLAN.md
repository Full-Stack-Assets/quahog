# Mount Hope Unreal — Improvement Plan

This document captures the current state of `MountHope_Unreal/`, the gaps
identified during exploration, and the phased plan to reach a playable
vertical slice.

## Current state (before this pass)

`MountHope_Unreal/` was an early C++ scaffold (~500 lines) with:

- Thin stubs for player, vehicle, missions, economy, and world metadata
- No `Target.cs` files (first compile required editor project generation)
- Empty `Content/` and a default map (`MH_VerticalSlice`) that does not exist
- Legacy input bindings despite Enhanced Input being enabled
- No JSON bootstrap, save/load, or mission trigger loop
- No CI; only `Scripts/validate_scaffold.py` for structural checks

A parallel tree at `QUAHOG_Unreal/` had more complete framework code (JSON
loading, mission triggers, save game) but is not listed in `README.md` /
`ENGINES.md` as the canonical PC track.

## Gaps vs. vertical-slice acceptance criteria

From `Docs/VERTICAL_SLICE.md`:

| Criterion | Status |
| --- | --- |
| Graybox level with OSM roads/water | Needs editor assets |
| Walk third-person on roads | C++ ready; needs map + pawn mesh |
| Enter/exit Chaos vehicle | C++ possession loop implemented |
| Drive on roads | Needs vehicle mesh + wheel setup |
| Mission NPC + short crime mission | JSON campaign + trigger actors wired |
| Earn/spend money | `MHGameStateSubsystem` + businesses JSON |
| Dialogue exchanges | Not started |
| OSM slice data loaded at runtime | `MHWorldSliceSubsystem` loads web slice JSON |
| Cinematic Lumen/Nanite lighting | Config defaults set; needs content |

## Improvements delivered in this pass

### Build & CI

- `Source/MountHope.Target.cs` and `Source/MountHopeEditor.Target.cs`
- `Scripts/build.sh` — wraps `RunUBT.sh` when `UE_ROOT` is set locally
- `.github/workflows/unreal-ci.yml` — runs `validate_scaffold.py` on PRs

### Framework (C++)

- `UMHGameInstance` — bootstraps slice, missions, economy, and save slot on startup
- `UMHWorldSliceSubsystem` — loads `slice-newbedford.json` at runtime
- `UMHMissionSubsystem` — JSON campaign with step advancement
- `UMHGameStateSubsystem` — cash, heat, weather, businesses, save/load
- `AMHMissionTriggerActor` — world-target objective volumes
- `AMHGameModeBase` — mission loop, heat decay, trigger refresh
- `AMHPlayerCharacter` — vehicle enter/exit + interact
- `UMHEconomySubsystem` — thin delegate to game state (backward compatible)

### Data

- `Data/Missions/vertical_slice.json`
- `Data/Economy/businesses.json`

### Validation

- Expanded `Scripts/validate_scaffold.py` to cover targets, JSON schemas,
  config wiring, mission/vehicle helpers, and deprecated-macro guards.

## Next phases (editor workstation required)

### Phase 1 — First playable in editor

1. Open `MountHope.uproject` in UE 5.6+ and compile (`Scripts/build.sh` or editor).
2. Create `/Game/Maps/MH_VerticalSlice` as an Open World map.
3. Add Blueprint children for `MHPlayerCharacter` and `MHVehiclePawn` with
   placeholder meshes and a Chaos vehicle setup.
4. Place at least one `MHVehiclePawn` in the slice spawn area.
5. PIE: walk, enter vehicle, complete first mission step via trigger volume.

### Phase 2 — World geometry

1. Import `quahog-project-files/mapdata/southcoast.obj` per `Docs/OSM_TO_UNREAL.md`.
2. Procedural mesh or spline actors driven by `UMHWorldSliceSubsystem` road data.
3. Nav mesh bake on imported roads.

### Phase 3 — Enhanced Input migration

Replace legacy `DefaultInput.ini` axis/action bindings with `UInputMappingContext`
assets and wire `MHPlayerCharacter` to `UEnhancedInputComponent` (plugin already
enabled).

### Phase 4 — Content & polish

- MetaHuman NPC for mission giver
- Dialogue UI (UMG) backed by mission JSON
- Weather VFX tied to `EMHWeatherState`
- Package Development build via `RunUAT BuildCookRun`

### Phase 5 — Repo consolidation

`QUAHOG_Unreal/` is marked **legacy** (`QUAHOG_Unreal/LEGACY.md`). Its framework
patterns live in `MountHope_Unreal/`; do not add new features to the old tree.

## Local compile & package

```bash
export UE_ROOT="/path/to/UE_5.6"
./MountHope_Unreal/Scripts/build.sh

# Package (after editor content exists):
./MountHope_Unreal/Scripts/package.sh
```

See `Docs/EDITOR_SETUP.md` for the Phase 1 editor checklist and
`Scripts/editor_bootstrap_vertical_slice.py` for in-editor automation.

## CI (cloud sandbox)

```bash
python3 MountHope_Unreal/Scripts/validate_scaffold.py
```

Full C++ compile cannot run in Cursor Cloud without a local Unreal install.
