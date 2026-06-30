# Legacy / reference — not actively developed

The canonical **PC/console Unreal track** is **`../MountHope_Unreal/`**.

This directory (`QUAHOG_Unreal/`) was an earlier UE 5.8 bootstrap that explored
the same JSON-driven mission/economy/world-slice framework. Its C++ patterns
were merged into `MountHope_Unreal/` (see `MountHope_Unreal/Docs/IMPROVEMENT_PLAN.md`).

## What to use instead

| Need | Use |
| --- | --- |
| Unreal project | `MountHope_Unreal/MountHope.uproject` |
| Validation | `python3 MountHope_Unreal/Scripts/validate_scaffold.py` |
| Editor setup | `MountHope_Unreal/Docs/EDITOR_SETUP.md` |
| Playable game | `QUAHOG_Web/` (canonical browser build) |

## Why this tree remains

- Historical reference for class naming (`MountHopeCharacter` vs `MHPlayerCharacter`)
- `Tools/validate_bootstrap.py` may still be useful when diffing against the
  canonical tree during migration

Do not add new features here. Port changes to `MountHope_Unreal/`.
