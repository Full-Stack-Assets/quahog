# WebGL → Unreal Porting Analysis (`QUAHOG_Web` → `MountHope_Unreal`)

> **Status:** Analysis / planning document. This branch (`port/webgl-to-unreal-analysis`)
> is **not intended to be merged** — it exists to capture the feature-parity gap
> between the canonical Web build and the Unreal port and to give an actionable,
> prioritised port order.
>
> **Canonical reference:** `QUAHOG_Web` (Three.js / React-Three-Fiber + Rapier)
> is the source of truth for game feel and content. Unreal should reach parity on
> **mechanics, systems, content and UX** — **not** on the stylised low-poly / blocky
> "blockout" art. Blocky procedural geometry (OSM-extruded buildings, box props,
> flat-shaded meshes) is explicitly **out of scope**; Unreal keeps its own art
> pipeline (Nanite/Lumen, authored or Marketplace assets).

---

## 1. Method

Parity was assessed by comparing:

- **Web systems** — `QUAHOG_Web/src/**` (game logic in `*.ts`, world systems and
  actors in `*.tsx`).
- **Unreal systems** — `MountHope_Unreal/Source/**` C++ subsystems/actors
  (`MH*Subsystem`, `MH*Actor`, `MH*Pawn`, `MH*Character`).
- Existing planning docs: `plans/mount-hope.md`, `plans/web-godot-parity-checklist.md`,
  `MountHope_Unreal/Docs/IMPROVEMENT_PLAN.md`, `MountHope_Unreal/Docs/VERTICAL_SLICE.md`.

Each Web feature is bucketed: **✅ Present** in Unreal, **◑ Partial**, or **❌ Missing**.

---

## 2. Parity matrix

### Systems already scaffolded in Unreal (parity or near-parity)

| Web feature | Web source | Unreal counterpart | State |
|---|---|---|---|
| Core stats (cash / health / dual-axis heat) | `game.ts` | `MHGameStateSubsystem`, `MHWantedSubsystem` | ✅ |
| Property/business economy (passive income) | `economy.ts` | `MHEconomySubsystem` | ✅ |
| Mission chain (11-mission canonical campaign) | `mission.ts`, `world/MissionRunner.tsx` | `MHMissionSubsystem`, `MHMissionTriggerActor` | ✅ |
| Police / wanted pursuit | `world/Police.tsx` | `MHWantedSubsystem`, `MHPoliceSpawnerActor`, `MHPoliceUnitPawn` | ✅ |
| Pedestrians (wander / flee) | `world/StreetLife.tsx` | `MHPedestrianCharacter`, `MHPedestrianSpawnerActor` | ✅ |
| Scrimshaw collectibles (×8) | `world/Collectibles.tsx` | `MHCollectibleSubsystem`, `MHCollectibleActor` | ✅ |
| Health pickups | `world/HealthPickups.tsx` | `MHHealthPickupActor` | ✅ |
| Safehouse (lie-low / save point) | `world/Safehouse.tsx` | `MHSafehouseActor` | ✅ |
| Shop / buy interactions | `world/Businesses.tsx` | `MHShopActor` | ✅ |
| Dialogue | (VO + `mission` beats) | `MHDialogueSubsystem`, `MHDialogueNpcActor` | ✅ |
| Reputation | (heat/faction flavour) | `MHReputationSubsystem` | ✅ |
| Time-of-day cycle | `world/DayNight.tsx` | `MHTimeOfDaySubsystem` | ✅ |
| Weather (clear/rain) | `world/Rain.tsx`, `store.ts` | `MHWeatherDirectorActor` | ◑ (visual only; see 3.7) |
| Car vehicle + damage | `actors/Car.tsx` | `MHVehiclePawn` | ✅ |
| World slice loading (New Bedford) | `slice.ts` | `MHWorldSliceSubsystem`, `MHOpenWorldSubsystem` | ✅ |
| HUD / minimap | `HUD.tsx`, `Minimap.tsx` | `MHGameHudWidget`, `MHMinimapCaptureActor` | ✅ |
| Save / load | `game.ts`, `world/GameSystems.tsx` | `MHSaveSubsystem`, `MHSaveGame` | ✅ |
| Radio stations (data) | `audio/radioEngine.ts` | `MHRadioSubsystem` | ◑ (audio bind is an editor step) |

### Web features MISSING or thinner in Unreal (the actual port backlog)

| # | Web feature | Web source | Gap in Unreal | Priority |
|---|---|---|---|---|
| G1 | **Pilotable boat** (mode switch foot/car/**boat**, harbour navigation, moored spawn) | `actors/Boat.tsx`, `store.ts` (`Mode = "foot"\|"car"\|"boat"`), `economy.ts` (`BOAT_SPAWN`) | No boat pawn — only `MHVehiclePawn` (car). No third locomotion mode. | **P0** |
| G2 | **Street races** (start pad, ordered checkpoints, clock, reward, best-time) | `race.ts`, `world/Race.tsx` | No race subsystem/actors at all. | **P0** |
| G3 | **Weapon variety** (pistol **+ shotgun**, melee fists **+ bat**) | `store.ts` (`Weapon`, `Melee`), `actors/Player.tsx` | Single-weapon combat; `MHWeaponPickupActor` exists but no shotgun / melee-bat variety or weapon-switch UI. | **P0** |
| G4 | **Revenue boom/leak events** (one-off windfalls & losses on owned fronts) | `economy.ts` (`rollRevenueEvent`, BOOM/LEAK pools) | `MHEconomySubsystem` has passive trickle only — no event roller / toast. | **P1** |
| G5 | **Traffic carjack** (steal an in-traffic car; car removed from traffic when stolen) | `shared.ts` (`TrafficCar.stolen`), `world/StreetLife.tsx` | Traffic simulation is thinner; no carjack-from-traffic path. | **P1** |
| G6 | **Near-miss cash bonus** (reward for high-speed close passes) | `world/StreetLife.tsx` / `world/GameSystems.tsx` | No near-miss scoring. | **P1** |
| G7 | **Big map + fast-travel + waypoints** (full-screen map, place waypoint, travel) | `ui/BigMap.tsx`, `store.ts` (`waypoint`, `mapOpen`) | Only a live minimap; no full map, no waypoint placement, no fast-travel. | **P1** |
| G8 | **Character / vehicle customization** (player tint, car type + colour) | `ui/CharacterMenu.tsx`, `store.ts` (`playerTint`, `playerCarType`, `playerCarColor`) | No customization menu or persisted appearance. | **P2** |
| G9 | **Wet-road handling + skid marks** (rain lowers friction; hard cornering lays marks) | `world/SkidMarks.tsx`, `actors/Car.tsx`, `shared.ts` (`skid`) | Weather is visual only; vehicle friction not weather-coupled; no skid decals. | **P2** |
| G10 | **Photo mode** (freeze + framing) | `store.ts` (`photo`, `togglePhoto`) | Not present. | **P2** |
| G11 | **Radio DJ banter binding** (VO barks tied to stations) | `audio/vo.ts`, `audio/radioEngine.ts` | `MHRadioSubsystem` is data-only; DJ VO/banter not wired. | **P2** (editor/audio step) |
| G12 | **Consequence / hazards feedback layer** (busted/wasted flow, hazards) | `world/Consequence.tsx`, `world/Hazards.tsx`, `store.ts` (`Down`) | `Down` state ("busted"/"wasted") flow and hazard reactions are thinner. | **P2** |
| G13 | **Camera-shake / juice & reduce-shake option** | `shared.ts` (`addShake`), `store.ts` (`reduceShake`) | Accessibility toggle + shake juice not ported. | **P3** |
| G14 | **Toast notifications** (transient gameplay feedback) | `store.ts` (`useToasts`) | No lightweight toast channel on the HUD. | **P3** |

### Explicitly **out of scope** (do not port)

- **Blockout art / procedural OSM geometry** — `world/Buildings.tsx`,
  `StreamingBuildings.tsx`, `AreaTrees.tsx`, `Foliage.tsx`, `Billboards.tsx`,
  `NeonSigns.tsx`, `Graffiti.tsx`, `Decals.tsx`, `Posters.tsx`, `Props.tsx`,
  `Awnings.tsx`, `UtilityPoles.tsx`, `Fences.tsx`, `Steeples.tsx`,
  `Crosswalks.tsx`, `RoadFixtures.tsx`, `StreetSigns.tsx`, etc. Unreal uses its own
  art pipeline; only the **placement data / gameplay collision** semantics matter,
  not the low-poly meshes.
- **Aerial/satellite photoreal build** (`earth.html`, `src/earth/**`, `api/staticmap.ts`,
  Google 3D Tiles) — a web-only rendering path; not a gameplay feature to port.
- **Touch controls** (`ui/TouchControls.tsx`) — mobile-web input; N/A on PC/console
  (use Enhanced Input gamepad/KBM instead).

---

## 3. Porting notes per gap

### 3.1 Boat (G1) — P0
- Web models three locomotion modes (`Mode = "foot" | "car" | "boat"`); the boat is
  moored near the Long Island marina (`BOAT_SPAWN = [6130, 0.6, 4520]`).
- Unreal: add an `MHBoatPawn` (buoyancy/floating movement over the water plane),
  register it with the same enter/exit interaction path as `MHVehiclePawn`, and add
  a "boat" locomotion state to the player controller. Reuse `MHWorldSliceSubsystem`
  water zones for navigable area.
- Coordinate mapping (Web/Godot → Unreal): `(X, 0, -Z_web) → (X, 0, Z_unreal)` — see §4.

### 3.2 Street races (G2) — P0
- Port `race.ts` verbatim as a subsystem (`MHRaceSubsystem`): `RACE_START`,
  ordered `CHECKPOINTS`, `active/idx/time/best`, `start/hit/tick/cancel`, `REWARD`.
- Add checkpoint trigger actors + a start pad; drive `tick` from the world timer and
  award cash via `MHEconomySubsystem`/`MHGameStateSubsystem` on completion.
- The Web logic is small and fully unit-testable — mirror the test cases added in the
  Web `review/test-coverage` PR (`src/__tests__/race.test.ts`).

### 3.3 Weapon variety (G3) — P0
- Web: `Weapon = "pistol" | "shotgun"`, `Melee = "fists" | "bat"`, with draw/switch
  in `store.ts` (`setWeapon`, `setMelee`, `toggleArmed`).
- Unreal: extend the weapon component with a shotgun (spread trace) and a melee bat
  (arc hit), plus weapon-switch input and HUD indicator. `MHWeaponPickupActor` can
  drop the additional types.

### 3.4 Revenue events (G4) — P1
- Port `rollRevenueEvent` (BOOM/LEAK flavour pools; amount scaled to `perDay`).
- Drive from a periodic timer once the player owns ≥1 front (Web fires the first
  after ~75 s of ownership — see `GameSystems.tsx`), surface via a HUD toast (G14).

### 3.5 Traffic carjack (G5) & 3.6 Near-miss (G6) — P1
- Carjack: allow the enter-vehicle interaction to target a *traffic* car, then remove
  that car from the traffic pool (mirror `TrafficCar.stolen`).
- Near-miss: detect high-relative-speed close passes to traffic/peds and award a small
  cash bonus + toast (Web does this in the street-life/systems update loop).

### 3.7 Weather-coupled handling + skid marks (G9) — P2
- `MHWeatherDirectorActor` currently changes visuals only. Couple rain → reduced tyre
  friction on `MHVehiclePawn`, and spawn skid-mark decals when cornering hard at speed
  (Web sets `shared.skid` and renders `SkidMarks.tsx`).

### 3.8 Map & fast-travel (G7), customization (G8), photo mode (G10)
- These are UMG/UI-driven; build as widgets backed by the existing subsystems.
  Persist customization + waypoint through `MHSaveSubsystem`.

---

## 4. Coordinate & data conventions

- **Web slice space:** 2D points are `[east, north]` metres; 3D maps `east → +x`,
  `north → -z`, `up → +y` (`slice.ts` `toWorld`).
- **Web/Godot → Unreal:** `(GodotX, 0, -GodotZ) → (UnrealX, 0, UnrealZ)` (per
  `plans/mount-hope.md`). Validate against the shared `slice-newbedford.json` the
  Unreal `MHWorldSliceSubsystem` already loads so world anchors (mission targets,
  business fronts, collectible spots, race checkpoints) line up across builds.
- Reuse the canonical numeric content directly (mission targets in `mission.ts`,
  business fronts in `economy.ts`, checkpoints in `race.ts`, collectible spots in
  `Collectibles.tsx`) so both builds stay data-identical.

---

## 5. Recommended port order

1. **P0 gameplay-completing systems:** Street races (G2) → Weapon variety (G3) →
   Boat (G1). These are the mechanics a player most notices missing versus the Web build.
2. **P1 economy & traffic depth:** Revenue events (G4), Carjack (G5), Near-miss (G6),
   Big map + fast-travel + waypoints (G7).
3. **P2 polish & UX:** Wet-road handling + skid marks (G9), Character/vehicle
   customization (G8), Photo mode (G10), Consequence/hazards depth (G12),
   Radio DJ banter binding (G11).
4. **P3 juice/accessibility:** Camera shake + reduce-shake (G13), HUD toasts (G14).

Port the small, pure-logic systems (race, revenue events) by translating the Web
`*.ts` almost line-for-line into subsystems and carrying over their unit tests; port
the actor/interaction systems (boat, carjack, weapons) as `MH*` classes wired through
the existing controller/interaction framework.
