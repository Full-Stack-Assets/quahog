# Content assets (editor-authored)

Binary `.uasset` files are created in the Unreal Editor and are not committed
until your team chooses to version them. Use this checklist when bootstrapping
the vertical slice.

## Required for Phase 1 PIE

| Asset path | Type | Parent class |
| --- | --- | --- |
| `/Game/Maps/MH_VerticalSlice` | World Partition level | — |
| `/Game/Blueprints/BP_MHPlayerCharacter` | Blueprint | `MHPlayerCharacter` |
| `/Game/Blueprints/BP_MHVehicle` | Blueprint | `MHVehiclePawn` |

## Recommended next

| Asset path | Purpose |
| --- | --- |
| `/Game/Input/IMC_Default` | Enhanced Input mapping context (Phase 3) |
| `/Game/Input/IA_Move`, `IA_Look`, `IA_Interact` | Input actions |
| `/Game/Materials/M_GroundPlaceholder` | Graybox ground |
| `/Game/OSM/SouthCoast_Blockout` | Imported `southcoast.obj` |

## Automation

Run `Scripts/editor_bootstrap_vertical_slice.py` from **Tools → Execute Python
Script** to create the map, folders, player start, and placed vehicle actor
shell. You still need to assign meshes and Chaos wheels in `BP_MHVehicle`.

See `Docs/EDITOR_SETUP.md` for the full walkthrough.
