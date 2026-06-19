# Project QUAHOG — Godot 4 Setup Guide

**Engine:** Godot 4.2+ (Forward+ renderer)
**Language:** GDScript
**Original codebase:** Unity C# (93 files, ~13K lines) → **48 GDScript files, ~6,100 lines**

---

## Quick Start

### 1. Install Godot
Download **Godot 4.2 or later** from [godotengine.org](https://godotengine.org/download).
- Use the **standard build** (not .NET/C# version — this project is pure GDScript)

### 2. Open the project
1. Launch Godot → **Import**
2. Point it at the `QUAHOG_Godot/` folder (where `project.godot` lives)
3. Let the engine import and index all scripts (takes ~10s on first open)

### 3. Create the Bootstrap scene
The main scene is set to `res://scenes/bootstrap/Bootstrap.tscn` — you need to create it:

1. **Scene → New Scene**
2. Root node: `Node` — rename to `Bootstrap`
3. Add a child `WorldEnvironment` node (required by WeatherController, FogController, CoastalNeonPostProcess)
4. Save as `res://scenes/bootstrap/Bootstrap.tscn`

That's it for a first boot. The 13 autoloads initialize automatically on run.

### 4. Press Play
Hit **F5** (or the Play button). In the **Output** panel you should see:
```
[GameManager] State → Boot
[WeatherController] Initialized — state: CLEAR
[TimeOfDayClock] Day 1, 00:00
[MissionManager] 22 missions registered. ns_01_intro → AVAILABLE
[SafehouseManager] 4 safehouses initialized
```

If you see those lines, the core engine is alive.

---

## Project Structure

```
QUAHOG_Godot/
│
├── project.godot              ← Godot project config, input map, autoloads
│
├── autoloads/                 ← 13 global singletons (auto-initialized)
│   ├── GameManager.gd         ← State machine: Boot/MainMenu/Playing/Paused/Cutscene
│   ├── PlayerWallet.gd        ← Balance, deduct, add — fires balance_changed signal
│   ├── SaveLoadManager.gd     ← 5-slot JSON saves with SHA-256 checksum
│   ├── InputManager.gd        ← Unified input, dead-zone, KB+mouse↔gamepad detection
│   ├── TimeOfDayClock.gd      ← 24h cycle, hour/midnight/day signals
│   ├── WeatherController.gd   ← 4-state FSM: CLEAR/DENSE_FOG/COASTAL_RAIN/NOREASTER
│   ├── HeatManager.gd         ← Wanted level (0-5) + per-faction aggro (0-100)
│   ├── SafehouseManager.gd    ← 4 safehouses, sleep/save/heat-clear flow
│   ├── RadioManager.gd        ← 5 stations (WMILL/RADIO_ATLANTICO/WRGE/WYAC/OFF)
│   ├── RevenueManager.gd      ← Daily property yields at midnight
│   ├── MissionManager.gd      ← 22 missions across 7 strands, prerequisite graph
│   ├── GloriaEventDirector.gd ← 5-phase hurricane event sequence
│   └── HUDManager.gd          ← CanvasLayer HUD coordinator
│
├── scripts/
│   ├── core/
│   │   ├── GameConstants.gd   ← All district/faction/mission/safehouse ID strings
│   │   ├── GameDataStructures.gd ← SaveData, PropertySaveData, MissionSaveData
│   │   ├── GameInterfaces.gd  ← IInteractable, IDamageable base classes
│   │   └── ServiceLocator.gd  ← Typed service registry (String key → Object)
│   │
│   ├── player/
│   │   └── PlayerController.gd ← CharacterBody3D: move, camera orbit, ADS, interact, cover
│   │
│   ├── world/
│   │   ├── WeatherVisualEffects.gd ← GPUParticles3D rain/snow, lightning OmniLight3D
│   │   ├── FogController.gd        ← Tween-based fog density blending
│   │   ├── CoastalNeonPostProcess.gd ← Per-district ambient color grading
│   │   └── LighthouseBeam.gd       ← Rotating beacon + player detection raycast
│   │
│   ├── systems/
│   │   ├── assets/
│   │   │   ├── AssetPropertyData.gd ← Resource: property data model
│   │   │   ├── AssetProperty.gd     ← Node3D + IInteractable: buy/yield flow
│   │   │   └── AcquisitionEngine.gd ← Purchase validation + mission unlock
│   │   ├── combat/
│   │   │   ├── CombatController.gd  ← 5-weapon system, raycast hit, async reload
│   │   │   └── FactionHostilityManager.gd ← Territory detection, hit squad spawning
│   │   ├── audio/
│   │   │   ├── AudioBarkManager.gd  ← NPC contextual voice lines by region
│   │   │   └── DJChatterSystem.gd   ← Context-aware DJ commentary + radio ducking
│   │   ├── ai/
│   │   │   ├── PedestrianAI.gd     ← 5-state FSM + NavigationAgent3D
│   │   │   ├── DynamicSpawner.gd   ← Spawn/despawn by region density
│   │   │   └── RegionProfile.gd    ← Resource: per-district demographic config
│   │   └── traffic/
│   │       ├── VehicleAI.gd          ← 4-state FSM + NavigationAgent3D
│   │       ├── GridlockZone.gd       ← Area3D canal bridge gridlock + honking
│   │       └── RegionalVehiclePool.gd ← Weighted vehicle type selection
│   │
│   ├── events/
│   │   ├── FloodSystem.gd           ← Dynamic water plane rise/recede
│   │   ├── BoatSinkSystem.gd        ← 3-stage boat sinking sequence
│   │   └── EmergencyBroadcastSystem.gd ← EAS radio override
│   │
│   ├── controllers/
│   │   └── VehicleController.gd    ← VehicleBody3D: motor/steer/brake, weather friction
│   │
│   ├── vehicle/
│   │   └── BuoyancyEffector.gd     ← Multi-point hull buoyancy physics
│   │
│   └── ui/
│       ├── MinimapController.gd    ← SubViewportContainer + icon projection
│       ├── WantedLevelDisplay.gd   ← 5-star TextureRect array
│       ├── CashCounter.gd          ← Animated tween number count-up
│       ├── HealthArmorDisplay.gd   ← Dual ProgressBar with color threshold
│       ├── DistrictNameDisplay.gd  ← Fade-in/out Label banner
│       ├── FactionHostilityDisplay.gd ← Per-faction aggro bars
│       ├── RadioStationWidget.gd   ← Station + song label display
│       └── RadarBlipSystem.gd      ← Player-relative blip projection
│
└── scenes/
    └── bootstrap/
        └── Bootstrap.tscn          ← Create this (see Quick Start step 3)
```

---

## Autoload Signal Map

The event-driven architecture is preserved exactly from Unity. Key cross-system wires:

| Signal | Emitter | Connected To |
|--------|---------|-------------|
| `TimeOfDayClock.midnight` | TimeOfDayClock | RevenueManager.process_daily_yield |
| `WeatherController.weather_changed` | WeatherController | VehicleController, WeatherVisualEffects, FogController, PedestrianAI |
| `PlayerWallet.balance_changed` | PlayerWallet | CashCounter |
| `HeatManager.wanted_level_changed` | HeatManager | WantedLevelDisplay, PedestrianAI, AudioBarkManager, DJChatterSystem |
| `HeatManager.heat_cleared` | HeatManager | SafehouseManager |
| `MissionManager.mission_completed` | MissionManager | AcquisitionEngine.unlock_linked_mission, DJChatterSystem |
| `SafehouseManager.player_slept` | SafehouseManager | TimeOfDayClock.advance_hours(6), SaveLoadManager, HeatManager.clear_heat |
| `GloriaEventDirector.gloria_phase_changed` | GloriaEventDirector | WeatherController, VehicleController, FloodSystem, EmergencyBroadcastSystem |

---

## Input Actions (all pre-mapped in project.godot)

| Action | Keyboard | Gamepad |
|--------|----------|---------|
| move_forward / back / left / right | WASD | Left stick |
| sprint | Left Shift | R3 |
| jump | Space | A (Xbox) / Cross (PS) |
| interact | E | X (Xbox) / Square (PS) |
| fire | LMB | RT/R2 |
| aim | RMB | LT/L2 |
| reload | R | Y/Triangle |
| weapon_next / prev | Scroll up/down | RB/LB |
| pause | Escape | Start |
| map | M | Select/Back |
| radio | N | D-pad up |
| crouch | Left Ctrl | L3 |
| enter_vehicle | F | X/Square |

---

## What's Not in This Port

A few Unity-specific things were left as integration points rather than direct ports:

| Unity System | Godot Equivalent Needed |
|---|---|
| `EmpireDatabaseManager` (SQLite) | Replace with Godot's built-in JSON save (SaveLoadManager already handles this) or add [godot-sqlite](https://github.com/2shady4u/godot-sqlite) plugin |
| `NavMesh baking` (runtime) | Use Godot's `NavigationRegion3D` in scenes; bake in editor or use `NavigationServer3D.bake_from_source_geometry_data()` |
| `WheelCollider` physics | Replaced with `VehicleBody3D` + `VehicleWheel3D` — configure wheel nodes in scene editor |
| Post-processing (URP Volume) | Godot uses `WorldEnvironment` + `Environment` resource — CoastalNeonPostProcess.gd uses `ambient_light_color` |
| `ParticleSystem` particle configs | Replace Unity `.asset` particle configs with Godot `GPUParticles3D` resources in the scene editor |
| `DebugOverlay` (IMGUI) | Port to Godot's built-in debug overlay or use a `CanvasLayer` with `Label` nodes |

---

## First Systems to Test After Boot

Run these in order — each one validates a dependency layer:

1. **PlayerWallet** — call `PlayerWallet.add(1000, "test")` from GDScript console
2. **TimeOfDayClock** — watch Output for hour/midnight signals firing
3. **WeatherController** — call `WeatherController.force_state(WeatherController.WeatherState.NOREASTER)`
4. **HeatManager** — call `HeatManager.add_wanted_level(3)`, watch WantedLevelDisplay update
5. **MissionManager** — call `MissionManager.start_mission("ns_01_intro")`
6. **SafehouseManager** — call `SafehouseManager.enter_safehouse("flour_mill")`, then `SafehouseManager.sleep()`

---

*Project QUAHOG — Godot 4 Port*
*48 GDScript files · ~6,100 lines · 13 autoloads · 22 missions · 4 districts*
