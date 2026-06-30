# ⚠️ Legacy / reference — use `MountHope_Unreal/` instead

> **This UE 5.8 bootstrap is retired.** All new Unreal work happens in
> [`../MountHope_Unreal/`](../MountHope_Unreal/). See
> [`LEGACY.md`](LEGACY.md) and [`../ENGINES.md`](../ENGINES.md).

---

# Mount Hope Unreal Foundation (UE 5.8) — archived

This directory was a UE5 C++ bootstrap for a console/PC version of Mount Hope.
Its framework code (JSON bootstrap, mission triggers, save game) has been
carried forward into `MountHope_Unreal/`.

## Redirect

| Task | Location |
| --- | --- |
| Open project | `MountHope_Unreal/MountHope.uproject` |
| Validate scaffold | `python3 MountHope_Unreal/Scripts/validate_scaffold.py` |
| First playable setup | `MountHope_Unreal/Docs/EDITOR_SETUP.md` |
| CI | `.github/workflows/unreal-ci.yml` |

## Original notes (archived)

- Target engine: UE **5.8** (`EngineAssociation` in `MountHope.uproject`)
- Included `UMHWorldSliceSubsystem`, `UMHMissionSubsystem`, `UMHGameStateSubsystem`
- Enhanced Input-ready `MountHopeCharacter` (canonical tree still uses legacy
  input for Phase 1; see improvement plan Phase 3)
