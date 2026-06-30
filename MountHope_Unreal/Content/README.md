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
| `/Game/Input/IMC_Default` | Enhanced Input mapping context | Run `editor_create_enhanced_input.py` |
| `/Game/Input/IA_Move`, `IA_Look`, `IA_Sprint`, `IA_Interact` | Input actions | Created by same script |
| `/Game/OSM/SM_SouthCoast_Blockout` | OSM graybox mesh | Run `editor_import_osm.py` |

## Automation

Run in order via **Tools → Execute Python Script**:

1. `Scripts/editor_bootstrap_vertical_slice.py` — map, player start, vehicle
2. `Scripts/editor_create_enhanced_input.py` — Input Actions + IMC
3. `Scripts/editor_import_osm.py` — OSM mesh + road splines

See `Docs/EDITOR_SETUP.md` for the full walkthrough.
