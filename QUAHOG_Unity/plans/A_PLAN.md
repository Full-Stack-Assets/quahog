# Path A: Grayboxed Playable Level — Plan

## Goal
A single Unity scene that loads, initializes all systems, and is playable:
- Walk around 4 districts with graybox buildings
- Drive vehicles on roads
- Buy properties, collect revenue
- Combat with ammo/reload
- Radio with DJ chatter
- Weather changes
- Save/load works end-to-end
- HUD shows cash, health, wanted level, minimap

## Files to Create/Modify

### NEW FILES (8)
1. **LevelInitializer.cs** — Master init script, runs after SceneBootstrap
2. **DistrictConfig.cs** — ScriptableObject with all 4 district configs
3. **SpawnPointDatabase.cs** — ScriptableObject with 12 named spawn points
4. **PropertyPlacement.cs** — MonoBehaviour that places property markers in world
5. **SafehousePlacement.cs** — MonoBehaviour that places safehouse triggers
6. **GameplayTest.cs** — Automated walkthrough test (walk, drive, buy, save)
7. **GameSettings.cs** — Global game settings ScriptableObject
8. **README_PLAYABLE.md** — How to set up and play

### MODIFIED FILES (12)
9. **PrologueSceneBuilder.cs** — Fill 11-step coroutine with real calls
10. **SceneBootstrap.cs** — Singleton init order, dependency resolution
11. **DynamicSpawner.cs** — Start spawning on scene ready
12. **TriggerVolumeSetup.cs** — Create default trigger volumes
13. **PlayerController.cs** — Ensure ground check, spawn position
14. **HUDManager.cs** — Auto-wire all subsystems on start
15. **MissionManager.cs** — Unlock prologue missions on init
16. **WeatherController.cs** — Set initial DenseFog state
17. **TimeOfDayClock.cs** — Start at midnight
18. **RadioManager.cs** — Auto-tune to WBCN on start
19. **DistrictTriggerBehaviour.cs** — Auto-create trigger volumes
20. **BuildingFactory.cs** — Ensure all 10 presets create valid geometry

### INIT ORDER (dependency-resolved)
```
1. ServiceLocator.Clear()
2. EmpireDatabaseManager (InitializeDatabase)
3. GameManager (SetState Playing)
4. TimeOfDayClock (SetTime 0, SetDay 1)
5. WeatherController (ForceState DenseFog)
6. PlayerWallet (SetBalance 0)
7. HeatManager (ClearHeat)
8. MissionManager (Awake → create 22 missions)
9. MissionDatabase (InitializeMissionManager)
10. PropertyDatabase (InitializeProperties)
11. SafehouseManager (unlock flour_mill)
12. RadioManager (SetStation WBCN_Rock)
13. CombatController (SyncAmmoToWeapon)
14. AudioBarkManager (cache listener)
15. SceneBuilder (BuildScene)
16. TerrainGenerator (GenerateTerrain)
17. RoadSystem (CreateRoads)
18. BuildingFactory (PlaceBuildings)
19. DistrictZoneBuilder (CreateDistrictZones)
20. NavMeshBuilder (BuildNavMesh)
21. DynamicSpawner (StartSpawning)
22. SpawnPointManager (PlacePlayer)
23. PropertyPlacement (PlaceMarkers)
24. SafehousePlacement (PlaceTriggers)
25. HUDManager (ShowHUD, wire events)
26. TutorialSystem (Queue first prompt)
```
