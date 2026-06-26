#!/usr/bin/env python3
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def load_json(path: Path):
    with path.open("r", encoding="utf-8") as f:
        return json.load(f)


def validate_uproject():
    project = load_json(ROOT / "MountHope.uproject")
    module_names = {m["Name"] for m in project.get("Modules", [])}
    assert "MountHope" in module_names, "MountHope module missing in .uproject"
    plugins = {p["Name"] for p in project.get("Plugins", [])}
    assert "EnhancedInput" in plugins, "EnhancedInput plugin missing"
    assert "ChaosVehiclesPlugin" in plugins, "ChaosVehiclesPlugin missing"
    assert "WorldPartitionHLODUtilities" in plugins, "WorldPartitionHLODUtilities missing"


def validate_expected_code_files():
    expected = [
        ROOT / "Source" / "MountHope" / "Public" / "MountHopeCharacter.h",
        ROOT / "Source" / "MountHope" / "Private" / "MountHopeCharacter.cpp",
        ROOT / "Source" / "MountHope" / "Public" / "MountHopeVehiclePawn.h",
        ROOT / "Source" / "MountHope" / "Private" / "MountHopeVehiclePawn.cpp",
        ROOT / "Source" / "MountHope" / "Public" / "MountHopeGameMode.h",
        ROOT / "Source" / "MountHope" / "Private" / "MountHopeGameMode.cpp",
        ROOT / "Source" / "MountHope" / "Public" / "MHMissionTriggerActor.h",
        ROOT / "Source" / "MountHope" / "Private" / "MHMissionTriggerActor.cpp",
        ROOT / "Source" / "MountHope" / "Public" / "MHSaveGame.h",
    ]
    missing = [str(path.relative_to(ROOT)) for path in expected if not path.exists()]
    assert not missing, f"Missing expected Unreal framework files: {missing}"


def validate_missions():
    data = load_json(ROOT / "Data" / "Missions" / "vertical_slice.json")
    missions = data.get("missions", [])
    assert missions, "No missions defined"
    for mission in missions:
        assert mission.get("title"), "Mission title is required"
        steps = mission.get("steps", [])
        assert steps, f"Mission {mission.get('title')} has no steps"
        for step in steps:
            assert "text" in step, "Mission step missing text"
            assert "needVehicle" in step, "Mission step missing needVehicle"
            assert "reward" in step, "Mission step missing reward"


def validate_economy():
    data = load_json(ROOT / "Data" / "Economy" / "businesses.json")
    businesses = data.get("businesses", [])
    assert businesses, "No businesses defined"
    seen = set()
    for b in businesses:
        bid = b.get("id")
        assert bid, "Business missing id"
        assert bid not in seen, f"Duplicate business id: {bid}"
        seen.add(bid)
        assert b.get("cost", 0) >= 0, f"Invalid cost for {bid}"
        assert b.get("dailyIncome", 0) >= 0, f"Invalid dailyIncome for {bid}"


def validate_default_config():
    default_game = (ROOT / "Config" / "DefaultGame.ini").read_text(encoding="utf-8")
    assert "GameInstanceClass=/Script/MountHope.MountHopeGameInstance" in default_game
    assert "GlobalDefaultGameMode=/Script/MountHope.MountHopeGameMode" in default_game


def validate_framework_wiring():
    char_cpp = (ROOT / "Source" / "MountHope" / "Private" / "MountHopeCharacter.cpp").read_text(encoding="utf-8")
    mode_cpp = (ROOT / "Source" / "MountHope" / "Private" / "MountHopeGameMode.cpp").read_text(encoding="utf-8")
    trigger_cpp = (ROOT / "Source" / "MountHope" / "Private" / "MHMissionTriggerActor.cpp").read_text(encoding="utf-8")

    assert "SetupPlayerInputComponent" in char_cpp, "Character input binding missing"
    assert "TryCompleteVehicleObjective" in mode_cpp, "Vehicle objective helper missing"
    assert "RefreshObjectiveTrigger" in mode_cpp, "Objective trigger refresh missing"
    assert "SetTriggerRadius" in trigger_cpp, "Trigger radius setter missing"
    assert "ResetConsumed" in trigger_cpp, "Trigger consumed reset missing"


if __name__ == "__main__":
    validate_uproject()
    validate_expected_code_files()
    validate_missions()
    validate_economy()
    validate_default_config()
    validate_framework_wiring()
    print("MountHope Unreal bootstrap validation passed.")
