# Mount Hope — Master Plan & Source of Truth

The one file to track everything. Update the **checklist** as work lands and append
to the **running log** every working session. Keep it honest: only check a box when
it's actually built, verified (build passes), and shipped.

- **Working title:** Mount Hope (retired “Project QUAHOG”)
- **Canonical engine:** `QUAHOG_Web/` — Three.js / React Three Fiber + Rapier (web; runs & deploys today). Unity/Godot = legacy reference (`ENGINES.md`).
- **Live:** https://projectsouthcoast.vercel.app · branch `claude/determined-thompson-9jg8o1` → `main` (Vercel auto-deploy)
- **Photoreal experiment:** `QUAHOG_Web/earth.html` (Google 3D Tiles) — blocked on a billed Google key; parked.
- **Design canon:** `quahog-project-files/CHARACTERS_AND_MISSIONS.md`, `GEMINI_BUILD_PROMPT.md`, `ROADMAP.md`.
- **Hard external blocker:** AAA console release needs Sony/Microsoft registered-dev + devkits (a business/legal step, not buildable here).

Legend: `[x]` done & shipped · `[~]` partial/in progress · `[ ]` not started.
Everything below is scoped to be **achievable in the web engine** unless marked *(parked/external)*.

---

## 0. Foundations & ops
- [x] Repo + branch workflow; Vercel project + git auto-deploy (`projectsouthcoast`)
- [x] Engine reconciliation: R3F canonical; Unity/Godot marked legacy
- [x] Game named **Mount Hope**
- [x] Design docs: README, ROADMAP, Characters & Missions bible, Gemini build spec
- [ ] CI: typecheck/build check on PRs
- [ ] Bundle code-splitting (main chunk >2 MB; split three/rapier/drei; lazy-load earth page)
- [ ] Asset loading/preload screen + progress bar
- [ ] Error boundary + crash overlay on the main game (exists on earth page)
- [ ] Versioning / changelog; build stamp in-game (commit hash, build date)
- [ ] Analytics-free telemetry stub (FPS, load time) behind a debug flag

## 1. World data & pipeline
- [x] OSM pull: New Bedford + Fall River (roads/water/rail/coastline/boundary)
- [x] Exports: GeoJSON, PMTiles, OBJ (`quahog-project-files/mapdata/`)
- [x] Slice blockout JSON (1071 buildings, 808 roads, harbor water, landmarks)
- [x] Pipeline scripts: `split_layers.py`, `bake_meshes.py`, `make_slice.py`
- [ ] Expand slice: full Fall River, Brockton, Cape Cod
- [ ] Real building heights/levels where OSM-tagged; roof shapes
- [ ] POI/landmark dataset beyond New Bedford
- [ ] Land use layers (parks/grass, parking lots, beaches, water edges) for ground variety
- [ ] Sidewalk/curb extraction (separate ped surfaces from roadway)
- [ ] Railways, bridges, piers as distinct meshes
- [ ] Street-name + address data for signage/navigation

## 2. World rendering & environment
- [x] Real street grid (roads + highways, textured)
- [x] Auto-extruded buildings (hull colliders near core, merged far mesh)
- [x] Harbor ocean (triangulated water)
- [x] Daytime sky + sun + fog
- [x] Procedural ground/road textures
- [x] Clouds + airliners
- [x] Hero landmark: Seamen’s Bethel (modeled + collider)
- [~] Satellite ground via signed Static Maps proxy — needs Vercel env vars + verify/align
- [ ] Varied building façades (windows, doors, brick/clapboard/granite materials, storefronts, roof detail)
- [ ] Curbs, sidewalks, crosswalks, road markings, manholes, potholes
- [ ] Parks/grass/trees/foliage, planters, hedges
- [ ] Distant skyline / horizon backdrop + atmospheric haze
- [ ] Hand-detailed landmarks: Whaling Museum, Custom House, Double Bank, Battleship Cove, Lizzie Borden House, St. Anne’s, Braga/Verde Bridge, the mills
- [ ] Interiors for key buildings (chapel, bar, gym, safehouse)
- [ ] LOD + impostors for distant buildings

## 3. Aesthetics & art direction
- [ ] Define a **style guide** (palette, era 1986, materials, signage fonts, mood boards) in `quahog-project-files/`
- [ ] Time-of-day color grading (dawn/day/golden hour/dusk/night palettes)
- [ ] Filmic tone mapping (ACES) + exposure
- [ ] Post FX: bloom, SSAO/GTAO, vignette, subtle film grain, chromatic aberration, sharpen
- [ ] Depth of field (cinematic + photo mode), motion blur (camera + object)
- [ ] **“Coastal Neon” dusk**: glowing tavern/shop signs, wet-surface reflections, neon spill light
- [ ] Screen-space reflections / reflective wet roads
- [ ] God rays / volumetric light shafts through fog
- [ ] Color LUT system (swap grades per district/weather/mission)
- [ ] Material weathering: rust, grime, salt stains, peeling paint, moss on granite
- [ ] Decal system: stains, cracks, graffiti, posters, tire marks, blood (toggleable)
- [ ] Consistent PBR material library (asphalt, cobble, brick, granite, wood, metal, glass, water)

## 4. Lighting
- [ ] Day/night dynamic sun/moon + ambient changes
- [ ] Street lights (auto on at dusk), warm sodium glow
- [ ] Lit building windows at night (emissive, randomized)
- [ ] Neon/shop signs as light sources
- [ ] Vehicle headlights/taillights/brake lights as real lights
- [ ] Emergency lights (police) flashing
- [ ] **Palmer’s Island Lighthouse** rotating beam
- [ ] Light probes / baked GI for interiors; shadow cascades tuning
- [ ] Moon + star sky at night; sunrise/sunset gradients

## 5. Weather & VFX
- [ ] **WeatherController** state machine: Clear / Dense Fog / Coastal Rain / Nor’easter
- [ ] Rain particles + screen rain droplets + ripples/puddles
- [ ] Wet-surface shader blend (roads darken/shine when wet)
- [ ] Fog volumes (dense coastal fog), variable density
- [ ] Wind (sway on trees/flags/signs; blowing litter/leaves)
- [ ] Lightning + thunder (Nor’easter)
- [ ] Snow/sleet variant; splash particles in puddles
- [ ] Weather ↔ vehicle friction tie-in (slick cobbles, flooded docks)
- [ ] Smooth weather transitions + scheduler

## 6. Ocean & harbor
- [x] Static harbor water surface
- [ ] Animated waves (Gerstner) + foam at shoreline/piers
- [ ] Reflections + fresnel + depth-based color
- [ ] Boats bobbing; ferries; fishing vessels with wakes
- [ ] Buoys, nets, lobster traps, dock pilings
- [ ] Splashes when entering water; swim/drown logic
- [ ] Tide / “Gloria” flood level change

## 7. World props & set dressing
- [ ] Street furniture: lamp posts, benches, trash cans, hydrants, mailboxes, bus stops, phone booths (1986)
- [ ] Traffic lights + stop signs (functional + decorative)
- [ ] Power lines / utility poles, dumpsters, crates, pallets
- [ ] Storefront awnings, signage, A-frame signs, window displays
- [ ] Parked cars lining streets
- [ ] Harbor props: nets, traps, barrels, forklifts, shipping containers
- [ ] Vegetation: street trees, weeds in cracks, harbor grass
- [ ] Litter/newspapers/leaves (wind-driven), puddles
- [ ] Birds: gulls (flocking near harbor), pigeons; stray dogs/cats

## 8. Environmental storytelling
- [ ] Posters/flyers for the radio stations + fictional businesses
- [ ] Graffiti tags per faction/turf
- [ ] Murals (Portuguese/Cape Verdean South End, whaling heritage)
- [ ] Memorials/plaques at real landmarks (flavor text)
- [ ] Seasonal/feast banners (Feast of the Blessed Sacrament)
- [ ] Newspaper headlines that react to player rampages/missions

## 9. Characters & animation
- [x] Rigged human model (GLB) for player + pedestrians
- [ ] Tune model scale/orientation/feet alignment
- [ ] Anim states: idle, walk, run, sprint, enter/exit car, punch, hit-react, knockdown, death, aim, shoot
- [ ] Locomotion blendspace + foot IK on slopes/stairs
- [ ] Ragdoll on death/knockdown
- [ ] Multiple ped models + wardrobe/skin variety; gender mix
- [ ] Named character models (Vinny, allies, antagonists) + portraits
- [ ] Facial animation / lipsync for cutscenes & dialogue
- [ ] Player outfit changes; wet/dirty clothing states

## 10. Player & controls
- [x] Rapier character controller: walk/sprint, collision
- [x] Enter/exit + drive car (E)
- [x] Melee punch (F) → KO/kill
- [x] 1st/3rd-person toggle (V)
- [ ] Jump, crouch, sprint stamina, cover, vault, climb, swim
- [ ] Mouse-look / pointer-lock aim; gamepad support; remappable controls
- [ ] Interaction system (prompts: enter, talk, pick up, sit, sleep)
- [ ] Inventory + weapon wheel
- [ ] Footstep surface detection (cobble/asphalt/wood/grass/water)

## 11. Combat & weapons
- [x] Melee punch → KO/kill + knockback
- [ ] Melee combo / block / grapple; lock-on
- [ ] Gunplay: aiming, hitscan/projectile, reticle, cover-shoot, recoil
- [ ] Weapon set: fists, bat, pistol, shotgun, SMG, “heavy” (Quequechan Mill tier)
- [ ] Ammo, reload, pickups, weapon switching
- [ ] Damage model + health/armor + regen/medkits
- [ ] Hit reactions, ragdolls, blood decals (toggleable), impact particles
- [ ] Enemy combat AI (cops, faction enforcers): chase, shoot, take cover, flank

## 12. Vehicles
- [x] Real car models (Bronco/Mustang/G/Z/RAV4) — player + traffic
- [x] Arcade driving (accel/brake/steer/reverse), enter/exit, collision
- [ ] Wheel rotation + steering animation; suspension travel
- [ ] Working lights (head/tail/brake/reverse/turn signals)
- [ ] Damage/deformation, smoke when wrecked, explosions
- [ ] Region-accurate spawns (“Townie”, “Linguiça” moped, “Codfish 40”, lowriders, preppy imports)
- [ ] Motorcycles/mopeds, boats, bicycles
- [ ] Garage / car storage / customization (paint, wheels)
- [ ] Car radio audible inside; horn

## 13. Driving feel & vehicle FX
- [ ] Tire skid marks (decals) + skid/screech audio
- [ ] Tire smoke, dust on dirt, water spray in rain/puddles
- [ ] Camera FOV/shake scaling with speed; speed lines
- [ ] Engine audio with RPM/gears; backfire
- [ ] Collision crunch sfx + sparks; ragdoll peds on impact
- [ ] Handbrake, drift, boost feel tuning

## 14. NPCs & living city
- [x] Wandering pedestrians (kinematic) + contact/knockback
- [x] Traffic following the real road network (turns at intersections)
- [x] Peds react to melee (KO/kill, lie down)
- [ ] Ped AI states: idle/converse/walk/flee/panic/cower; weather reactions (umbrellas)
- [ ] Ped density + variety by district + time of day; crowds
- [ ] Traffic: lanes, stop at lights, yield, collision avoidance, honking, react to player
- [ ] Faction NPCs + turf spawns (Azorean Syndicate, South End/Crioulo, Cape Set, Provençal)
- [ ] Police NPCs + pursuit + backup escalation
- [ ] NPC daily schedules / spawn zones
- [ ] Performance: instanced/pooled crowds + LOD

## 15. Gameplay systems (canon)
- [ ] **MissionManager**: objective/trigger/state/reward engine + markers + waypoints
- [ ] **Dual-axis Heat/Wanted**: Axis A police (1–5), Axis B faction aggro; decay; busted/wasted states
- [ ] **Safehouses** (Maplecroft) — clear heat + save + sleep/time-skip
- [ ] **PlayerWallet** + currency UI
- [ ] **AcquisitionEngine** (5 businesses) + property ownership/markers
- [ ] **RevenueManager** (daily yields, margin-leak events)
- [ ] **ChopShopArmsManager** (weapons gated to Quequechan Mill #4 tier)
- [ ] **WeatherController** ↔ vehicle friction
- [ ] **Dialect Engine** (non-rhotic barks; Chip Worthington hard-Rs)
- [ ] **RadioManager** integration with story milestones
- [ ] Save/load (IndexedDB/localStorage) + autosave + multiple slots
- [ ] Time of day clock + day counter; time-skip
- [ ] Respect/reputation + faction standing

## 16. Missions & content
- [ ] **“Off the Boat”** opener (arrival → Bethel → fish-pier ambush → fog getaway → safehouse)
- [ ] Mission framework primitives: go-to, follow, deliver, chase, escape, eliminate, protect, steal, tail, timed, stealth
- [ ] Cutscene system (scripted camera + dialogue + subtitles)
- [ ] Act I (New Bedford): harbor takeover arc
- [ ] Act II (Fall River): “Acquitted” (Borden) + “The Undefeated” (boxing)
- [ ] Act III (Cape + “Gloria” storm) → Battleship Cove finale
- [ ] Branching/optional outcomes; mission replay
- [ ] Dialogue system (NPC conversations, choices where relevant)

## 17. Progression & economy
- [ ] Cash earning/spending loops (missions, businesses, side jobs, theft)
- [ ] Property empire with upkeep + income tick
- [ ] Player upgrades/skills (driving, shooting, health, stamina)
- [ ] Shops: weapons, clothing, vehicle mods, food (health)
- [ ] Bank/stash; bribes; fines

## 18. Side activities & minigames
- [ ] Street races (bridge circuits, checkpoints, timers)
- [ ] Boxing circuit (Champion City Gym)
- [ ] Boat smuggling runs (Coast Guard heat)
- [ ] Clam-shack delivery time-trials
- [ ] Vigilante/taxi/“rampage” style diversions
- [ ] Collectibles (e.g., hidden whaling artifacts/landmarks photo-ops)
- [ ] Lizzie Borden ghost-tour caper

## 19. Audio & music
- [x] Radio: 4 stations (WHALE, The Rage, The Anvil, Maré Alta) — TTS hosts, music, switching/mute
- [ ] Radio depth: longer scripts, ad reads, weather/news, hosts react to milestones
- [ ] More stations + larger procedural/licensed-free music sets
- [ ] VO pipeline for NPC/mission dialogue (TTS now, recorded later)
- [ ] Mission/score adaptive music layers (calm/tension/chase)

## 20. Audio aesthetics & ambience
- [ ] Per-district ambient beds (harbor gulls/waves, mill hum, downtown traffic, Cape calm)
- [ ] Time-of-day ambience (dawn birds, night crickets/quiet)
- [ ] Weather audio (rain, wind, thunder, foghorn)
- [ ] SFX: footsteps by surface, doors, punches/impacts, gunfire, glass, car crunch, horns
- [ ] 3D spatialization + reverb zones (alleys, interiors, under bridges) + occlusion
- [ ] Doppler on passing vehicles; distance attenuation
- [ ] UI sfx (menu, mission start/complete, cash, wanted-up)

## 21. UI / UX
- [x] Basic HUD (title, controls, mode)
- [ ] Minimap/radar (rotation, streets, property icons, hostile blips, lighthouse sweep, objective)
- [ ] Health/armor, stamina, wanted badges (police + faction), wallet, ammo, weapon
- [ ] Objective markers + waypoints + on-screen distance
- [ ] Interaction prompts + context hints
- [ ] Big map screen (set waypoint, fast-travel, legend)
- [ ] Subtitles + dialogue UI + phone/contacts
- [ ] Notifications (mission, cash, busted/wasted), damage vignette + directional hit indicators

## 22. UI aesthetics & menus
- [ ] **1986 retro UI** theme (fonts, colors, CRT/neon styling) — consistent kit
- [ ] Main menu (New/Continue/Load/Settings/Extras) with art + ambient scene
- [ ] Pause menu, mission screen, stats/progress screen
- [ ] Loading screens with art + tips/lore
- [ ] Map/HUD icon set; mission-text styling; credits
- [ ] Photo-mode UI (filters, frames, stickers)

## 23. Game feel / juice
- [ ] Camera shake (impacts, explosions, engine, gunfire)
- [ ] Hit-stop / time-dilation on big hits; slow-mo finishers (optional)
- [ ] Impact particles (sparks, dust, debris, blood toggle), screen-space hit FX
- [ ] Controller rumble / gamepad haptics
- [ ] Damage/low-health screen FX (desaturate, pulse, blur)
- [ ] Pickup/cash pop FX + sound; wanted-up sting
- [ ] Foot dust, splash, footstep decals

## 24. Camera
- [x] Third-person chase + first-person toggle
- [ ] Collision-aware camera (no clipping through walls); auto-occlusion fade
- [ ] Aim/over-the-shoulder camera; lock-on framing
- [ ] Cinematic/cutscene camera rig; mission intro fly-bys
- [ ] Photo mode free-cam (already exists on earth page — port + expand)
- [ ] Smoothing, FOV options, motion-sickness comfort settings

## 25. Accessibility
- [ ] Subtitles + size/background options
- [ ] Full control remap; gamepad + KB/M
- [ ] Colorblind modes; UI scale; high-contrast
- [ ] Aim assist; difficulty options; hold-vs-toggle
- [ ] Reduce-motion / camera-shake toggle; flashing-lights warning

## 26. Save / settings / onboarding
- [ ] Save/load UI + autosave + slots + cloud-ready format
- [ ] Settings: graphics presets + toggles (shadows, post FX, draw distance), audio mix, controls
- [ ] First-time tutorial / control onboarding (the opener doubles as this)
- [ ] Resume/“continue” flow; new-game-plus (stretch)

## 27. Tooling (“devkit”) & pipeline
- [x] OSM → game asset pipeline (data scripts)
- [x] GLTF asset import (characters); procedural world-gen
- [ ] In-browser world/mission editor: place markers, define triggers/objectives, free-cam, entity inspector, save to JSON
- [ ] Debug overlays (colliders, AI states, nav, FPS/stats, spawn tools, teleport)
- [ ] Hot-reload content data (missions/props from JSON)
- [ ] Documented art/VO drop-in pipeline (commissioned models + recorded VO slots)
- [ ] Asset budget/validation tooling (poly/texture/memory)

## 28. Districts / content expansion
- [x] New Bedford waterfront (primary)
- [ ] New Bedford full (downtown, South End, North End)
- [ ] Fall River (Spindle City): Flint, Lizzie Borden, Battleship Cove, Braga Bridge, mills
- [ ] Brockton (Champion City Gym, boxing)
- [ ] Cape Cod (marinas, Fake Kennedys)
- [ ] Connecting roads/highways between districts; fast-travel
- [ ] “Gloria” hurricane set-piece (flood, map alteration, sunk boats)

## 29. Performance & optimization
- [ ] Instanced rendering (buildings, props, crowds, traffic)
- [ ] LOD + frustum/occlusion culling; impostors for far buildings
- [ ] Object pooling (peds, cars, particles, decals)
- [ ] Texture atlasing + compression; geometry merging
- [ ] Frame budget profiling; fixed-timestep physics; web worker offload where possible
- [ ] Quality presets + dynamic resolution; mobile/low-end fallback
- [ ] Bundle split + lazy loading; asset streaming by district

## 30. QA / testing / release
- [ ] Smoke-test checklist per build (load, walk, drive, combat, radio, save)
- [ ] Automated typecheck/build gate
- [ ] Cross-browser + perf testing; input device testing
- [ ] Bug tracker / known-issues list
- [ ] Release notes + in-game version stamp
- [ ] Legal/attribution page (OSM ODbL, model licenses, parody disclaimer)

## 31. Parked / external
- [~] Photoreal Google 3D Tiles build (`earth.html`) — full play world built; **blocked on billed Google key**; revisit if resolved
- [ ] *(external)* Native/console wrap — Sony/Microsoft dev program + devkits (business/legal, not buildable here)
- [ ] *(stretch)* Desktop wrap (Tauri/Electron) for an installable PC build of the web game
- [ ] *(stretch)* Multiplayer / co-op

---

## Running log

### 2026-06-21
- Pulled OSM data (New Bedford + Fall River); produced GeoJSON/PMTiles/OBJ + MapLibre viewer; baked the web slice blockout (1071 buildings, 808 roads, harbor).
- Reconciled engines → **R3F canonical**; Unity (PR #18) + Godot legacy; ported StreetLife + car tuning.
- Locked **real names + original characters**; chose **New Bedford waterfront** opener.
- Built the web vertical slice: third-person walk + drivable car + Rapier collision on the real grid; deployed to Vercel via git integration.
- Named the game **Mount Hope**; modeled **Seamen’s Bethel**; spawn in front of it.
- Stylized-realism pass: harbor ocean, daytime sky, textured ground/roads, highways; expanded slice.
- Added **radio** (4 stations, TTS hosts, procedural music, switching/mute).
- Wrote **Characters & Missions bible** and the **Gemini build spec** (AAA console+PC framing, all canon).
- Photoreal **Google 3D Tiles** build (`earth.html`) with full play world + signing proxy — **blocked by Google billing/quota**; parked.
- Pivoted to make the **stylized web game canonical**; folded in **rigged human model**, **radio**, and a **signed Static Maps proxy** for satellite ground (needs Vercel env vars).
- Gameplay pass: **real car models** (player + traffic), **melee combat** (F → KO/kill), **1st/3rd-person toggle** (V), **clouds + planes**; HUD controls updated.
- Created `plans/mount-hope.md` as source of truth, then **expanded it** into a full essential-systems + aesthetics/art-direction/game-feel checklist (this revision).

<!-- Append new dated entries above this line as work lands. -->
