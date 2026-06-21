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

# Part II — World Detail Atlas (intricate, per-city)

Granular mapping + aesthetic tasks. Each top-level checkbox is a trackable unit;
the nested bullets are the intricate spec for that unit. Grounded in the real
South Coast (real roads, real architecture). All achievable in the web engine via
modular kits + procedural placement driven by OSM data.

## 32. Roads & paving (surface system, all cities)
- [ ] **Road-class material set** — distinct look per OSM class
  - motorway/trunk: smooth dark highway asphalt + rumble strips, wide lanes
  - primary/secondary: city asphalt, patched, oil-stained centerlines
  - residential: narrower, cracked, frost-heaved, tar crack-seal “snakes”
  - service/alley: broken asphalt, gravel patches, weeds in seams
- [ ] **Historic cobblestone & brick** — Johnny Cake Hill / NB historic district
  - rounded granite setts, uneven height, moss in joints, wet-shine, cart-rut wear
  - brick-paved crosswalks & plazas; herringbone vs running-bond patterns
- [ ] **Lane & road markings** — double-yellow, dashed white, turn arrows, stop bars, “ONLY”, crosswalk zebra/ladder, faded/repainted, plow-scraped
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

<!-- Append new dated entries above this line as work lands. -->
