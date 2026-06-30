#!/usr/bin/env python3
"""
Add or resize a Nav Mesh Bounds Volume for the vertical slice play area.

Run inside Unreal Editor after OSM geometry / road splines are placed.
"""

from __future__ import annotations

try:
    import unreal
except ImportError as exc:  # pragma: no cover
    raise SystemExit(
        "This script must run inside the Unreal Editor Python environment."
    ) from exc


MAP_PATH = "/Game/Maps/MH_VerticalSlice"

# Meters → centimeters; covers default waterfront bbox + margin
EXTENT_X_CM = 120000.0  # 1200m east/west
EXTENT_Y_CM = 8000.0    # 80m vertical band
EXTENT_Z_CM = 120000.0  # 1200m north/south
CENTER = unreal.Vector(-27200.0, 0.0, 10600.0)


def log(message: str) -> None:
    unreal.log(f"[MountHope Nav] {message}")


def load_map() -> None:
    if unreal.EditorAssetLibrary.does_asset_exist(MAP_PATH):
        unreal.EditorLoadingAndSavingUtils.load_map(MAP_PATH)


def find_or_spawn_nav_bounds() -> unreal.NavMeshBoundsVolume:
    for actor in unreal.EditorLevelLibrary.get_all_level_actors():
        if isinstance(actor, unreal.NavMeshBoundsVolume):
            log("Resizing existing NavMeshBoundsVolume")
            return actor

    actor = unreal.EditorLevelLibrary.spawn_actor_from_class(
        unreal.NavMeshBoundsVolume,
        CENTER,
        unreal.Rotator(0.0, 0.0, 0.0),
    )
    log("Spawned NavMeshBoundsVolume")
    return actor


def main() -> None:
    load_map()
    volume = find_or_spawn_nav_bounds()
    volume.set_actor_location(CENTER, False, True)
    volume.set_actor_scale3d(
        unreal.Vector(
            EXTENT_X_CM / 100.0,
            EXTENT_Y_CM / 100.0,
            EXTENT_Z_CM / 100.0,
        )
    )
    unreal.EditorLevelLibrary.build_paths()
    unreal.EditorLoadingAndSavingUtils.save_dirty_packages(True, True)
    log("Nav bounds placed. Press P to visualize; build paths if needed.")


if __name__ == "__main__":
    main()
