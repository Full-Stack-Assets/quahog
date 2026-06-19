# QUAHOG Engine — Compile Blocker Fix Plan

## Category 1: Duplicate Type Definitions
| Type | Locations | Fix |
|------|-----------|-----|
| IInteractable | GameInterfaces.cs, UI/IInteractable.cs, AssetProperty.cs (3 different signatures!) | Unify to single canonical interface in GameInterfaces.cs: void OnInteract(), string GetInteractPrompt(). Fix AssetProperty.cs + delete UI/IInteractable.cs |
| AssetPropertyData | AssetProperty.cs (canonical), EmpireDatabaseManager.cs (different shape) | Make EDM use AssetPropertyData shape; keep canonical in AssetProperty.cs |
| SaveData | GameDataStructures.cs (canonical), SaveLoadManager.cs (different shape) | Remove from SaveLoadManager, use GameDataStructures version |

## Category 2: SaveLoadManager References Non-Existent Classes
| Fake Reference | Actual Class | Fix |
|----------------|-------------|-----|
| WalletManager | PlayerWallet | Replace all refs |
| PropertyManager | RevenueManager + direct property list | Replace with RevenueManager.Instance |
| TimeManager | TimeOfDayClock | Replace all refs |
| MissionManager.CompletedMissionIds | MissionManager.Missions list | Query from Missions list |
| MissionManager.ActiveMissionIds | MissionManager.Missions list | Query from Missions list |
| MissionManager.LoadMissions | Add method to MissionManager | Implement LoadMissions() |
| HeatManager.CurrentHeat | HeatManager.WantedLevel | Use WantedLevel + faction aggro |
| HeatManager.SetHeat | Add method | Implement SetHeat() |

## Category 3: Missing APIs (Add to existing classes)
| Class | Missing API | Add |
|-------|-------------|-----|
| AcquisitionEngine | event OnAcquisitionSuccess | Add event, fire on successful purchase |
| Mission | WorldTarget, RewardAmount, ControlPromptId | Add fields |
| MissionManager | UnlockPhaseMissions, CompletedMissionIds, ActiveMissionIds, LoadMissions | Add properties + method |
| WeatherController | ApplyPhaseWeather | Add method |
| CutsceneManager | PlayPhaseTransition | Add method |
| HealthArmorDisplay | RestoreHealthAndArmor() | Add method |
| HUDManager | UpdateRadarBlips() | Add method |
| RadarBlipSystem | UpdatePoliceBlips(int) | Add method |
| DebugOverlay | OnForceWeather, OnForceTime, OnClearHeat, OnAddMoney, OnRunValidationRequested, OnRunTestsRequested | Add events |
| DistrictTriggerBehaviour | Fix OnDistrictEntered signature | Should be Action<string> (just district name) |
| DynamicSpawner | SetRegionProfile(RegionProfile) | Add method |
| AudioBarkManager | SetCurrentRegion(RegionProfile) | Add method |
| NavMeshFloodModifier | CarveFloodArea() no-arg overload | Add overload that uses default bounds |
| SafehouseManager | OnSafehouseEntered event type | Should be Action (no-arg) for wiring compat |

## Category 4: Wiring Script Fixes
| File | Issues |
|------|--------|
| EconomySystemWiring | _onDailyYieldHandler type wrong (int vs float); OnAcquisitionSuccess event missing |
| MissionSystemWiring | References non-existent Mission fields + manager methods |
| UISystemWiring | Wrong event signatures, non-existent methods |
| CombatSystemWiring | OnFired signature mismatch, faction wiring type mismatch |
| AudioSystemWiring | RadioStationWidget.SetStation signature mismatch, weather enum mismatch |
| EventSystemWiring | NavMeshFloodModifier.CarveFloodArea signature mismatch |
| DebugSystemWiring | DebugOverlay events don't exist |
| LevelSystemWiring | Methods don't exist on target classes |
| AISystemWiring | Methods don't exist on target classes |

## Category 5: Enum Duplication
| Enum | GameEnums.cs | Nested In | Fix |
|------|-------------|-----------|-----|
| WeatherState | top-level | WeatherController | Delete GameEnums.cs, keep all nested |
| MissionState | top-level | MissionManager | Delete GameEnums.cs |
| VehicleType | top-level | VehiclePrefabFactory | Delete GameEnums.cs |
| NPCType | top-level | NPCPrefabFactory | Delete GameEnums.cs |
| WeaponType | top-level | CombatController | Delete GameEnums.cs |
| GameState | top-level | GameManager | Delete GameEnums.cs |

### GameDataStructures.cs references MissionManager.MissionState — need to fix after deleting GameEnums.cs

## Category 6: TODO Stubs
| File | TODOs |
|------|-------|
| TriggerVolumeSetup | Switch cases are empty/TODO — fill with actual calls |
| CombatController | TODO stubs for damage, reload anim | Fill basic implementations |
