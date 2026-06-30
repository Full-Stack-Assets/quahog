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
    "Config/DefaultGameplayTags.ini",
    "Config/DefaultGame.ini",
    "Config/DefaultInput.ini",
    "Source/MountHope/MountHope.Build.cs",
    "Source/MountHope/MountHope.cpp",
    "Source/MountHope/MHGameModeBase.h",
    "Source/MountHope/MHGameModeBase.cpp",
    "Source/MountHope/MHPlayerCharacter.h",
    "Source/MountHope/MHPlayerCharacter.cpp",
    "Source/MountHope/MHVehiclePawn.h",
    "Source/MountHope/MHVehiclePawn.cpp",
    "Source/MountHope/MHInteractable.h",
    "Source/MountHope/MHEconomySubsystem.h",
    "Source/MountHope/MHEconomySubsystem.cpp",
    "Source/MountHope/MHDialogueSubsystem.h",
    "Source/MountHope/MHDialogueSubsystem.cpp",
    "Source/MountHope/MHMissionSubsystem.h",
    "Source/MountHope/MHMissionSubsystem.cpp",
    "Source/MountHope/MHOpenWorldSubsystem.h",
    "Source/MountHope/MHOpenWorldSubsystem.cpp",
    "Source/MountHope/MHReputationSubsystem.h",
    "Source/MountHope/MHReputationSubsystem.cpp",
    "Source/MountHope/MHSaveGame.h",
    "Source/MountHope/MHSaveSubsystem.h",
    "Source/MountHope/MHSaveSubsystem.cpp",
    "Source/MountHope/MHWantedSubsystem.h",
    "Source/MountHope/MHWantedSubsystem.cpp",
    "Docs/READY_TO_PLAY_CHECKLIST.md",
    "Docs/VERTICAL_SLICE.md",
    "Docs/OSM_TO_UNREAL.md",
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


def validate_uproject() -> None:
    descriptor_path = PROJECT_ROOT / "MountHope.uproject"
    try:
        descriptor = json.loads(descriptor_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        fail(f"MountHope.uproject is invalid JSON: {exc}")

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


def validate_source_contract() -> None:
    module_source = read_text("Source/MountHope/MountHope.cpp")
    if 'IMPLEMENT_PRIMARY_GAME_MODULE(FDefaultGameModuleImpl, MountHope, "MountHope")' not in module_source:
        fail("MountHope.cpp does not implement the primary game module")

    game_mode_source = read_text("Source/MountHope/MHGameModeBase.cpp")
    if "AMHPlayerCharacter::StaticClass()" not in game_mode_source:
        fail("MHGameModeBase.cpp does not set MHPlayerCharacter as the default pawn")

    player_source = read_text("Source/MountHope/MHPlayerCharacter.cpp")
    for binding in ("MoveForward", "MoveRight", "Interact", "EnterExitVehicle"):
        if binding not in player_source:
            fail(f"MHPlayerCharacter.cpp is missing input binding: {binding}")

    build_source = read_text("Source/MountHope/MountHope.Build.cs")
    for dependency in ("EnhancedInput", "GameplayTags", "ChaosVehicles"):
        if dependency not in build_source:
            fail(f"MountHope.Build.cs is missing dependency: {dependency}")

    subsystem_contracts = {
        "Source/MountHope/MHDialogueSubsystem.h": ("BeginConversation", "AdvanceConversation"),
        "Source/MountHope/MHWantedSubsystem.h": ("ReportCrime", "GetWantedLevel"),
        "Source/MountHope/MHReputationSubsystem.h": ("AddReputation", "MeetsReputation"),
        "Source/MountHope/MHSaveSubsystem.h": ("LoadGameState", "SaveGameState"),
        "Source/MountHope/MHSaveGame.h": ("CashBalance", "CompletedMissions"),
    }
    for relative_path, expected_symbols in subsystem_contracts.items():
        source = read_text(relative_path)
        for symbol in expected_symbols:
            if symbol not in source:
                fail(f"{relative_path} is missing symbol: {symbol}")

    checklist = read_text("Docs/READY_TO_PLAY_CHECKLIST.md")
    for required_phrase in ("Packaged Windows PC build", "Free-roam remains available", "Map uses real OSM-derived"):
        if required_phrase not in checklist:
            fail(f"READY_TO_PLAY_CHECKLIST.md is missing: {required_phrase}")


def validate_existing_data_links() -> None:
    for relative_path in EXPECTED_EXISTING_DATA:
        if not (REPO_ROOT / relative_path).exists():
            fail(f"referenced existing data is missing: {relative_path}")


def main() -> None:
    validate_uproject()
    validate_required_files()
    validate_source_contract()
    validate_existing_data_links()
    print("MountHope_Unreal scaffold validation passed")


if __name__ == "__main__":
    main()
