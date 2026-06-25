# Mount Hope Unreal Foundation (UE5)

This directory is a UE5 C++ bootstrap for a console/PC version of Mount Hope,
derived from the existing South Coast gameplay concept in this repo.

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
- `Data/Missions/vertical_slice.json`: opening mission chain seed.
- `Data/Economy/businesses.json`: first-pass property roster seed.

## Open in Unreal

1. Install Unreal Engine 5.4+ via Epic Games Launcher.
2. In Unreal Editor, open `QUAHOG_Unreal/MountHope.uproject`.
3. Let Unreal generate project files and compile C++.
4. Confirm startup logs show:
   - slice load count (roads/buildings/landmarks),
   - mission file load count,
   - business file load count.

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

1. Add `AMountHopeCharacter` + `AMountHopeVehiclePawn` with Enhanced Input.
2. Add a `GameMode` that binds objective checks to `UMHMissionSubsystem`.
3. Build a georeferenced New Bedford map level with World Partition and import
   hero landmarks.
4. Replace JSON bootstrap data with DataAssets + editor tooling.
5. Stand up an automated content cook/package pipeline for Windows first, then
   PS5 and Xbox.
