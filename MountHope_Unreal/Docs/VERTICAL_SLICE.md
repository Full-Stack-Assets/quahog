# Mount Hope Unreal Vertical Slice

## Creative target

Build a premium PC/console vertical slice that feels like a grounded,
photoreal, Massachusetts South Coast crime game with sharp satire and a small
thread of local Gothic unease. The tone reference is GTA-like in structure and
freedom, but the world, characters, place names, missions, and story material
must stay original.

## Map direction

Use real OSM data as the base truth, then allow controlled fictionalization:

- preserve recognizable coastline, arterial roads, neighborhoods, and civic
  landmarks where legally and creatively useful;
- compress distances when mission pacing needs it;
- rename businesses, interiors, gangs, and story-specific locations;
- author hero blocks by hand after the OSM graybox establishes scale;
- add Brockton after the first Unreal import path is proven on existing South
  Coast data.

The current repo already contains New Bedford and Fall River city data plus a
combined South Coast road mesh. Brockton should be treated as the next data
pull, not a blocker for the first Unreal slice.

## Required gameplay systems

| System | First-slice behavior | Scaffold hook |
| --- | --- | --- |
| On-foot traversal | Third-person walking, camera-relative movement, interaction input. | `MHPlayerCharacter` |
| Driving | One drivable heavy-feeling car with chase camera and enter/exit flow. | `MHVehiclePawn`, `MHPlayerCharacter::RequestEnterExitVehicle` |
| NPCs | Ambient pedestrians and mission givers; Mass AI can expand crowds later. | `MHInteractable`, Mass plugins |
| Missions | One authored mission with start, fail, complete, and reward states. | `MHMissionSubsystem` |
| Economy | Cash reward/cost loop for mission reward, repair, bribe, or item purchase. | `MHEconomySubsystem` |
| Dialogue | Mission setup, barks, subtitles, speaker names, and skippable lines. | `MHDialogueSubsystem`, `MHInteractable` |
| Police/wanted | Crime reporting, heat escalation, pursuit/search state, fines, and bribes. | `MHWantedSubsystem` |
| Reputation | Standing with crews, police, businesses, and community contacts. | `MHReputationSubsystem` |
| Save/checkpoint | Autosave payload for player, vehicle, missions, money, wanted level, and reputation. | `MHSaveGame`, `MHSaveSubsystem` |
| OSM world | Import roads/water/building blockout in Unreal centimeters. | `MHOpenWorldSubsystem` |

## Prototype mission

Working title: **Harbor Errand**

1. Player starts near a South Coast waterfront diner or garage.
2. A mission NPC asks the player to retrieve a package from a dockside contact.
3. Player enters a car, drives through OSM-derived streets, and reaches the
   contact before a timer expires.
4. A satirical dialogue exchange reveals local corruption without leaning on
   parody of any protected franchise.
5. Player returns, gets paid, and unlocks a small shop or repair interaction.
6. Optional stinger hints at older local violence or Lizzie Borden-era folklore,
   but the mission remains primarily crime/satire.

## Acceptance criteria

- A packaged PC build launches from an executable and reaches a playable world
  without editor setup.
- New game flow loads the player into an OSM-based Massachusetts city/district
  with roads, sidewalks/paths, collision, buildings, landmarks, lighting,
  explorable space, traffic, and pedestrian life.
- The core loop is complete: walk, interact, enter vehicle, drive, exit vehicle,
  complete a mission, earn cash, spend or use cash, save/checkpoint, and
  continue free-roaming.
- At least one polished story mission runs from intro dialogue through
  objective, driving segment, resolution, reward, and post-mission state.
- Driving feels heavy, cinematic, and responsive, with tuned camera,
  acceleration, braking, steering, collision, engine audio, lights, and damage
  feedback.
- NPCs include ambient pedestrians, at least one mission giver, basic reactions,
  and dialogue barks.
- Economy includes a visible cash balance, mission payout, and at least one
  meaningful money sink such as repair, bribe, shop, or safehouse use.
- UI includes title/start flow, objective tracker, dialogue/subtitles,
  interaction prompts, cash display, pause/settings, controls help, and
  save/checkpoint feedback.
- Keyboard/mouse and gamepad controls both work.
- Audio includes vehicle, ambience, UI feedback, mission stingers, and
  licensed-safe music/dialogue placeholders or final assets.
- Visuals target UE5 cinematic realism with Lumen, Nanite-ready assets,
  realistic materials, weather/atmosphere, roads, vehicles, buildings, and
  grounded character art.
- No protected GTA/Rockstar content, branding, characters, UI, missions, or
  assets are used.
- Build includes run instructions, controls, known issues, and a short gameplay
  walkthrough video.

## Desired feature set

- Third-person walking, sprinting, camera control, collision, interaction,
  animation polish, and accessible keyboard/mouse plus gamepad input.
- Heavy cinematic driving with tuned acceleration, braking, steering,
  suspension, handbrake, impacts, damage, headlights, brake lights, reverse
  lights, horn, camera shake, and vehicle audio.
- Real OSM-based Massachusetts city/district with fictionalized businesses,
  interiors, shortcuts, alleys, parking lots, industrial zones, mission spaces,
  authored hero blocks, and optional Brockton expansion.
- Ambient open-world life: pedestrians, traffic, parked cars, storefront lights,
  random events, sirens, ambient conversations, reactions, and simple schedules.
- Mission variety: delivery jobs, intimidation, investigation, chase sequences,
  getaway driving, tailing, protection jobs, debt collection, corruption
  errands, local family drama, and political satire.
- Original cast: criminals, relatives, corrupt officials, shop owners,
  mechanics, dock workers, cops, neighborhood personalities, and odd local
  legends.
- Faction/reputation behavior for local crews, police, businesses, and
  community contacts.
- Police behavior with traffic violations, foot pursuit, vehicle pursuit, search
  radius, wanted cooldown, arrests/fines, bribes, and escalating response.
- Safehouse/home base with save point, vehicle storage, wardrobe/basic
  customization, mission planning, and money stash.
- Shops and services: diner, garage, pawn shop, convenience store, mechanic,
  safehouse, and mission-specific interiors.
- Side content: street races, courier work, taxi/delivery jobs, garage repairs,
  hidden cash, local artifacts, photo spots, vehicle stashes, neighborhood
  secrets, and optional Gothic/Lizzie Borden-inspired clues.
- Dialogue polish: subtitles, speaker names, skippable lines, branching
  responses where useful, phone calls, mission banter, and ambient barks.
- Short in-engine cutscenes for intro, mission start/finish, character staging,
  and cinematic transitions.
- Progression pacing through tutorial mission, first vehicle, first payout,
  first shop purchase, first police encounter, first major contact, free-roam
  unlock, vehicles, reputation, and money.
- Options and accessibility: remappable controls, subtitles, camera sensitivity,
  audio sliders, brightness, resolution/window settings, and color-safe UI.
- Performance-ready packaging with optimized assets, reasonable load times, no
  editor-only dependencies, no missing references, and no major blocking bugs.

## Art direction notes

- Use Lumen, Nanite-ready assets, virtual shadow maps, and cinematic exposure.
- Favor overcast coastal realism, sodium vapor street lighting, wet asphalt,
  weathered brick, triple-decker houses, mills, diners, waterfront industry,
  pawn shops, municipal buildings, and used sedans/SUVs.
- Satire should come from characters, local institutions, radio, signage, and
  mission dialogue; visuals should stay grounded and photoreal.
