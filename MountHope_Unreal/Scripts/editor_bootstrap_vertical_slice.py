#!/usr/bin/env python3
"""
Mount Hope — vertical-slice editor bootstrap.

Run inside Unreal Editor 5.6+ with the Python Editor Script Plugin enabled:
  Tools → Execute Python Script → select this file

Creates /Game/Maps/MH_VerticalSlice, content folders, a player start, and a
placed MHVehiclePawn instance. Blueprint subclasses and Chaos wheel tuning
still require manual editor steps (see Docs/EDITOR_SETUP.md).
"""

from __future__ import annotations

try:
    import unreal
except ImportError as exc:  # pragma: no cover - only runs inside UE
    raise SystemExit(
        "This script must run inside the Unreal Editor Python environment."
    ) from exc


MAP_PATH = "/Game/Maps/MH_VerticalSlice"
PLAYER_START_LOCATION = unreal.Vector(-27200.0, 0.0, 200.0)
PLAYER_START_ROTATION = unreal.Rotator(0.0, 0.0, 0.0)
VEHICLE_LOCATION = unreal.Vector(-27000.0, 500.0, 200.0)
VEHICLE_ROTATION = unreal.Rotator(0.0, 90.0, 0.0)

CONTENT_FOLDERS = (
    "/Game/Maps",
    "/Game/Blueprints",
    "/Game/Input",
    "/Game/Materials",
    "/Game/OSM",
)


def log(message: str) -> None:
    unreal.log(f"[MountHope Bootstrap] {message}")


def warn(message: str) -> None:
    unreal.log_warning(f"[MountHope Bootstrap] {message}")


def ensure_content_folders() -> None:
    for folder in CONTENT_FOLDERS:
        if not unreal.EditorAssetLibrary.does_directory_exist(folder):
            unreal.EditorAssetLibrary.make_directory(folder)
            log(f"Created content folder: {folder}")


def save_map_if_needed() -> None:
    if unreal.EditorAssetLibrary.does_asset_exist(MAP_PATH):
        log(f"Map already exists: {MAP_PATH}")
        unreal.EditorLoadingAndSavingUtils.load_map(MAP_PATH)
        return

    log("Creating new Open World map...")
    unreal.EditorLoadingAndSavingUtils.new_blank_map(save_existing_packages=False)

    saved = unreal.EditorLoadingAndSavingUtils.save_map(
        unreal.EditorLevelLibrary.get_editor_world(),
        MAP_PATH,
    )
    if not saved:
        warn(f"Failed to save map to {MAP_PATH}")
    else:
        log(f"Saved map: {MAP_PATH}")


def spawn_or_find_player_start() -> None:
    world = unreal.EditorLevelLibrary.get_editor_world()
    for actor in unreal.EditorLevelLibrary.get_all_level_actors():
        if isinstance(actor, unreal.PlayerStart):
            actor.set_actor_location(PLAYER_START_LOCATION, False, True)
            actor.set_actor_rotation(PLAYER_START_ROTATION, False)
            log("Repositioned existing PlayerStart")
            return

    unreal.EditorLevelLibrary.spawn_actor_from_class(
        unreal.PlayerStart,
        PLAYER_START_LOCATION,
        PLAYER_START_ROTATION,
    )
    log("Spawned PlayerStart")


def spawn_vehicle_pawn() -> None:
    vehicle_class = unreal.load_class(None, "/Script/MountHope.MHVehiclePawn")
    if vehicle_class is None:
        warn("Could not load MHVehiclePawn; compile C++ first.")
        return

    for actor in unreal.EditorLevelLibrary.get_all_level_actors():
        if actor.get_class() == vehicle_class:
            log("MHVehiclePawn already placed in level")
            return

    unreal.EditorLevelLibrary.spawn_actor_from_class(
        vehicle_class,
        VEHICLE_LOCATION,
        VEHICLE_ROTATION,
    )
    log("Spawned MHVehiclePawn (assign mesh + Chaos wheels in editor)")


def save_dirty_packages() -> None:
    unreal.EditorLoadingAndSavingUtils.save_dirty_packages(True, True)


def print_next_steps() -> None:
    warn(
        "Run next:\n"
        "  1. Scripts/editor_create_enhanced_input.py\n"
        "  2. Scripts/editor_import_osm.py\n"
        "  3. Create BP_MHPlayerCharacter / BP_MHVehicle (mesh + Chaos wheels)\n"
        "  4. Press Play — see Docs/EDITOR_SETUP.md"
    )


def main() -> None:
    log("Starting vertical-slice bootstrap...")
    ensure_content_folders()
    save_map_if_needed()
    spawn_or_find_player_start()
    spawn_vehicle_pawn()
    save_dirty_packages()
    print_next_steps()
    log("Bootstrap complete.")


if __name__ == "__main__":
    main()
