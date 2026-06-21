# Mount Hope — Master Plan & Source of Truth

The one file to track everything. Update the **checklist** as work lands and append
to the **running log** every working session. Keep it honest: only check a box when
it's actually built, verified (build passes), and shipped.

- **Working title:** Mount Hope (retired “Project QUAHOG”)
- **Canonical engine:** `QUAHOG_Web/` — Three.js / React Three Fiber + Rapier (web; runs & deploys today). Unity/Godot = legacy reference (`ENGINES.md`).
- **Live:** https://projectsouthcoast.vercel.app  · branch `claude/determined-thompson-9jg8o1` → `main` (Vercel auto-deploy)
- **Photoreal experiment:** `QUAHOG_Web/earth.html` (Google 3D Tiles) — blocked on a billed Google key; parked.
- **Design canon:** `quahog-project-files/CHARACTERS_AND_MISSIONS.md`, `GEMINI_BUILD_PROMPT.md`, `ROADMAP.md`.
- **Hard external blocker:** AAA console release needs Sony/Microsoft registered-dev + devkits (a business/legal step, not buildable here).

Legend: `[x]` done & shipped · `[~]` partial/in progress · `[ ]` not started.

---

## 0. Foundations & ops
- [x] Repo + branch workflow; Vercel project + git auto-deploy (`projectsouthcoast`)
- [x] Engine reconciliation: R3F canonical; Unity/Godot marked legacy (`ENGINES.md`, `LEGACY.md`)
- [x] Game named **Mount Hope**
- [x] Design docs: README, ROADMAP, Characters & Missions bible, Gemini build spec
- [ ] CI: typecheck/build check on PRs
- [ ] Bundle code-splitting (main chunk >2 MB; split three/rapier/drei)
- [ ] Performance budget + FPS counter / stats overlay

## 1. World data & pipeline
- [x] OSM pull: New Bedford + Fall River (roads/water/rail/coastline/boundary)
- [x] Exports: GeoJSON, PMTiles, OBJ (`quahog-project-files/mapdata/`)
- [x] Slice blockout JSON for the web game (`slice-newbedford.json`): 1071 buildings, 808 roads, harbor water, landmarks
- [x] Pipeline scripts: `split_layers.py`, `bake_meshes.py`, `make_slice.py`
- [ ] Expand slice: full Fall River, Brockton, Cape Cod districts
- [ ] Building height data pass (real heights/levels where tagged)
- [ ] POI/landmark dataset beyond New Bedford (Battleship Cove, Lizzie Borden, St. Anne’s, etc.)

## 2. Rendering & environment (web game)
- [x] Real street grid rendered (roads + highways, textured)
- [x] Auto-extruded buildings (hull colliders near core, merged far mesh)
- [x] Harbor ocean (triangulated water)
- [x] Daytime sky + sun + fog
- [x] Procedural ground/road textures
- [x] Clouds + airliners (Ambient)
- [x] Hero landmark: Seamen’s Bethel (hand-modeled, collider)
- [~] Satellite ground via signed Google Static Maps serverless proxy (`api/staticmap.ts`) — code shipped; **needs `GOOGLE_MAPS_API_KEY` + `GOOGLE_MAPS_URL_SIGNING_SECRET` in Vercel + redeploy**, then verify/align
- [ ] Day/night cycle + dynamic weather cycle (clear/fog/rain/Nor’easter) in main game
- [ ] “Coastal Neon” dusk post-processing (bloom, wet reflections, neon signs)
- [ ] Lighthouse beam sweep (Palmer’s Island)
- [ ] More hand-detailed landmarks (Whaling Museum, Custom House, Battleship Cove, Lizzie Borden House, Braga Bridge)
- [ ] Higher-res / stitched satellite ground; precise alignment to OSM roads
- [ ] Performance: instanced buildings + instanced crowds, LOD, draw-call reduction

## 3. Characters & animation
- [x] Rigged human model (CesiumMan GLB) for player + pedestrians
- [ ] Tune model scale/orientation/feet alignment (`ModelCharacter` SCALE/FACE/Y_OFF)
- [ ] Animation states: idle / walk / run / enter-car / punch / hit-react / death
- [ ] Multiple distinct ped models (not all the same person); wardrobe variety
- [ ] Named character models (Vinny, allies, antagonists)
- [ ] Facial animation / lipsync for dialogue

## 4. Player & controls
- [x] Rapier character controller: walk/sprint, collision
- [x] Enter/exit + drive car (E)
- [x] Melee punch (F) → KO / kill
- [x] 1st/3rd-person toggle (V)
- [ ] Jump, crouch, cover, vault, swim
- [ ] Gunplay: aim, shoot, reload, cover-shoot, weapon wheel
- [ ] Gamepad support + remappable controls
- [ ] Mouse-look / pointer-lock aim mode

## 5. Vehicles
- [x] Real car models (Bronco/Mustang/Infiniti G/Nissan Z/RAV4) — player + traffic
- [x] Arcade driving (accel/brake/steer/reverse), enter/exit, collision
- [ ] Wheel rotation/steering animation, headlights at night, engine audio
- [ ] Damage model, region-accurate spawns (“Townie”, “Linguiça”, “Codfish 40”, lowriders)
- [ ] Motorcycles/mopeds, boats (smuggling), parking/garage

## 6. NPCs & living city
- [x] Wandering pedestrians (kinematic) with contact/knockback
- [x] Traffic following the real road network (turns at intersections)
- [x] Pedestrians react to melee (KO/kill, lie down)
- [ ] Ped AI states: flee, panic, react to weather/gunfire; crowd density by district
- [ ] Traffic: lanes, stops/signals, collision avoidance, react to player driving
- [ ] Faction NPCs + turf-based spawns (Azorean Syndicate, South End/Crioulo, Cape Set)
- [ ] Police NPCs + pursuit behavior

## 7. Gameplay systems (from canon)
- [ ] **MissionManager**: objective/trigger/state/reward engine
- [ ] **“Off the Boat”** opening mission (fish-pier ambush → fog getaway → safehouse)
- [ ] **Dual-axis Heat/Wanted**: Axis A police (1–5), Axis B faction aggro
- [ ] **Safehouses** (Maplecroft) — clear heat + save
- [ ] **PlayerWallet** + economy
- [ ] **AcquisitionEngine** (5 businesses) + property ownership
- [ ] **RevenueManager** (daily yields, margin-leak events)
- [ ] **ChopShopArmsManager** (weapons gated to Quequechan Mill #4 tier)
- [ ] **WeatherController** ↔ surface friction on vehicles
- [ ] **Dialect Engine** (non-rhotic NPC barks; Chip Worthington hard-Rs)
- [ ] Save/load (EmpireDatabaseManager → IndexedDB/localStorage) + autosave
- [ ] Full story arc: Act I (NB) → Act II (Fall River) → Act III (Cape + “Gloria”) → Battleship Cove finale
- [ ] Side threads: “Acquitted” (Borden), “The Undefeated” (boxing), races, smuggling, clam-shack runs

## 8. Audio
- [x] Radio: 4 stations (WHALE, The Rage, The Anvil, Maré Alta), TTS hosts, music, switching/mute
- [ ] Radio depth: longer scripts, ad reads, hosts react to story milestones
- [ ] SFX: footsteps, engine, punches/impacts, gulls, harbor ambience, weather
- [ ] Spatial audio + occlusion; adaptive music score under gameplay
- [ ] VO pipeline for NPC/mission dialogue (TTS now, recorded later)

## 9. UI / UX
- [x] Basic HUD (title, controls, mode)
- [ ] Minimap/radar (rotation, property icons, hostile blips, lighthouse sweeps)
- [ ] Health/armor, wanted badges, wallet, objective markers, interaction prompts
- [ ] Main menu (New/Continue/Load/Settings/Extras), pause menu
- [ ] Settings (graphics/audio/controls), accessibility (subtitles, colorblind, remap), photo mode

## 10. Tooling (“devkit”) & pipeline
- [x] OSM → game asset pipeline (data scripts)
- [x] GLTF asset import (characters); procedural world-gen
- [ ] In-browser world/mission editor: place markers, define triggers/objectives, free-cam, entity inspector
- [ ] Debug overlays (colliders, AI states, perf)
- [ ] Documented art/VO drop-in pipeline (commissioned models + recorded VO slots)

## 11. Districts / content expansion
- [x] New Bedford waterfront (primary)
- [ ] Fall River (Spindle City): Flint, Lizzie Borden, Battleship Cove, Braga Bridge
- [ ] Brockton (Champion City Gym, boxing)
- [ ] Cape Cod (marinas, Fake Kennedys)
- [ ] Fast-travel between districts; “Gloria” hurricane set-piece

## 12. Parked / external
- [~] Photoreal Google 3D Tiles build (`earth.html`) — full play world built; **blocked on billed Google key**; revisit if key resolved
- [ ] Native/console wrap — requires Sony/Microsoft dev program + devkits (external; not buildable here)

---

## Running log

### 2026-06-21
- Pulled OSM data for New Bedford + Fall River; produced GeoJSON/PMTiles/OBJ + MapLibre viewer; baked the web slice blockout (1071 buildings, 808 roads, harbor).
- Reconciled engines → **R3F canonical**; Unity (PR #18) + Godot marked legacy; ported StreetLife + car tuning into the web game.
- Confirmed canon vs Master Plan; locked **real names + original characters**; chose **New Bedford waterfront** opening slice.
- Built the web vertical slice: third-person walk + drivable car + Rapier collision on the real street grid; deployed to Vercel (`projectsouthcoast.vercel.app`) via git integration.
- Named the game **Mount Hope**; hand-modeled **Seamen’s Bethel**; spawn in front of it.
- Stylized-realism pass: harbor ocean, daytime sky, textured ground/roads, highways; expanded slice.
- Added **radio** (4 stations, TTS hosts, procedural music, switching/mute).
- Wrote **Characters & Missions bible** and the **Gemini build spec** (retargeted to AAA console+PC, all canon embedded).
- Photoreal **Google 3D Tiles** build (`earth.html`): full play world (player/car/NPCs/spawn picker/combat/view/weather/clouds/planes) + signing proxy — but **blocked by Google key billing/quota** (orbit + play blank). Parked.
- Pivoted to make the **stylized web game canonical** and fold in photoreal elements offline: **rigged human model** (player + peds), **radio**, and a **signed Static Maps serverless proxy** for satellite ground (needs Vercel env vars).
- Gameplay pass on the main game: **real car models** (player + traffic), **melee combat** (F → KO/kill), **1st/3rd-person toggle** (V), **clouds + planes**; HUD controls updated.
- Created this plan file as the source of truth.

<!-- Append new dated entries above this line as work lands. -->
