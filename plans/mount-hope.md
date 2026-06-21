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

## Working loop (how this plan gets executed)

Repeat this loop every working cycle. One task (or one small coherent batch) at a
time; keep the build green; be honest about status.

1. **READ** — open this file. Skim the checklist + the latest running-log entry.
   Pick the **next task**: highest-priority unchecked `[ ]` (or resume a `[~]`),
   respecting dependencies and any current user-chosen focus. Prefer order:
   foundations → core systems → content → aesthetics/polish, unless redirected.
2. **SCOPE** — restate the task + its acceptance criteria (use the task's intricate
   spec/sub-bullets as the definition of done). Mark it `[~]` in the checklist.
3. **BUILD** — implement it in `QUAHOG_Web/` (code) or `quahog-project-files/` /
   `plans/` (data/docs). Keep changes focused on the task.
4. **VERIFY** — run `npm run build` (tsc + vite) until clean. Sanity-check
   behavior/intent. If shippable, deploy (push → Vercel) and confirm the
   deployment is **READY**. Note: WebGL visuals can't be eyeballed here, so verify
   build + logic and flag anything needing the user's eyes.
5. **REVIEW** — self-review against the task's spec; check for regressions; confirm
   no console/type errors. If only partly done, keep it `[~]` and note what's left.
6. **CHECK OFF** — set the box to `[x]` (done & shipped) or `[~]` (partial).
   Append a dated bullet to the **running log**: what changed + commit hash +
   any blocker/follow-up.
7. **COMMIT & PUSH** — commit on the feature branch, fast-forward `main`, push
   (Vercel auto-deploys). Update task counts if helpful.
8. **REPEAT** — go to step 1.

**Rules of the loop**
- Never leave the build broken between cycles.
- Don't check a box until it's actually built + verified + shipped.
- Record blockers explicitly (e.g., needs a key/asset/user decision) and skip to
  the next unblocked task rather than stalling.
- Batch only tightly-related tasks; otherwise one at a time for clean history.
- The user can interrupt to re-prioritize at any point; honor it, then resume the loop.

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
- [x] Filmic tone mapping (ACES) + exposure
- [~] Post FX: bloom, SSAO/GTAO, vignette, subtle film grain, chromatic aberration, sharpen — bloom + vignette + SMAA live (Effects.tsx); SSAO/grain/CA/sharpen TODO
- [ ] Depth of field (cinematic + photo mode), motion blur (camera + object)
- [ ] **“Coastal Neon” dusk**: glowing tavern/shop signs, wet-surface reflections, neon spill light
- [ ] Screen-space reflections / reflective wet roads
- [ ] God rays / volumetric light shafts through fog
- [ ] Color LUT system (swap grades per district/weather/mission)
- [ ] Material weathering: rust, grime, salt stains, peeling paint, moss on granite
- [ ] Decal system: stains, cracks, graffiti, posters, tire marks, blood (toggleable)
- [ ] Consistent PBR material library (asphalt, cobble, brick, granite, wood, metal, glass, water)

## 4. Lighting
- [x] Day/night dynamic sun/moon + ambient changes — DayNight.tsx, 600s cycle, sun pos/intensity/color + hemisphere + ambient + fog/bg drive
- [~] Street lights (auto on at dusk), warm sodium glow — lamp-head emissive ramps with night (Props.tsx); real per-lamp point lights TODO
- [~] Lit building windows at night (emissive, randomized) — warm emissive glow ramps at night across all building materials (Buildings.tsx); per-window mask/randomization TODO
- [ ] Neon/shop signs as light sources
- [ ] Vehicle headlights/taillights/brake lights as real lights
- [ ] Emergency lights (police) flashing
- [x] **Palmer’s Island Lighthouse** rotating beam — Lighthouse() in DayNight.tsx, beam brighter at night
- [ ] Light probes / baked GI for interiors; shadow cascades tuning
- [x] Moon + star sky at night; sunrise/sunset gradients — drei <Stars> + Sky sunPosition + fog/bg gradient by hour

## 5. Weather & VFX
- [~] **WeatherController** state machine: Clear / Dense Fog / Coastal Rain / Nor’easter — Clear/Rain toggle (store.ts weather, key R); Fog/Nor’easter states TODO
- [~] Rain particles + screen rain droplets + ripples/puddles — falling rain streaks (Rain.tsx) + grey grade/closer fog (DayNight); droplets/puddles TODO
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
- [~] Boats bobbing; ferries; fishing vessels with wakes — bobbing fishing boats (HarborProps.tsx); ferries/wakes TODO
- [~] Buoys, nets, lobster traps, dock pilings — dock pilings + bobbing buoys along the OSM shoreline (HarborProps.tsx); nets/traps TODO
- [ ] Splashes when entering water; swim/drown logic
- [ ] Tide / “Gloria” flood level change

## 7. World props & set dressing
- [~] Street furniture: lamp posts, benches, trash cans, hydrants, mailboxes, bus stops, phone booths (1986) — instanced lamp posts/benches/hydrants/mailboxes along road edges (Props.tsx); trash cans/bus stops/phone booths TODO
- [ ] Traffic lights + stop signs (functional + decorative)
- [ ] Power lines / utility poles, dumpsters, crates, pallets
- [ ] Storefront awnings, signage, A-frame signs, window displays
- [ ] Parked cars lining streets
- [ ] Harbor props: nets, traps, barrels, forklifts, shipping containers
- [~] Vegetation: street trees, weeds in cracks, harbor grass — instanced street trees (Props.tsx); weeds/harbor grass TODO
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
- [~] Tire skid marks (decals) + skid/screech audio — skid-mark decal ring buffer on hard cornering (SkidMarks.tsx); screech audio TODO
- [ ] Tire smoke, dust on dirt, water spray in rain/puddles
- [~] Camera FOV/shake scaling with speed; speed lines — FOV widens + subtle shake with car speed (FollowCamera); speed lines TODO
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
- [x] **MissionManager**: objective/trigger/state/reward engine + markers + waypoints — mission.ts + MissionRunner.tsx (objective beam/ring); waypoint trail TODO
- [x] **Dual-axis Heat/Wanted**: Axis A police (1–5), Axis B faction aggro; decay; busted/wasted states — game.ts police+faction 0–5 + decay; busted/wasted TODO
- [ ] **Safehouses** (Maplecroft) — clear heat + save + sleep/time-skip
- [x] **PlayerWallet** + currency UI — game.ts cash + addCash; HUD cash readout
- [ ] **AcquisitionEngine** (5 businesses) + property ownership/markers
- [ ] **RevenueManager** (daily yields, margin-leak events)
- [ ] **ChopShopArmsManager** (weapons gated to Quequechan Mill #4 tier)
- [ ] **WeatherController** ↔ vehicle friction
- [ ] **Dialect Engine** (non-rhotic barks; Chip Worthington hard-Rs)
- [ ] **RadioManager** integration with story milestones
- [~] Save/load (IndexedDB/localStorage) + autosave + multiple slots — localStorage save + 20s autosave (GameSystems.tsx); multi-slot TODO
- [~] Time of day clock + day counter; time-skip — HUD clock from shared.hour; day counter + time-skip TODO
- [ ] Respect/reputation + faction standing

## 16. Missions & content
- [~] **“Off the Boat”** opener (arrival → Bethel → fish-pier ambush → fog getaway → safehouse) — 3-step playable version (Bethel → steal car → safehouse); ambush/fog beats TODO
- [~] Mission framework primitives: go-to, follow, deliver, chase, escape, eliminate, protect, steal, tail, timed, stealth — go-to + steal/needCar live; remaining primitives TODO
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
- [~] Minimap/radar (rotation, streets, property icons, hostile blips, lighthouse sweep, objective) — player-centered radar (Minimap.tsx: roads, water, objective, heading arrow); blips/property icons/rotation TODO
- [~] Health/armor, stamina, wanted badges (police + faction), wallet, ammo, weapon — health bar + police/faction badges + wallet + clock (HUD.tsx); armor/stamina/ammo/weapon TODO
- [ ] Objective markers + waypoints + on-screen distance
- [ ] Interaction prompts + context hints
- [ ] Big map screen (set waypoint, fast-travel, legend)
- [ ] Subtitles + dialogue UI + phone/contacts
- [ ] Notifications (mission, cash, busted/wasted), damage vignette + directional hit indicators

## 22. UI aesthetics & menus
- [ ] **1986 retro UI** theme (fonts, colors, CRT/neon styling) — consistent kit
- [ ] Main menu (New/Continue/Load/Settings/Extras) with art + ambient scene
- [~] Pause menu, mission screen, stats/progress screen — pause/settings overlay (PauseMenu.tsx: resume, view, weather, reset); mission/stats screens TODO
- [ ] Loading screens with art + tips/lore
- [ ] Map/HUD icon set; mission-text styling; credits
- [ ] Photo-mode UI (filters, frames, stickers)

## 23. Game feel / juice
- [~] Camera shake (impacts, explosions, engine, gunfire) — melee + speed shake (shared.shake/addShake, FollowCamera); explosions/gunfire TODO
- [ ] Hit-stop / time-dilation on big hits; slow-mo finishers (optional)
- [ ] Impact particles (sparks, dust, debris, blood toggle), screen-space hit FX
- [ ] Controller rumble / gamepad haptics
- [x] Damage/low-health screen FX (desaturate, pulse, blur) — red inset damage vignette scaling with low health (HUD.tsx)
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

# Part II — World Detail Atlas (intricate, per-city)

Granular mapping + aesthetic tasks. Each top-level checkbox is a trackable unit;
the nested bullets are the intricate spec for that unit. Grounded in the real
South Coast (real roads, real architecture). All achievable in the web engine via
modular kits + procedural placement driven by OSM data.

## 32. Roads & paving (surface system, all cities)
- [~] **Road-class material set** — distinct look per OSM class — Roads.tsx 3 classes (highway/surface/cobble); per-class wear sub-bullets TODO
  - motorway/trunk: smooth dark highway asphalt + rumble strips, wide lanes
  - primary/secondary: city asphalt, patched, oil-stained centerlines
  - residential: narrower, cracked, frost-heaved, tar crack-seal “snakes”
  - service/alley: broken asphalt, gravel patches, weeds in seams
- [~] **Historic cobblestone & brick** — Johnny Cake Hill / NB historic district — makeCobbleTexture() running-bond granite setts on footway/path/steps
  - rounded granite setts, uneven height, moss in joints, wet-shine, cart-rut wear
  - brick-paved crosswalks & plazas; herringbone vs running-bond patterns
- [~] **Lane & road markings** — double-yellow, dashed white, turn arrows, stop bars, “ONLY”, crosswalk zebra/ladder, faded/repainted, plow-scraped — center/edge lines baked into highway asphalt texture; arrows/stop-bars/crosswalks TODO
- [ ] **Curbs & edges** — granite curbstones (NB/FR signature), curb cuts, ADA ramps, rolled curbs in suburbs, painted (yellow no-park / blue handicap)
- [ ] **Drainage & utilities in-road** — catch-basin grates, manhole covers (city seal), water/gas valve caps, sewer steam, gutter flow in rain
- [ ] **Wear & grime decals** — potholes (patched/open), tar seams, oil drips at stop lines, skid marks, manhole settling rings, salt-stain whitening
- [ ] **Embedded rail/trolley tracks** — old streetcar rails flush in pavement near downtown/mills
- [ ] **Parking** — parallel-park lane markings, metered spots, lots (striped, light poles, painted arrows), gravel/dirt back lots
- [ ] **Road geometry polish** — crown/camber, banking on ramps, expansion joints on bridges, smooth spline tangents at corners (no hard kinks)

## 33. Intersections, signage & street systems
- [ ] **Traffic control** — period (1980s) signal heads on mast arms + pedestal, walk/don’t-walk, blinking-yellow at night, stop/yield signs, all-way stops
- [ ] **Rotaries/traffic circles** — President Ave rotary (FR) and others, yield geometry, central island landscaping
- [ ] **Signage kit** — green street-name signs, one-way, no-parking, speed limit, school zone, route shields (**I-195, US-6, MA-18, MA-24, MA-79, MA-138**), overhead guide signs on highways
- [ ] **Street lighting** — cobra-head sodium (amber) on arterials; historic acorn/harbor lamps in the cobblestone district; auto-on at dusk; pools of warm light
- [ ] **Roadside furniture** — utility poles with sagging wires + transformers + pole-mounted signs, fire hydrants, USPS blue mailboxes, newspaper boxes, bus shelters, phone booths, parking meters, benches, bike racks
- [ ] **Wires & overhead** — power/phone line spans pole-to-pole, service drops to houses, traffic-signal span wires, slight catenary sag + wind sway

## 34. Buildings & façade system (modular kit, shared)
- [ ] **Footprint → mass → roof** — extrude OSM footprints with real heights; roof types: flat+parapet, gable, hip, mansard, sawtooth (mills), with chimneys/vents/AC units/water tanks
- [ ] **Façade module library** — tileable bays with: double-hung windows, storefront plate glass, arched/round-top windows, bay windows, doors/transoms, cornices, lintels, sills, string courses, quoins
- [ ] **Material set (PBR)** — red brick (multiple bonds), Fall River **granite block**, clapboard, wood shingle, stucco, cast stone, painted brick, glazed terra-cotta trim
- [ ] **Detail props** — fire escapes (tenement signature), downspouts/gutters, awnings, window AC units, satellite-less era TV antennas, rooftop billboards, ghost-sign painted ads, parapets, cornice brackets
- [ ] **Weathering pass** — soot near rooflines, rust streaks under metal, salt bloom near harbor, peeling paint, water stains, boarded windows in dead zones
- [ ] **Glass & interiors fake-out** — parallax/interior-cubemap windows + lit rooms at night (randomized warm/cool, some dark)
- [ ] **Procedural façade assignment** — pick kit + materials by district + building size + era so streets read coherent, not repetitive

## 35. Residential typologies (New England)
- [ ] **Triple-decker** (the iconic FR/NB three-family) — stacked porches, flat/low roof, clapboard, side stair, small yard, driveway
- [ ] **Sea-captain & mill-owner mansions** — Greek Revival / Federal / Italianate on County St (NB) and the Highlands (FR); columns, widow’s walks, iron fences
- [ ] **Victorian / Queen Anne** — turrets, gingerbread trim, polychrome paint, wrap porches
- [ ] **Worker row houses & duplexes** — tight mill-adjacent rows, shared walls
- [ ] **Cape Cod cottages & shingle-style** — gray weathered shingles, gambrel/saltbox roofs, dormers, hydrangeas, crushed-shell driveways (Cape district)
- [ ] **Postwar ranches & capes** — suburban Brockton/outer districts
- [ ] **Yard kit** — picket/chain-link fences, stoops, clotheslines, lawns, hedges, mailboxes, detached garages, above-ground pools, lawn ornaments

## 36. Commercial, storefronts & signage
- [ ] **Mixed-use main streets** — ground-floor retail under apartments (Acushnet Ave NB, South Main/Columbia FR)
- [ ] **Storefront kit** — recessed entries, plate-glass display windows, bulkhead bases, transoms, roll-down security gates, awnings
- [ ] **Signage** — neon, hand-painted, plastic backlit box signs, projecting blade signs, barber poles, era-correct logos (fictional)
- [ ] **Business types (flavor)** — Portuguese bakery (malasadas), package store, pharmacy, luncheonette/diner, fish market, hardware, laundromat, pawn shop, tavern/bar (neon), corner store, record shop, movie marquee, gas station (period pumps + price signs)
- [ ] **Interiors (hero shops)** — bar, bakery, gym, gun-running mill front, safehouse — enterable, dressed
- [ ] **Window dressing** — products, “OPEN/CLOSED” signs, flyers/posters, day-night open/close states

## 37. Civic, religious & industrial
- [ ] **Fall River granite mills** — multi-story granite blocks, tall mill windows, sawtooth/monitor roofs, brick smokestacks, water/stair towers, loading docks, mill yards + the Quequechan canal/river running through
- [ ] **Churches** — St. Anne’s basilica (twin spires, granite + marble), Seamen’s Bethel, ornate Catholic parishes; stained glass; bell towers
- [ ] **Civic buildings** — city hall, library, courthouse, post office, fire/police stations, schools (brick + columns)
- [ ] **Industrial waterfront** — fish-processing plants, ice houses, cold storage, fuel depots, rail spur + freight yard, water towers
- [ ] **Parks & green** — Buttonwood Park (NB), Kennedy Park (FR), Cape beaches/dunes; trees, paths, ballfields, bandstands, monuments

## 38. Ocean, harbor & working waterfront (per body of water)
- [ ] **New Bedford Harbor / Acushnet River** — the Hurricane Barrier (massive stone + gate), State Pier, fish piers with draggers/scallopers moored, fuel & ice docks, co-op
- [ ] **Palmer’s Island Lighthouse** — modeled + rotating beam
- [ ] **Mount Hope Bay (Fall River)** — Battleship Cove (USS Massachusetts, PT boats, submarine Lionfish), waterfront under the Braga Bridge
- [ ] **Cape Cod waters** — beaches, dunes, marinas, moored yachts, the Canal
- [ ] **Water shading** — Gerstner waves, foam at shore/pilings, fresnel + depth color, oily sheen near docks, reflections, wakes behind boats
- [ ] **Waterfront props** — pilings, bollards, cleats, lobster traps stacked, nets drying, buoys, dinghies, gulls on every piling, breakwaters/jetties, seaweed at tide line
- [ ] **Boats (ambient + usable)** — fishing draggers, ferries (Cuttyhunk/Vineyard), pleasure boats, Coast Guard; bobbing animation; usable boat for smuggling
- [ ] **Tide & flood** — tide line shading; “Gloria” storm-surge flood that raises water over low roads/docks

## 39. Inter-city highway network (major upgrade)
- [ ] **I-195** — the east-west spine linking **New Bedford ↔ Fall River**: 4-lane divided, median jersey barrier, guardrails, breakdown lanes, overhead green guide signs, mile markers, sodium lighting, embankments
- [ ] **Interchanges & ramps** — on/off ramps, cloverleaf/diamond interchanges, gore points, merge/accel lanes, ramp meters-off (era), exit numbering
- [ ] **MA-24** — Fall River ↔ **Brockton** (north); **US-6** coastal route; **MA-18** NB waterfront connector to I-195; **MA-79/138** spurs
- [ ] **Cape connection** — US-6 to the **Sagamore/Bourne bridges** over the Cape Cod Canal
- [ ] **Highway dressing** — sound barriers, cut-slope/embankment terrain, drainage culverts, overpasses with shadow, reflective signage, rumble strips, lane reflectors, breakdown shoulders, brush/treelines
- [ ] **Traffic on highways** — faster lane-following AI, merging, trucks, exits; police highway pursuit
- [ ] **Seamless streaming** — load/unload districts as you drive the highway between cities (no loading screens)

## 40. Bridges (hero infrastructure)
- [ ] **Braga Bridge (“Verde Bridge”, Fall River)** — the long green steel cantilever over the Taunton River; deck, towers, truss detail, lime-green paint, night lighting + fog glow; drivable, with Battleship Cove beneath
- [ ] **New Bedford–Fairhaven Bridge** — swing-span over the Acushnet, low steel deck
- [ ] **Brightman St / old bascule bridges** — period detail
- [ ] **Sagamore & Bourne Bridges** — Cape Cod Canal steel arches
- [ ] **Rail & canal bridges** — smaller crossings tying districts
- [ ] **Bridge tech** — expansion joints (bump/rumble), pylons in water w/ reflections, under-bridge ambient shadow + reverb, navigation lights, suicide-fence/railings

## 41. Per-city aesthetic packs
- [ ] **New Bedford — “Whaling City”**
  - cobblestone historic district + Seamen’s Bethel/Whaling Museum/Custom House; working fish harbor; Acushnet Ave commercial; South End (Cape Verdean/Portuguese) triple-deckers + murals; County St mansions; the Hurricane Barrier; gritty maritime palette (greys, weathered wood, rust, harbor blue)
- [ ] **Fall River — “Spindle City”**
  - granite textile mills + smokestacks dominating the skyline; the Flint + the Highlands; the Quequechan; Columbia St Portuguese district; Battleship Cove + the green Braga Bridge; Lizzie Borden house (Second St) + Maplecroft (French St); steep hills; granite-grey + brick-red palette
- [ ] **Brockton — “City of Champions”**
  - brick downtown, boxing gyms (Champion City Gym), Campanello-era homes, working-class grid; warmer brick palette
- [ ] **Cape Cod**
  - weathered-shingle cottages, marinas + yachts, dunes/beaches/lighthouses, US-6, preppy yacht-club money; bright sand/sea-glass palette; summer-crowd density
- [ ] **District transitions** — palette/material/density blends so each city reads distinct from the road

## 42. Other major upgrades & systems
- [ ] **OSM footprint → typology classifier** — auto-tag each building (triple-decker / mill / storefront / mansion / civic) to assign the right kit + materials
- [ ] **Procedural city generator** — scale detailing to full districts from data (no hand placement per building)
- [ ] **Per-city satellite ground** — signed Static Maps draped + aligned for each district (extend the proxy)
- [ ] **Full road-network graph + navmesh** — drives traffic routing, ped sidewalks, GPS/route line, AI pursuit
- [ ] **Streaming & LOD at multi-city scale** — district chunks, impostors, instanced props/crowds, memory budget
- [ ] **Season + time-of-day dressing** — snow banks (winter), leaves (fall), summer crowds (Cape), holiday/feast banners
- [ ] **Interiors streaming** — enterable hero interiors load/unload seamlessly
- [ ] **Living economy** — shops open/close by time; ferries run on schedule; rush-hour traffic density
- [ ] **Destructible/dynamic props** — bins, signs, fences, fruit stands, fire hydrants (spray), light poles
- [ ] **GPS / waypoint route line** on roads to objectives (mini-map + world)

---

# Part III — System Detail Atlases (exhaustive)

Each game system gets its own deep atlas. Real-world 1980s references are listed
for accuracy; **ship fictionalized analogs** (Vice-City style) to avoid trademark.
Per-asset build spec lives under each entry. VO is produced via **ElevenLabs**
(see §G), keyed through a server proxy so the API key never ships in the client.

## A. Vehicle Atlas — the 1980s market (fictionalize on ship)
Per vehicle: low-poly model + LODs, color/livery + dirt/rust variants, damage
deform, working lights, optional interior, handling profile (mass/grip/accel/top
speed/braking), engine+horn audio, spawn rules (district/era/wealth).

- [ ] **American full-size sedans/coupes** — Caprice/Impala, LTD Crown Victoria, Delta 88, Bonneville, Town Car, Fleetwood/DeVille, Diplomat/Gran Fury (cop), Grand Marquis
- [ ] **American mid-size & compact** — Citation, Fairmont, Reliant/Aries (K-car), Cavalier, Tempo/Topaz, Celebrity, Century, Cutlass Ciera, Corsica, Taurus (’86)
- [ ] **Muscle / pony / performance** — Camaro (Z28/IROC), Firebird/Trans Am, Mustang 5.0 (Fox), Corvette C4, Monte Carlo SS, Buick Grand National/GNX, Mustang SVO, Dodge Daytona, Charger 2.2
- [ ] **Personal-luxury coupes** — Eldorado, Riviera, Toronado, Thunderbird, Cordoba, Mark VI/VII, Monte Carlo, Cutlass Supreme
- [ ] **Station wagons** — Country Squire (woody), Caprice/Custom Cruiser wagon, Colony Park, Vista Cruiser, K-wagon
- [ ] **Pickups** — F-150/F-250, C/K (Silverado), D-series/Ram, Ranger, S-10, Toyota Hilux/pickup, Datsun/Nissan 720
- [ ] **SUVs / 4x4** — Bronco (full + Bronco II), Blazer K5/S-10, Jeep CJ-7 / Wrangler YJ, Cherokee XJ, Wagoneer, Suburban, Scout II, Toyota Land Cruiser/4Runner
- [ ] **Vans & minivans** — Econoline, G-van (boogie van w/ murals), Caravan/Voyager (’84 minivan), Astro, VW Vanagon, Toyota Van
- [ ] **Japanese imports** — Civic/CRX, Accord, Corolla (AE86), Celica, Supra, Datsun/Nissan 280ZX→300ZX, Sentra, Maxima, Camry, Cressida, Mazda RX-7, 626, Mitsubishi Starion/Conquest, MR2, Subaru GL/Brat, Isuzu Impulse
- [ ] **German** — VW Rabbit/Golf GTI, Jetta, Scirocco, BMW E30 3-series, E28 5-series, Mercedes W123/W124, 190E, S-class W126, Audi 4000/5000, Porsche 911/944/928/924
- [ ] **Other European** — Saab 900 (Turbo), Volvo 240/740, Peugeot 505, Fiat/Alfa Spider, Renault Alliance, **Yugo GV**, Lancia, Lotus Esprit
- [ ] **Economy / subcompact** — Chevette, Escort/EXP, Festiva, Sprint/Metro, Horizon/Omni, Pinto holdovers, Gremlin/Pacer holdovers
- [ ] **Exotics & sports** — Ferrari Testarossa/308/328, Lamborghini Countach, DeLorean DMC-12, Porsche 959, Lotus, De Tomaso, TVR
- [ ] **Luxury / executive** — Rolls-Royce/Bentley, Mercedes S, Jaguar XJ/XJS, Cadillac limo, stretch limo
- [ ] **Commercial & service** — yellow taxi (Checker/Caprice), marked police cruiser + unmarked, fire engine + ladder truck, ambulance, garbage truck, box/delivery truck, semi tractor-trailer, tow truck, dump truck, cement mixer, school bus, transit bus, USPS mail jeep/LLV, ice-cream truck, food truck, news van, utility/bucket truck, hearse, parade float
- [ ] **Motorcycles & mopeds** — Harley (cruiser/chopper/police), Honda CB/Nighthawk/Gold Wing, cafe racer, dirt bike, scooter/Vespa, **moped (the “Linguiça”)**
- [ ] **Boats & marine** — fishing dragger/scalloper, lobster boat, ferry (Cuttyhunk/Vineyard), speedboat/cigarette boat, sailboat/yacht, dinghy/skiff, Coast Guard cutter/RIB, tugboat, **“Codfish 40” cruiser**
- [ ] **Misc/utility** — bicycle (BMX/road/beach cruiser), forklift, golf cart, riding mower, go-kart, airport tug, harbor crane
- [ ] **Canon flavor mapping** — “Townie” rusted beater (K-car/Caprice analog) heavy in Fall River; “Linguiça” moped; “Codfish 40” cruiser; preppy imports + yachts on the Cape; lowriders for the South End/Crioulo crews
- [ ] **Systems** — vehicle data table (stats/spawn), paint/livery system, dirt/rust/damage materials, license plates (MA), wreck/burn states, ambient parked-car variety, rarity/wealth tiers per district

## B. Character Atlas
Per character: model (GLB/MetaHuman-grade), rig + anim set, face + lipsync,
portrait, **ElevenLabs voice profile**, wardrobe, role/missions.
- [ ] **Vinny Tavares (protagonist)** — full sheet: look, wardrobe options, voice, ability/anim set, arc beats
- [ ] **Allies** — Auntie Conceição, Deacon Mealy, Reggie “Two-Stroke” Pina, Marisol Cabral, Iron Mike Fontaine (each: bio, model, VO, mission role)
- [ ] **Antagonists** — Sully Brangwynne, Chip Worthington III, Lady Borden, the Fake Kennedys (each: bio, model, VO, boss role)
- [ ] **Radio personalities** — Buddy Mello, Iron Mike, DJ Sully, Tia Conceição (voices + on-air persona)
- [ ] **Faction rosters** — Azorean Syndicate, Crioulo/South End Crew, Cape Set, Provençal, the Brass (police): boss → lieutenants → enforcers → grunts, with colors/wardrobe/vehicles/turf
- [ ] **Named minor NPCs** — vendors, fixers, fence, mechanic, bartender, priest, gym corner-man, ferry captain, mission-givers
- [ ] **Generic NPC archetypes** — dockworker, fisherman, millhand, factory worker, preppy/yachtie, cop, priest/nun, businessman, retiree, teen, jogger, drunk, tourist, panhandler, kid — each w/ model set + wardrobe + voice bank
- [ ] **Production** — character data table, casting/voice map, portrait set, relationship/standing data

## C. Pedestrian Behavior Atlas (elevated AI)
- [ ] **Core states** — idle, stroll, commute, sit, lean/smoke, window-shop, jog, wait (crosswalk/bus), converse, eat
- [ ] **Threat reactions** — flee, panic-run, cower, hands-up, rubberneck/film, fight back, call cops, hide indoors
- [ ] **World reactions** — to weather (umbrellas, run for cover, hunch in cold), to vehicles (dodge, jump back, yell, slap hood), to gunfire/explosions (scatter), to fire/water
- [ ] **Social behaviors** — groups walking, conversations (turn-take + gestures), queues, crowds at events (Feast, boxing, ferry), street performers, arguments
- [ ] **Daily schedules** — per archetype + time-of-day (home→work→lunch→home→nightlife); shops/bars populate accordingly
- [ ] **Navigation** — sidewalk navmesh, crosswalks, jaywalking, doorway enter/exit, stairs, avoid obstacles + each other, personal space
- [ ] **Dialogue/barks** — dialect engine + **ElevenLabs** archetype voice banks; greetings, insults, reactions, ambient chatter; subtitles
- [ ] **Reputation reactions** — defer/fear/respect by player standing + turf; faction members hostile on their turf
- [ ] **Density & perf** — per-district/time spawn density, crowd pooling, behavior LOD (simplify off-screen)

## D. Interiors Atlas
Shared modular interior kit (walls/floors/ceilings/doors/stairs/windows/lighting),
era-1980s prop library, ambient audio + interactables; hero interiors fully
dressed, ambient ones use window fake-out.
- [ ] **Residential** — triple-decker apartment (kitchen, living, 2 bed, bath, hall, back porch), sea-captain mansion (foyer, parlor, study, grand stair, bedrooms), Cape cottage, worker flat, tenement hallway
- [ ] **Safehouses** — starter flat, **Maplecroft B&B** (period-creepy), upgraded apartments, mansion endgame — each w/ bed (save), wardrobe (change), stash
- [ ] **Bars/nightlife** — tavern (neon, pool table, jukebox), dive bar, social club (Portuguese/Azorean), gambling back-room
- [ ] **Food** — Portuguese bakery (cases of malasadas), diner/luncheonette (counter+booths), clam shack, coffee shop
- [ ] **Shops** — package/liquor store, pharmacy, pawn shop, hardware, record shop, barbershop, gun-running mill front, gas-station mart, corner store
- [ ] **Civic/religious** — Seamen’s Bethel (ship-prow pulpit), church nave, city hall, police station (cells), library, courthouse
- [ ] **Industrial** — granite mill floor (looms / chop-shop bay), warehouse, fish-processing, ice house, boat cabin/wheelhouse
- [ ] **Sports/training** — Champion City Gym (ring, bags, lockers)
- [ ] **Systems** — interior streaming (load on enter), occlusion, exterior/interior door transitions, interior lighting + ambience, NPC population, lootables/interactables

## E. Weapons Atlas (1980s-appropriate, fictionalized)
Per weapon: model, damage/range/fire-rate/recoil/mag, ammo type, reload + holster
anim, sound (foley/ElevenLabs), pickup, tier (Quequechan Mill upgrade), legality
(heat on draw/fire).
- [ ] **Fists & improvised** — fists, brass knuckles, baseball bat, crowbar, pipe, tire iron, chain, broken bottle, hammer, **gaff/fishing knife/oar** (maritime), nightstick/baton
- [ ] **Knives/blades** — switchblade, hunting knife, machete, cleaver
- [ ] **Pistols** — .38/.357 revolver, 9mm auto (Beretta-92 analog), .45 (1911 analog), compact/snub, Glock-17 analog (new ’82), Desert Eagle analog
- [ ] **Shotguns** — pump, sawn-off, double-barrel, semi-auto
- [ ] **SMGs** — Uzi analog, MAC-10/11 analog, MP5 analog, grease gun
- [ ] **Rifles** — bolt hunting rifle, lever-action, AK analog, M16/AR analog, M1 carbine, sniper (scoped)
- [ ] **Heavy (mill-tier)** — RPG/LAW analog, light MG, flamethrower, mounted gun
- [ ] **Thrown/placed** — molotov, frag grenade, pipe bomb, dynamite, throwing knife, brick
- [ ] **Special / regional** — harpoon/whaling gun, speargun, flare gun (signal), nail gun, taser-prototype
- [ ] **Systems** — weapon wheel/inventory, ammo types + pickups, holstering, dual-wield (stretch), durability for melee, weapon shops + the mill chop-shop tier gate, cops react to brandishing

## F. Clothing & Wardrobe Atlas
Player slots: head, face/eyes, torso-inner, torso-outer, hands, legs, feet,
accessories. Per item: model fit to rig, materials, color variants, wet/dirty/
blood states, price, vendor, unlock.
- [ ] **Tops** — t-shirt, polo, flannel, bowling shirt, Hawaiian shirt, fisherman’s/cable-knit sweater, hoodie, tank, dress shirt
- [ ] **Outerwear** — leather jacket (biker), denim jacket, Members-Only jacket, windbreaker/track jacket, bomber, peacoat, oilskin/raincoat (slicker), suit jacket/blazer, varsity jacket
- [ ] **Bottoms** — jeans (straight/acid-wash), chinos, track pants, work pants, shorts, suit trousers, coveralls
- [ ] **Footwear** — high-top sneakers, running shoes, work boots, cowboy boots, loafers, deck/boat shoes, dress shoes
- [ ] **Headwear** — ballcap, trucker cap, knit watch cap, fedora, bandana, headband, do-rag
- [ ] **Eyewear/accessories** — aviators, Wayfarers, gold chains, watch, gloves, belt, suspenders, fanny pack, backpack
- [ ] **Role/faction outfits** — Azorean Syndicate sharp suit, South End/lowrider streetwear, Cape preppy (sweater-over-shoulders, boat shoes), dockworker/oilskins, millhand coveralls, cop uniform, priest cassock, boxer trunks+robe, tracksuit
- [ ] **Systems** — clothing shops, change at safehouse, full outfit presets, dirt/wet/blood overlay states, story-locked outfits, disguise (lower heat/faction recognition)

## G. Radio & VO Atlas (ElevenLabs pipeline)
- [ ] **VO production pipeline** — ElevenLabs voice per host/character → generated audio assets → packaged/streamed; **server proxy for the ElevenLabs key** (mirror the maps-signing proxy); Web-Speech fallback for dev; subtitle/caption data alongside each line
- [ ] **The Rage (1480 AM, talk)** — Buddy Mello: rant scripts (bridge traffic, potholes, the Pats, civic gripes), caller segments, station IDs, milestone-reactive lines (player rampage callouts)
- [ ] **The Anvil (WBOX, sports)** — Iron Mike Fontaine: boxing gospel, City-of-Champions hype, fight recaps, training rants
- [ ] **WHALE 92.1 (classic rock)** — DJ Sully: patter, dedications, triple-shots, weekend-format bits
- [ ] **Maré Alta 105.3 (Portuguese/Cape Verdean oldies)** — Tia Conceição: warm host bits (PT/Kriolu phrases), feast-season shout-outs
- [ ] **New stations** — Cape yacht-rock/AOR (preppy), punk/hardcore (youth), AM news/talk, Cape Verdean kriolu, country, oldies/doo-wop
- [ ] **Shared content** — fictional **commercials** for South Coast businesses, PSAs, **traffic/weather/news** that reference real geography + react to player/story milestones, station jingles/IDs, time-of-day shows
- [ ] **Music** — royalty-free/procedural now → curated license-free later; per-station playlists, crossfade, in-car vs walking ambience, volume ducking under talk
- [ ] **Mission/cinematic VO** — character dialogue, mission briefings, in-game phone calls, cutscene lines — all via ElevenLabs voice map; lipsync hookup

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
- Created `plans/mount-hope.md` as source of truth, then **expanded it** into a full essential-systems + aesthetics/art-direction/game-feel checklist.
- Added **Part II — World Detail Atlas**: intricate per-city mapping & aesthetic tasks — road/paving system, intersections & signage, modular building/façade kit, NE residential typologies (triple-deckers, mansions, Cape cottages), storefronts & signage, granite mills/churches/civic, ocean & working-waterfront detail, the **inter-city highway network (I-195, MA-24, US-6, MA-18)**, hero **bridges (Braga/“Verde”, Fairhaven, Sagamore/Bourne)**, per-city aesthetic packs (NB/FR/Brockton/Cape), and major systems upgrades (typology classifier, procedural city-gen, navmesh, streaming/LOD, living economy).
- Added **Part III — System Detail Atlases**: exhaustive **vehicle atlas** (the 1980s market by category, fictionalized for ship), plus **character**, **elevated pedestrian-AI**, **interiors**, **weapons**, **clothing/wardrobe**, and **radio & VO** atlases — the radio/VO atlas specifies an **ElevenLabs** pipeline (server-proxied key, subtitles, per-host/character voices, more stations, ads/news/music).
- Added the **Working loop** process (read → scope → build → verify → review → check off → log → commit → repeat) as the canonical execution protocol.
- **Execution batch (+10 items, recommended order):** ① `Props.tsx` — instanced street furniture (lamp posts, hydrants, mailboxes, benches) along road edges (§7); ② lamp-head + building **lit-window glow** ramping at night (§4); ③ **camera FOV scales with car speed** (§13); ④ `SkidMarks.tsx` tire-mark decals on hard cornering (§13); ⑤ **camera shake** (melee + speed via `addShake`) + **low-health damage vignette** (§23); ⑥ `Minimap.tsx` player-centered **radar** (roads/water/objective/heading) (§21); ⑦ `Rain.tsx` + storm grade/closer fog, **R** toggles rain (§5); ⑧ `HarborProps.tsx` — dock pilings + bobbing buoys/fishing boats on the OSM shoreline (§6); ⑨ instanced **street trees** (§7); ⑩ `PauseMenu.tsx` — **Esc/P pause** (resume/view/weather/reset) freezing player/car/time (§26). Added `shared.carSpeed/skid/shake` + `store.ts` weather/paused/slice. Shipped (`d238002`).
- **Execution batch (§32/§3/§4/§15/§16):** rewrote `Roads.tsx` into a 3-class surface system (highway w/ lane markings · asphalt streets · historic granite cobblestone via new `makeCobbleTexture`); added `Effects.tsx` (bloom + vignette + SMAA) + **ACES tone mapping**; added `DayNight.tsx` (600 s day/night cycle driving sun/hemisphere/ambient/fog/bg + drei `<Stars>` + **Palmer’s Island lighthouse beam**); added `game.ts` **PlayerWallet + dual-axis Heat/Wanted** (police + faction 0–5, decay) with `GameSystems.tsx` autosave/load; added `mission.ts` + `MissionRunner.tsx` **mission engine** with a 3-step playable **“Off the Boat”** opener (Bethel → steal car → safehouse) + objective beam/ring marker; HUD gained cash/clock/stars/health panel + objective banner. Shipped (`39ece9e`, `80a05b8`).

<!-- Append new dated entries above this line as work lands. -->
