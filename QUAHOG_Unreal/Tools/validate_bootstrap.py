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


if __name__ == "__main__":
    validate_uproject()
    validate_missions()
    validate_economy()
    print("MountHope Unreal bootstrap validation passed.")
