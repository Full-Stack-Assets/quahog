# Mount Hope Unreal Foundation (UE 5.8)

This directory is a UE5 C++ bootstrap for a console/PC version of Mount Hope,
derived from the existing South Coast gameplay concept in this repo.

> **Engine target:** Unreal Engine **5.8**. The project descriptor
> (`MountHope.uproject` → `EngineAssociation`) and both target rules
> (`Source/*.Target.cs`) are pinned to 5.8 via `BuildSettingsVersion.Latest` /
> `EngineIncludeOrderVersion.Latest`, so the module builds against the engine you
> have installed. If you prefer an explicit pin, swap `Latest` for
> `EngineIncludeOrderVersion.Unreal5_8` once you have confirmed it in your
> engine's UnrealBuildTool.

## What is included

- `MountHope.uproject`: UE5 project descriptor with `EnhancedInput` and
  `ChaosVehicles` enabled.
- `Source/MountHope`: C++ runtime module with foundational gameplay subsystems:
  - `UMHWorldSliceSubsystem`: loads the real New Bedford slice JSON already used
    by the web build (`QUAHOG_Web/public/slice-newbedford.json`).
  - `UMHMissionSubsystem`: mission chain loader + progression state.
  - `UMHGameStateSubsystem`: wallet/health, dual-axis heat, weather state, and
    property economy primitives.
  - `UMountHopeGameInstance`: bootstraps the above from JSON files on startup.
- Playable framework classes:
  - `AMountHopeCharacter`: Enhanced Input-ready walk/look/sprint + enter/exit vehicle shell.
  - `AMountHopeVehiclePawn`: Chaos wheeled-vehicle base pawn for drivable cars.
  - `AMountHopeGameMode`: heat decay tick + objective completion/reward routing + auto objective-trigger placement from mission step data.
  - `AMHMissionTriggerActor`: reusable overlap trigger to advance mission objectives.
  - `UMHSaveGame`: save slot payload for wallet/health/heat/weather/owned assets.
- `Data/Missions/vertical_slice.json`: opening mission chain seed.
- `Data/Economy/businesses.json`: first-pass property roster seed.

## Open in Unreal

1. Install Unreal Engine 5.8 via Epic Games Launcher.
2. In Unreal Editor, open `QUAHOG_Unreal/MountHope.uproject`.
3. Let Unreal generate project files and compile C++.
4. Confirm startup logs show:
   - slice load count (roads/buildings/landmarks),
   - mission file load count,
   - business file load count.
5. Place a player start and at least one `AMountHopeVehiclePawn` in the map.
6. Optional: if using custom objective flow, place `AMHMissionTriggerActor` manually.
   Otherwise `AMountHopeGameMode` auto-spawns/repositions one for target steps.

## Current status

This is a production-oriented foundation, not a content-complete game. It gives
you a clean Unreal code spine to continue into:

- character controller and combat,
- Chaos vehicle pawn and tuning,
- World Partition map composition and streaming,
- AI crowd/traffic,
- save/load and platform integrations,
- cinematics, VO, and mission scripting.

## Next build steps (recommended)

1. Create and assign `UInputMappingContext` + `UInputAction` assets in editor
   (`Move`, `Look`, `Sprint`, `Interact`) to activate the character bindings.
2. Build a georeferenced New Bedford map level with World Partition and import
   hero landmarks.
3. Replace JSON bootstrap data with DataAssets + editor tooling.
4. Add mission-authoring utilities for batch trigger visualization and debug UX.
5. Stand up an automated content cook/package pipeline for Windows first, then
   PS5 and Xbox.
