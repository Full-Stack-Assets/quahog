# QUAHOG Engine v4.0 — Full Implementation Plan
## All 6 reviewer-priority tiers

---

## Tier 1: Fix Save/Load Correctness (4 agents)
| Agent | File | Problem | Fix |
|-------|------|---------|-----|
| T1_SaveData | GameDataStructures.cs | JsonUtility can't serialize List<T> | Convert to arrays, add saveVersion |
| T1_SaveLoadMgr | SaveLoadManager.cs | No versioning, property not restored | Version check, property restore via EDM |
| T1_EDM | EmpireDatabaseManager.cs | propertyId "flour_mill" parsed as int=0 | Use TEXT primary key, add migration table |
| T1_Migrate | SaveLoadManager.cs | No schema migration | Add checksum, migration pipeline |

## Tier 2: Implement Critical Stubs (6 agents)
| Agent | File | Problem | Fix |
|-------|------|---------|-----|
| T2_Spawner | DynamicSpawner.cs | StartSpawning() is a log-only stub | Coroutine-based spawn loop with despawn |
| T2_Trigger | TriggerVolumeSetup.cs | 10 action types are TODO | Wire each to MissionManager/Safehouse/etc |
| T2_SceneBuilder | SceneBuilder.cs | Setters are no-ops | Wire to serialized fields + FindObjectOfType |
| T2_Combat | CombatController.cs | No ammo, reload, damage | Ammo count, reload coroutine, IDamageable |
| T2_Audio | AudioBarkManager.cs | SetCurrentRegion empty, ResolveClip stub | Cache region, weighted clip selection |
| T2_Mission | MissionManager.cs | UnlockPhaseMissions is stub | Phase-to-mission mapping |

## Tier 3: Hot-Path Performance (4 agents)
| Agent | File | Problem | Fix |
|-------|------|---------|-----|
| T3_Camera | All files (14) | Camera.main = FindObjectOfType every call | Cache in Awake, use cached ref |
| T3_FindObjects | World/AISystemWiring/etc | FindObjectsOfType per event | Registry pattern: PedestrianRegistry, VehicleRegistry |
| T3_DebugOverlay | DebugOverlay.cs | New GUIStyle/Texture2D per frame | Cache once in OnEnable |
| T3_Pool | DynamicSpawner + Factories | Instantiate/Destroy per spawn | ObjectPool<T> for NPCs and vehicles |

## Tier 4: Data-Drive Content (3 agents)
| Agent | File | Problem | Fix |
|-------|------|---------|-----|
| T4_MissionData | New: MissionDatabase SO | 22 missions hard-coded | ScriptableObject with all mission data |
| T4_PropertyData | New: PropertyDatabase SO | 5 properties hard-coded | ScriptableObject with property configs |
| T4_Presets | Vehicle/NPC Factories | Types/colors hard-coded | ScriptableObject preset assets |

## Tier 5: Unity Test Framework (2 agents)
| Agent | File | Problem | Fix |
|-------|------|---------|-----|
| T5_Tests | New: Tests/ folder | Play-mode tests mutate singletons | EditMode tests with [SetUp]/[TearDown] |
| T5_Mocks | New: MockManagers.cs | No way to test without full scene | Mock implementations for isolated testing |

## Tier 6: Architecture (3 agents)
| Agent | File | Problem | Fix |
|-------|------|---------|-----|
| T6_ServiceLocator | New: ServiceLocator.cs | 18 singletons, tight coupling | Typed service locator |
| T6_EventBus | New: EventBus.cs | 9 wiring MonoBehaviours | Typed EventBus<T> replacing wiring scripts |
| T6_Log | New: QLog.cs | 197 raw Debug.Log calls | Structured logging with channels/levels |
