#!/usr/bin/env python3
"""
Create a Widget Blueprint child of UMHGameHudWidget for visual customization.

Run inside Unreal Editor after compiling C++. Optional — the C++ widget builds
its own tree at runtime if no Blueprint is assigned.
"""

from __future__ import annotations

try:
    import unreal
except ImportError as exc:  # pragma: no cover
    raise SystemExit(
        "This script must run inside the Unreal Editor Python environment."
    ) from exc


WIDGET_PATH = "/Game/UI/WBP_MHGameHud"
PARENT_CLASS_PATH = "/Script/MountHope.MHGameHudWidget"


def log(message: str) -> None:
    unreal.log(f"[MountHope UI] {message}")


def warn(message: str) -> None:
    unreal.log_warning(f"[MountHope UI] {message}")


def main() -> None:
    if not unreal.EditorAssetLibrary.does_directory_exist("/Game/UI"):
        unreal.EditorAssetLibrary.make_directory("/Game/UI")

    if unreal.EditorAssetLibrary.does_asset_exist(WIDGET_PATH):
        log(f"Widget already exists: {WIDGET_PATH}")
        return

    parent_class = unreal.load_class(None, PARENT_CLASS_PATH)
    if parent_class is None:
        warn("Compile MHGameHudWidget C++ before running this script.")
        return

    factory = unreal.WidgetBlueprintFactory()
    factory.set_editor_property("parent_class", parent_class)

    asset_tools = unreal.AssetToolsHelpers.get_asset_tools()
    widget = asset_tools.create_asset("WBP_MHGameHud", "/Game/UI", unreal.WidgetBlueprint, factory)
    if widget:
        unreal.EditorAssetLibrary.save_loaded_asset(widget)
        log(f"Created {WIDGET_PATH} — customize fonts/layout, then assign on MHPlayerController.")
    else:
        warn("Failed to create Widget Blueprint.")


if __name__ == "__main__":
    main()
