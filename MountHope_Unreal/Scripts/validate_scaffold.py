#!/usr/bin/env python3
"""Validate the Unreal scaffold without requiring Unreal Engine."""

from __future__ import annotations

import json
from pathlib import Path
import sys


PROJECT_ROOT = Path(__file__).resolve().parents[1]
REPO_ROOT = PROJECT_ROOT.parent


REQUIRED_FILES = [
    "MountHope.uproject",
    "Config/DefaultEngine.ini",
    "Config/DefaultGame.ini",
    "Config/DefaultInput.ini",
    "Source/MountHope.Target.cs",
    "Source/MountHopeEditor.Target.cs",
    "Source/MountHope/MountHope.Build.cs",
    "Source/MountHope/MountHope.cpp",
    "Source/MountHope/MHGameInstance.h",
    "Source/MountHope/MHGameInstance.cpp",
    "Source/MountHope/MHGameModeBase.h",
    "Source/MountHope/MHGameModeBase.cpp",
    "Source/MountHope/MHPlayerCharacter.h",
    "Source/MountHope/MHPlayerCharacter.cpp",
    "Source/MountHope/MHVehiclePawn.h",
    "Source/MountHope/MHVehiclePawn.cpp",
    "Source/MountHope/MHInteractable.h",
    "Source/MountHope/MHEconomySubsystem.h",
    "Source/MountHope/MHEconomySubsystem.cpp",
    "Source/MountHope/MHMissionSubsystem.h",
    "Source/MountHope/MHMissionSubsystem.cpp",
    "Source/MountHope/MHOpenWorldSubsystem.h",
    "Source/MountHope/MHOpenWorldSubsystem.cpp",
    "Source/MountHope/MHWorldSliceSubsystem.h",
    "Source/MountHope/MHWorldSliceSubsystem.cpp",
    "Source/MountHope/MHWorldSliceTypes.h",
    "Source/MountHope/MHGameStateSubsystem.h",
    "Source/MountHope/MHGameStateSubsystem.cpp",
    "Source/MountHope/MHSaveGame.h",
    "Source/MountHope/MHMissionTriggerActor.h",
    "Source/MountHope/MHMissionTriggerActor.cpp",
    "Data/Missions/vertical_slice.json",
    "Data/Economy/businesses.json",
    "Docs/VERTICAL_SLICE.md",
    "Docs/OSM_TO_UNREAL.md",
    "Scripts/build.sh",
]

EXPECTED_PLUGINS = {
    "EnhancedInput",
    "ChaosVehiclesPlugin",
    "MassEntity",
    "MassAI",
    "Water",
}

EXPECTED_EXISTING_DATA = [
    "quahog-project-files/mapdata/southcoast-roads.json",
    "quahog-project-files/mapdata/southcoast.obj",
    "QUAHOG_Web/public/slice-newbedford.json",
]


def fail(message: str) -> None:
    print(f"ERROR: {message}", file=sys.stderr)
    raise SystemExit(1)


def read_text(relative_path: str) -> str:
    path = PROJECT_ROOT / relative_path
    if not path.exists():
        fail(f"missing required file: {relative_path}")
    return path.read_text(encoding="utf-8")


def load_json(relative_path: str) -> dict:
    try:
        return json.loads(read_text(relative_path))
    except json.JSONDecodeError as exc:
        fail(f"{relative_path} is invalid JSON: {exc}")


def validate_uproject() -> None:
    descriptor = load_json("MountHope.uproject")

    modules = descriptor.get("Modules", [])
    if not any(module.get("Name") == "MountHope" for module in modules):
        fail("MountHope.uproject does not declare the MountHope runtime module")

    enabled_plugins = {
        plugin.get("Name")
        for plugin in descriptor.get("Plugins", [])
        if plugin.get("Enabled") is True
    }
    missing_plugins = EXPECTED_PLUGINS - enabled_plugins
    if missing_plugins:
        fail(f"MountHope.uproject is missing plugins: {sorted(missing_plugins)}")


def validate_required_files() -> None:
    for relative_path in REQUIRED_FILES:
        read_text(relative_path)


def validate_target_rules() -> None:
    for target in ("MountHope.Target.cs", "MountHopeEditor.Target.cs"):
        text = read_text(f"Source/{target}")
        if "EngineIncludeOrderVersion.Unreal5_4" in text:
            fail(f"{target} still pins the legacy Unreal5_4 include order")
        if "DefaultBuildSettings" not in text:
            fail(f"{target} missing DefaultBuildSettings")
        if "IncludeOrderVersion" not in text:
            fail(f"{target} missing IncludeOrderVersion")


def validate_no_deprecated_macros() -> None:
    src_root = PROJECT_ROOT / "Source" / "MountHope"
    for path in src_root.rglob("*.cpp"):
        text = path.read_text(encoding="utf-8")
        for line in text.splitlines():
            if "UE_KINDA_SMALL_NUMBER" in line or "KINDA_SMALL_NUMBER" not in line:
                continue
            fail(f"{path.name}: use UE_KINDA_SMALL_NUMBER instead of KINDA_SMALL_NUMBER")


def validate_source_contract() -> None:
    module_source = read_text("Source/MountHope/MountHope.cpp")
    if 'IMPLEMENT_PRIMARY_GAME_MODULE(FDefaultGameModuleImpl, MountHope, "MountHope")' not in module_source:
        fail("MountHope.cpp does not implement the primary game module")

    game_mode_source = read_text("Source/MountHope/MHGameModeBase.cpp")
    if "AMHPlayerCharacter::StaticClass()" not in game_mode_source:
        fail("MHGameModeBase.cpp does not set MHPlayerCharacter as the default pawn")
    for symbol in (
        "CompleteCurrentObjective",
        "TryCompleteVehicleObjective",
        "RefreshObjectiveTrigger",
    ):
        if symbol not in game_mode_source:
            fail(f"MHGameModeBase.cpp is missing mission helper: {symbol}")

    player_source = read_text("Source/MountHope/MHPlayerCharacter.cpp")
    for binding in ("MoveForward", "MoveRight", "Interact", "EnterExitVehicle"):
        if binding not in player_source:
            fail(f"MHPlayerCharacter.cpp is missing input binding: {binding}")
    for symbol in ("EnterVehicle", "ExitVehicle", "FindNearestVehicle"):
        if symbol not in player_source:
            fail(f"MHPlayerCharacter.cpp is missing vehicle helper: {symbol}")

    trigger_source = read_text("Source/MountHope/MHMissionTriggerActor.cpp")
    for symbol in ("SetTriggerRadius", "ResetConsumed"):
        if symbol not in trigger_source:
            fail(f"MHMissionTriggerActor.cpp is missing: {symbol}")

    build_source = read_text("Source/MountHope/MountHope.Build.cs")
    for dependency in ("EnhancedInput", "GameplayTags", "ChaosVehicles", "Json"):
        if dependency not in build_source:
            fail(f"MountHope.Build.cs is missing dependency: {dependency}")


def validate_default_config() -> None:
    default_game = read_text("Config/DefaultGame.ini")
    if "GameInstanceClass=/Script/MountHope.MHGameInstance" not in default_game:
        fail("DefaultGame.ini does not wire MHGameInstance")
    if "GlobalDefaultGameMode=/Script/MountHope.MHGameModeBase" not in default_game:
        fail("DefaultGame.ini does not wire MHGameModeBase")


def validate_missions() -> None:
    data = load_json("Data/Missions/vertical_slice.json")
    missions = data.get("missions", [])
    if not missions:
        fail("No missions defined in vertical_slice.json")
    for mission in missions:
        if not mission.get("title"):
            fail("Mission title is required")
        steps = mission.get("steps", [])
        if not steps:
            fail(f"Mission {mission.get('title')} has no steps")
        for step in steps:
            for field in ("text", "needVehicle", "reward"):
                if field not in step:
                    fail(f"Mission step missing field: {field}")


def validate_economy() -> None:
    data = load_json("Data/Economy/businesses.json")
    businesses = data.get("businesses", [])
    if not businesses:
        fail("No businesses defined in businesses.json")
    seen: set[str] = set()
    for business in businesses:
        bid = business.get("id")
        if not bid:
            fail("Business missing id")
        if bid in seen:
            fail(f"Duplicate business id: {bid}")
        seen.add(bid)
        if business.get("cost", 0) < 0:
            fail(f"Invalid cost for {bid}")
        if business.get("dailyIncome", 0) < 0:
            fail(f"Invalid dailyIncome for {bid}")


def validate_existing_data_links() -> None:
    for relative_path in EXPECTED_EXISTING_DATA:
        if not (REPO_ROOT / relative_path).exists():
            fail(f"referenced existing data is missing: {relative_path}")


def main() -> None:
    validate_uproject()
    validate_required_files()
    validate_target_rules()
    validate_no_deprecated_macros()
    validate_source_contract()
    validate_default_config()
    validate_missions()
    validate_economy()
    validate_existing_data_links()
    print("MountHope_Unreal scaffold validation passed")


if __name__ == "__main__":
    main()
