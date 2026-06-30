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
| Dialogue | Short mission setup and world flavor barks through interactable actors. | `MHInteractable` |
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

- The level opens in Unreal and streams a playable city graybox.
- Player can walk, enter a car, drive, exit, and re-enter.
- At least one NPC starts a mission through an interaction prompt.
- Mission state changes from inactive to active to complete.
- Economy balance changes after mission completion.
- Dialogue displays at least three authored lines.
- Roads, water, and at least one landmark/blockout zone come from OSM-derived
  source data.
- Lighting, post-process, and materials target cinematic realism, even if final
  assets are placeholders.
- Runtime HUD shows objectives, dialogue, cash, and weather (`UMHGameHudWidget`).

## HUD & weather

`AMHPlayerController` spawns the game HUD at play start. Dialogue lines render
as bottom subtitles; objectives and cash/weather display in the corners. Press
`.` in PIE to cycle `EMHWeatherState` (fog/sun adjusted by `AMHWeatherDirectorActor`).

- Use Lumen, Nanite-ready assets, virtual shadow maps, and cinematic exposure.
- Favor overcast coastal realism, sodium vapor street lighting, wet asphalt,
  weathered brick, triple-decker houses, mills, diners, waterfront industry,
  pawn shops, municipal buildings, and used sedans/SUVs.
- Satire should come from characters, local institutions, radio, signage, and
  mission dialogue; visuals should stay grounded and photoreal.
