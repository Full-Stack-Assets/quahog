# Path D: The Prologue — 7-Phase Opening Sequence

## Goal
A polished 10-15 minute opening that teaches all core mechanics through gameplay.

## Phase Breakdown

### Phase 1: Arrival (60s)
- Cinematic intro: camera pans over South Coast harbor at midnight in dense fog
- Player character steps off a fishing boat onto the pier
- Ambient: seagulls, distant foghorn, LighthouseBeam rotating
- Tutorial: "Press W/A/S/D to move"

### Phase 2: Ambush (90s)
- Player walks toward town center
- FloodlightController.SnapOn() — blinding spotlights from alleys
- DynamicSpawner spawns 4 hostiles
- WantedLevelDisplay flashes: HeatManager.AddWantedLevel(2)
- Audio: gunshots, barks (Alert), siren
- Tutorial: "Press Left Shift to sprint, Space to take cover"

### Phase 3: Escape (120s)
- Player must sprint through alleys to escape
- PedestrianAI.Fleeing state triggers — civilians scatter
- WeatherController.TransitionWeather(CoastalRain) for drama
- GridlockZone on canal bridge slows pursuit
- Tutorial: "Find a vehicle. Press F to enter."

### Phase 4: Drive (180s)
- VehiclePrefabFactory spawns sedan near player
- GPS route via WaypointSystem to safehouse
- RadioManager auto-tunes WBCN Rock
- DJChatter plays "first time in town" line
- VehicleController.SetWeatherFriction(CoastalRain) — slippery
- Tutorial: "Drive to the safehouse. Follow the GPS marker."

### Phase 5: Safehouse (60s)
- Player enters safehouse trigger zone
- SafehouseManager.EnterSafehouse("flour_mill")
- Screen fades, time advances +6 hours
- HeatManager.ClearHeat()
- SaveLoadManager.SaveGame(0)
- Tutorial: "Press F1 for debug info. This is your safehouse."

### Phase 6: First Property (120s)
- Player wakes to dawn lighting
- TimeOfDayClock advances, SceneLightingSetup transitions
- ObjectiveMarker points to first property (flour_mill)
- PropertyPlacement highlights marker with yellow glow
- Player interacts: AcquisitionEngine.ProcessPurchase()
- Wallet deducts, RevenueManager registers, UI shows yield
- Tutorial: "Properties earn daily income. Return to collect."

### Phase 7: Free Roam
- All missions unlocked via MissionManager.UnlockPhaseMissions(FreeRoam)
- Tutorial: "South Coast is yours. Explore, build your empire."
- GloriaEventDirector is now triggerable (random or mission)
- ChopShopArmsManager opens after flour_mill purchase

## Files to Create/Modify

### NEW FILES (5)
1. **PrologueSequence.cs** — Master coroutine orchestrating all 7 phases
2. **ArrivalCinematic.cs** — Camera pan + player placement for Phase 1
3. **AmbushTrigger.cs** — Floodlights + enemy spawn + heat for Phase 2
4. **EscapeRoute.cs** — Waypoint markers + civilian flee triggers for Phase 3
5. **DriveTutorial.cs** — Vehicle spawn + GPS + radio + DJ line for Phase 4

### MODIFIED FILES (8)
6. **PrologueDirector.cs** — Wire phase transitions to real systems
7. **CutsceneManager.cs** — Add arrival shot sequence
8. **TutorialSystem.cs** — Add prologue-specific prompts
9. **MissionManager.cs** — Lock all missions except prologue strand
10. **WeatherController.cs** — Trigger rain during escape
11. **ObjectiveMarker.cs** — Pulsing highlight for first property
12. **PropertyPlacement.cs** — Highlight first property during prologue
13. **HUDManager.cs** — Suppress non-essential UI during prologue
