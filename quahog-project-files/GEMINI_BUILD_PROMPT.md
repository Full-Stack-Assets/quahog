# The Narrows — Build Prompt (Photorealistic, Console + PC)

> Feed the block below to a Gemini vibe-coding app as the master spec. It
> describes the **ideal finished product**: a **fully developed, AAA-grade,
> photorealistic, third/first-person open-world crime epic for PC and consoles
> (PlayStation 5, Xbox Series X|S, Windows PC)** — *not* a browser game — set on
> the real Massachusetts South Coast and built on real-world photogrammetry.

---

## PROMPT

Build **“The Narrows”** — a **complete, shippable AAA open-world action game for PlayStation 5, Xbox Series X|S, and Windows PC** (gamepad-first, full mouse/keyboard support). It is a third/first-person crime epic set in the **real Massachusetts South Coast** (New Bedford and Fall River, with Cape Cod and Brockton), rendered on **photorealistic real-world 3D geography**. Think *Grand Theft Auto* meets *Google Earth*, at full production value: you walk and drive through the actual streets, harbors, mills, and real landmarks, populated with original characters, living traffic and crowds, dynamic weather, a full radio suite, and a multi-act story campaign with side content. This is a disc/digital-storefront title (Steam, Epic, PlayStation Store, Microsoft Store) with installer, save system, settings, achievements/trophies, controller support, and accessibility options — a real game, not a tech demo or web app.

### Core vibe
Rust-belt coastal noir with salt-air humor. Overcast harbor light, wet cobblestones, gulls, fishing boats, granite mills, neon tavern signs at dusk. Cinematic but readable. The world is *real* (photogrammetry); the characters, cars, story, and UI are stylized-but-grounded game assets layered on top.

### Platforms & performance
- **Target hardware:** PlayStation 5, Xbox Series X|S, and Windows PC (DirectX 12 / Vulkan). Scalable settings from Steam Deck / minimum-spec PC up to high-end RTX with ray tracing.
- **Performance modes:** a **Performance mode (60 fps, dynamic-res ~1440p→4K)** and a **Fidelity mode (30 fps, native 4K + ray-traced GI/reflections)** on consoles; uncapped + DLSS/FSR/XeSS on PC.
- **Controller-first** (DualSense/Xbox), with full mouse/keyboard. DualSense haptics + adaptive triggers (engine rev, braking, gunfire, punches). Remappable controls.
- Fast streaming open world with no hard loading screens after the initial load; seamless district-to-district traversal; **save/load** (manual + autosave), settings, achievements/trophies, photo mode.

### Engine & rendering
- Built in a **modern AAA engine — Unreal Engine 5** (or equivalent): **Nanite** virtualized geometry, **Lumen** dynamic global illumination + reflections, **World Partition** streaming, **Chaos** physics & destruction, **Chaos Vehicles** for driving.
- **World geometry from real-world photogrammetry:** ingest **Google Photorealistic 3D Tiles via Cesium for Unreal** (3D Tiles / `CesiumGeoreference` anchored at New Bedford lat/lon), so the city is the *actual* New Bedford/Fall River, georeferenced into the play space. Real road network and POIs from **OpenStreetMap** drive traffic, pedestrian zones, and mission placement.
- **Hand-authored hero detail layered on the photogrammetry:** key landmarks (Seamen’s Bethel, the fish piers, Battleship Cove, the Lizzie Borden house, mills, bridges) get bespoke art, interiors, and collision on top of the scanned base mesh; clean up scan artifacts in playable zones.
- **Characters via MetaHuman** (or equivalent): fully rigged, mocap-driven humans with facial animation and lipsync for cutscenes/VO. **Vehicles** as detailed drivable models with interiors, damage, and working lights.
- **Materials/atmosphere:** PBR throughout, volumetric clouds & fog, physically-based sky + day/night, wet-surface shading, screen-space + ray-traced reflections, decals, foliage, particle systems (rain, spray, sparks, smoke), filmic post (tone mapping, bloom, motion blur, depth of field, chromatic flourishes for the “Coastal Neon” dusk).
- **Audio engine:** Wwise/MetaSounds with full 3D spatialization, occlusion, and a dynamic music/score system layered under the in-world radio.

### The world
- Real **New Bedford** historic waterfront as the primary playable district: cobblestone Johnny Cake Hill, William/Union/Water Streets, MacArthur Drive (Route 18), the working fish piers, the harbor and hurricane barrier, Palmer’s Island Lighthouse offshore.
- **Fast-travel** (taxi/map) between real anchors: **New Bedford – Seamen’s Bethel**, **Fall River – Battleship Cove (USS Massachusetts)**, **Fall River – Lizzie Borden House (230 Second St)**, **Fall River downtown**, plus the Cape and Brockton — with streamed traversal so you can also just drive between them.
- Real road network and points of interest pulled from **OpenStreetMap** drive traffic routing, pedestrian zones, and mission markers.
- Hero landmark **Seamen’s Bethel** (the Whaleman’s Chapel) is hand-detailed and used as the opening location.

### Player & controls
- Full on-foot moveset: walk/jog/sprint, jump, crouch/cover, climb/vault, swim; **enter/exit/hotwire vehicles**; **melee** (punch/grapple/combo) and **gunplay** (aim, shoot, lock-on/free-aim, reload, cover-shoot, throw); pickups, interact, lean/peek.
- **Gamepad-first mapping** (left stick move, right stick camera, triggers accelerate/brake or aim/fire, face buttons jump/enter/interact/melee, D-pad weapon & radio, shoulder buttons cover/sprint) **plus full mouse/keyboard** (WASD, mouse-look/aim, E interact, F melee, V camera, R reload, Tab map). Remappable; DualSense haptics + adaptive triggers.
- **Third-person chase camera** (eases behind player/car, collision-aware) and a clean **first-person** view, toggleable; aim mode tightens over-the-shoulder; cinematic camera for cutscenes; **photo mode**.
- The player is a **fully rigged, mocap-animated human** (MetaHuman-grade) with locomotion blendspaces, combat anims, facial animation, and a 1986 South Coast wardrobe; outfit changes. Proper character controller with physics collision (no surface pop/float).

### Vehicles
- Drivable **arcade-but-grounded car physics** (responsive, high lateral grip, modest top speed for tight streets), with enter/exit, reverse, and contact response.
- A handful of **real-looking car models**: a boxy SUV (Bronco-style), a muscle coupe (Mustang-style), a sport sedan (Infiniti G-style), a sports coupe (Nissan Z-style), and a compact crossover (RAV4-style). Headlights/taillights, working wheels, period-appropriate.
- **Collision response:** cars bump and shove other cars; the player can be knocked by traffic; you can run into things with weight and feedback.

### NPCs & living city
- **Pedestrians** wander sidewalks (rigged humans, varied looks) with idle/walk states; they react to the player — flee, stumble, get knocked down.
- **Traffic** drives the real road network, turning at intersections, following lanes; region-appropriate vehicles.
- **Melee combat:** punch pedestrians → knockdown/unconscious; repeated hits → “killed” (ragdoll/lie down). Crowds react and scatter.
- **Dual-axis Wanted/“Heat” system:** Axis A = police response (escalating), Axis B = faction aggro (whose turf you hit). Cops and faction enforcers pursue; lose heat at a safehouse.

### Weather, sky, time
- Dynamic **weather cycle**: clear → overcast → coastal rain → Nor’easter, affecting fog, light, road sheen, and driving grip.
- Drifting **volumetric clouds**, **airliners** crossing the sky, gulls, harbor boats, real **ocean** water with reflections.
- **Day/night cycle** with dusk “Coastal Neon”: flickering tavern signs reflecting off wet cobblestones and oily dock water; lighthouse beam sweeps.
- A scripted **“Gloria” hurricane set-piece** (homage to the ’85 storm) that floods low roads, alters the map, and sinks boats.

### Audio & radio
- An in-car/ambient **radio** with multiple stations you switch live ([ ]) and mute (M):
  - **WHALE 92.1** — classic rock, DJ “Sully.”
  - **The Rage (1480 AM)** — talk; host **Buddy Mello** rants about the Braga Bridge, potholes, civic life (Eastern New England “pahk the cah” accent).
  - **The Anvil (WBOX)** — sports talk; **Iron Mike Fontaine**, Brockton “City of Champions” boxing gospel.
  - **Maré Alta 105.3** — Portuguese/Cape Verdean oldies, host **Tia Conceição**.
- Host voices are real spoken audio (TTS or recorded), scripted per show, ducking under music. Plus SFX: footsteps, engines, punches, gulls, harbor ambience, weather.

### Characters (original cast)
- **Vincent “Vinny” Tavares** — protagonist, South Coast born, just back from “away,” building a stake of his own (boat, bar, a name).
- Allies: **Auntie Conceição** (bakery/fixer), **Deacon Mealy** (keeps the chapel, launders more than souls), **Reggie “Two-Stroke” Pina** (mechanic/garage/wheels), **Marisol Cabral** (ex-Coast Guard, boats & getaways), **Iron Mike Fontaine** (boxing trainer).
- Antagonists: **Sully Brangwynne** (corrupt harbormaster), **Chip Worthington III** (Cape money laundering through a marina), **Lady Beatrice “Lady” Borden** (Fall River dynasty trading on an infamous name), **the Fake Kennedys** (Hyannisport grifter clan).
- Factions: the **Azorean Syndicate** (the Flint), the **South End Crew** (Cape Verdean, New Bedford), the **Cape Set** (preppy money), and **the Brass** (police + harbormaster).

### Missions
- **Opening vertical slice — “Off the Boat”:** Vinny arrives at the New Bedford fish pier; walk the cobblestones to Seamen’s Bethel; a deal at the fish auction goes wrong; pier ambush; high-speed coastal-fog getaway up the waterfront; reach the first safehouse. (Teaches walk, drive, evade, fight.)
- **Act I — The Whaling City (New Bedford):** break the harbormaster’s grip on the docks; earn the South End Crew; take over a wharf (first owned property/income).
- **Act II — Spindle City (Fall River):** cross the green Braga Bridge into the Flint; the **“Acquitted”** Lady Borden thread (heist/cover-up at the Second Street manor); **“The Undefeated”** boxing thread at Champion City Gym.
- **Act III — The Cape & the Storm:** infiltrate Chip Worthington’s heritage-marina laundering; con the Fake Kennedys; the **“Gloria”** hurricane chaos heist; finale at **Battleship Cove** aboard the USS *Massachusetts*.
- **Side activities:** a property empire (bars, wharves, gym, marina) with daily income; boat-smuggling runs; street races over the bridges; the boxing circuit; clam-shack delivery time-trials; radio call-ins that react to your rampages.

### HUD & UI
- Minimap/radar that tracks player rotation, shows property icons, hostile blips in red, and lighthouse sweeps.
- Health/armor, wanted-level badges (police + faction), wallet/cash, current radio station, weather indicator, objective markers, interaction prompts.
- Clean front-end + pause menu: map/fast-travel, view toggle, radio, garage, save/load, and full **Settings** (graphics presets + ray-tracing/upscaler toggles, audio mix, controls remap, accessibility).

### Visual style & post-processing
- Photoreal tiles as the base; PBR-lit game props matched to the scene light.
- Subtle filmic tone mapping, ambient occlusion, bloom on neon/headlights at night, wet-surface reflections, light fog/atmosphere, motion blur on fast driving. Keep it crisp and performant.

### Acceptance criteria (“shippable finished game” looks like)
1. Boots on **PS5, Xbox Series X|S, and Windows PC** to a main menu (New Game / Continue / Load / Settings / Extras), installs and saves like a retail title, and holds the target frame rate in both Performance and Fidelity modes.
2. Shows **photoreal New Bedford/Fall River** (real-world 3D geography), seamlessly streamed with no hard loading screens after entry; the player stands and moves on real streets with solid collision against real buildings.
3. Complete traversal & combat: **walk/sprint/cover, drive the real roads, gunplay + melee, enter/exit/hotwire vehicles, 1st/3rd-person toggle**, all on **gamepad and KB/M**, with DualSense haptics.
4. A **living city**: pedestrian crowds and traffic with believable AI that react to the player; melee, gunfire, and vehicle collisions have weighty response and consequences.
5. **Dynamic weather, full day/night, volumetric clouds, aircraft, real ocean & reflections** are alive; the multi-station **radio** plays with switchable channels and in-character hosts; full SFX + adaptive score.
6. The world spans the **four districts** (New Bedford, Fall River, Cape Cod, Brockton) with **fast-travel** to key anchors (Seamen’s Bethel, Battleship Cove, Lizzie Borden House, Fall River downtown).
7. The **story campaign** is playable start-to-finish — the “Off the Boat” opener through the Act III “Gloria” storm and the Battleship Cove finale — plus the side threads; the **dual-axis Heat system** responds to crime with police + faction pursuit; the **property/economy loop** pays out.
8. Production completeness: full **VO + lip-synced cutscenes**, accessibility options (subtitles, remap, colorblind, difficulty, aim assist), achievements/trophies, photo mode, credits — a real, finished console/PC game, not a tech demo.

Make it feel like a real place you can get lost in — the Whaling City, rendered at AAA fidelity, with a story worth staying for.

---

## FULL CANON (treat everything below as authoritative; build all of it)

**Title / naming.** Ship as **The Narrows** (*South Coast · Now*, 2026). Retired codenames: Project QUAHOG (Family Guy collision), Mount Hope (in-world bay/avenue only). Tone & systems: *GTA: South Coast* feel, **Coastal Neon** aesthetic (lighting mood, not a period piece). Naming canon: **real geography + real landmark names + original characters**; parody district names are in-world *flavor* (mapping below).

### Districts (real place ↔ canonical parody name ↔ flavor)
The open world is four core districts split by structural **canal bridges**:
| Real place | Parody name (canon flavor) | Identity |
|---|---|---|
| **Fall River** | **Cascade** | “Spindle City”: granite textile mills, the Quequechan river, the **Flint** neighborhood, the Borden legacy, the lime-green **Verde Bridge** (= real **Braga Bridge**) |
| **New Bedford** | **New Sefton** | “Whaling City”: working fish pier, cobblestone historic district, Cape Verdean/Portuguese **South End** |
| **Cape Cod** | **Cape Cobb** | Old money, summer people, yacht clubs, preppy imports |
| **Brockton** | **Brockmore** | “City of Champions”: boxing town, blue-collar grit, Champion City Gym |

### Engine systems (implement all; native save system + local DB, e.g. SQLite)
- **PlayerWallet** — singleton tracking cash/balances.
- **EmpireDatabaseManager** — persistence layer (local **SQLite**/save-game) for global player metrics, balances, and **real-time asset ownership**, integrated with console save-data + cloud saves.
- **WeatherController** — state machine: **Clear, Dense Fog, Coastal Rain, Nor’easter** — each tied directly to **surface friction multipliers** (slick cobblestones, flooded docks, bridge slush) that the vehicle physics inherit automatically.
- **AcquisitionEngine** — property acquisition hooks; place interaction markers for the **5 fundamental businesses** from the portfolio.
- **RevenueManager** — time loop that distributes **daily asset yields** and triggers dynamic **margin-leak events**.
- **ChopShopArmsManager** — weapon-crate availability gated to the **upgrade progression tier of Quequechan Mill #4** (the chop shop). Heavy weapons from the mill feel distinctly different from starter pistols.
- **RadioManager** — multi-channel, simultaneous, **crossfading** station audio (stations below).
- **MissionManager** — objective engine coordinating multi-step scripted scenarios (player location, target statuses, rewards).
- **Dual-Axis Hostility (“Heat”) Manager** — **Axis A: Law Enforcement** (1–5 badges); **Axis B: Faction Aggro** (shoot up a faction’s room and their hit squads hunt you in that territory). Lose heat by sleeping at a **safehouse**.
- **Dialect Engine** — Eastern New England **non-rhotic** accent on ambient NPC barks (“pahk the cah”); specific triggers for characters like **Chip Worthington III** and his performative **hard Rs**.
- **“Coastal Neon” render stack** — flickering tavern signs reflecting off rain-slicked cobblestones and oily dock water; the lime-green glow of the **Verde Bridge** in fog; local lighthouse sweeps.

### Vehicles (fictional makes, region-accurate spawning)
- Rusted **“Townie”** sedans and **“Linguiça”** mopeds spawn heavily in **Cascade (Fall River)**.
- **“Codfish 40”** cruisers and **preppy imports** spawn across the canal in **Cape Cobb (Cape Cod)**.
- Real-shape player/garage cars (Reggie’s): boxy SUV (Bronco-style), muscle coupe (Mustang-style), sport sedan (Infiniti G-style), sports coupe (Nissan Z-style), compact crossover (RAV4-style).
- Lowriders for the Crioulo Crews; faction-appropriate models per turf/zip code.

### Factions & turf
- **Azorean Syndicate** — assigned to **the Flint** (Fall River).
- **Crioulo Crews** (Cape Verdean) — **New Sefton’s South End** (New Bedford); lowriders, loyalty, turf.
- **Provençal** gambling rooms — run out of dead mills.
- **Cape Set** — preppy money + the Fake Kennedys (Cape Cod).
- **The Brass** — police + harbormaster’s office.

### Radio (RadioManager — all stations, with hosts reacting to story milestones)
- **The Rage** — **Buddy Mello** screaming about bridge traffic (talk).
- **The Anvil** — **Iron Mike Fontaine** (Brockton boxing/sports talk).
- **WHALE 92.1** — classic rock, DJ “Sully” (music).
- **Maré Alta 105.3** — Portuguese/Cape Verdean oldies, “Tia Conceição” (music).

### Cast (original characters; historical/parody figures used satirically)
- **Vincent “Vinny” Tavares** — protagonist; South Coast born, half-Azorean, raised in the Flint, back from “away.” Arc: errand-runner → made man → kingpin of the harbor.
- Allies: **Auntie Conceição Rosa** (bakery/fixer; also Maré Alta host), **Deacon Mealy** (keeps Seamen’s Bethel; launderer; mission-giver), **Reggie “Two-Stroke” Pina** (mechanic/chop-shop/garage), **Marisol Cabral** (ex-Coast Guard; boats/getaways; romance-loyalty thread), **Iron Mike Fontaine** (boxing trainer; The Anvil).
- Antagonists: **Sully Brangwynne** (corrupt harbormaster), **Chip Worthington III** (Cape money laundering via a heritage marina; performative hard-Rs), **Lady Beatrice “Lady” Borden** (Fall River dynasty on Second Street; the “Acquitted” thread), **the Fake Kennedys** (Hyannisport grifter clan).

### Real landmarks (build/reference these)
Seamen’s Bethel (Whaleman’s Chapel, 15 Johnny Cake Hill) + Whaling Museum + Mariner’s Home + U.S. Custom House + Double Bank Building + Rodman Candleworks (New Bedford historic district); the working **fish pier**, State Pier, Co-op/Homer’s/Fisherman’s Wharf; **Palmer’s Island Lighthouse**; the **Hurricane Barrier**. In Fall River: **Lizzie Borden House (230 Second St)**, **Battleship Cove / USS *Massachusetts***, **St. Anne’s** basilica, the **Braga Bridge**. **“Maplecroft”** — the notorious axe-murder B&B safehouse in the Highlands, where Vinny sleeps to clear wanted level and save.

### Mission arc (MissionManager)
- **Vertical slice — “Off the Boat”:** Vinny’s arrival at the **New Sefton (New Bedford) fish pier**; meet Deacon Mealy at Seamen’s Bethel; the auction deal turns; **fish-pier ambush**; **high-speed coastal-fog getaway**; first safehouse validation.
- **Act I — Whaling City (New Bedford):** strong-arm Sully Brangwynne’s collectors; earn the South End Crew (a lowrider run; a Feast of the Blessed Sacrament favor); take a wharf → first owned property/income; boss: break Sully’s grip on the harbor.
- **Act II — Spindle City (Fall River):** cross the Verde/Braga Bridge into the Flint; broker with the Azorean Syndicate; **“Acquitted”** — the Lady Borden heist/cover-up at the Second Street manor; **“The Undefeated”** — train with Iron Mike at **Champion City Gym (Brockmore)**, a fixed fight you can throw or win; boss: dismantle Lady Borden’s hold on the Highlands.
- **Act III — The Cape & the Storm:** infiltrate Chip Worthington’s **heritage marina** laundering; long-con the **Fake Kennedys**; **the “Gloria” Event** — mid/late hurricane set-piece (homage to the ’85 storm) that floods low roads, **alters the map**, and sinks boats — a chaos heist during the storm; finale at **Battleship Cove** aboard the USS *Massachusetts*: take the harbor for good, or lose everything.

### “The Sidelines” (optional side-missions & activities)
Property empire (bars, wharves, the gym, a marina) with daily income; boat-smuggling runs with Marisol (Coast Guard heat); street races over the bridges; the **boxing circuit**; **“The Undefeated”** (Champion City Gym, Brockton) and **“Acquitted”** (Borden legacy, Fall River) story threads; Lizzie Borden ghost-tour caper; clam-shack delivery time-trials; radio call-ins where Buddy Mello reacts to your rampages.

### Original 8-phase development order (for reference / scoping)
1. Core engine & data backbone (wallet, persistence, WeatherController↔friction).
2. Macro world graybox (4 districts, canal bridges), weather-aware vehicle physics, acquisition markers.
3. Subsystems & soundscapes (RevenueManager, ChopShopArmsManager, RadioManager).
4. Scripted progression & **vertical slice** (MissionManager + the fish-pier debut loop).
5. Living city & AI (traffic splines, pedestrian states, turf bounds).
6. Combat, consequences & **Heat** (dual-axis wanted, weapon feel, safehouses).
7. Voice, dialect & “The Sidelines” (dialect engine, radio host integration, side threads).
8. UI, polish & the coastal vibe (HUD/radar w/ lighthouse sweeps, Coastal Neon post-processing, the **“Gloria”** event).

*All studios, characters, factions, stations, and most place-branding are fictional; real places and historical/parody figures (e.g., the Borden legacy) are used satirically. Not affiliated with Rockstar/Take-Two. Map data © OpenStreetMap contributors; photoreal imagery © Google.*

