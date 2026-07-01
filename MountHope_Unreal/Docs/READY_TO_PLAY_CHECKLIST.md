# Ready-to-Play Delivery Checklist

Use this checklist to decide whether the Unreal build is player-ready. A build
that misses any critical item is still a prototype, not a complete playable
delivery.

## Critical launch requirements

- Packaged Windows PC build launches from an executable.
- No Unreal Editor install is required by the player.
- New Game starts a playable session.
- Pause menu can resume, show controls, adjust basic settings, and quit.
- Known issues and controls are documented with the build.
- No missing asset references, blocking map-load errors, or startup crashes.

## Critical gameplay requirements

- Player can walk, sprint, rotate camera, collide with world geometry, and
  interact with nearby actors.
- Player can enter, drive, stop, damage, exit, and re-enter at least one vehicle.
- Vehicle handling is tuned for heavy cinematic feel rather than toy-like
  acceleration or weightless steering.
- At least one mission is polished from start to completion.
- Mission has intro dialogue, objective tracking, driving, objective action,
  completion dialogue, reward, and post-mission state.
- Cash balance is visible, changes after rewards/costs, and has at least one
  meaningful use.
- Save/checkpoint flow preserves core progress during normal play.
- Free-roam remains available after the mission.

## Critical world requirements

- Map uses real OSM-derived Massachusetts road/water/building data as its base.
- Streets, sidewalks/paths, intersections, lots, and collision are playable.
- Authored fictionalization improves pacing without erasing the real-world base.
- District includes at least one polished mission hub and several explorable
  surrounding blocks.
- Ambient pedestrians, traffic or parked vehicles, lights, signs, and audio make
  the district feel inhabited.

## Critical presentation requirements

- UE5 lighting, post-process, weather/atmosphere, and materials target cinematic
  realism.
- Roads, buildings, vehicles, and characters are coherent in scale and style.
- Audio includes vehicle sounds, ambience, UI feedback, mission cues, and
  dialogue/music placeholders or final safe assets.
- UI covers title/start, objective tracker, dialogue/subtitles, interaction
  prompt, cash, pause/settings, and save/checkpoint feedback.
- Keyboard/mouse and gamepad are both usable.

## Expanded feature targets

- Police/wanted loop supports crimes, pursuit/search, cooldown, fine/bribe, and
  escalation. **C++ done:** `UMHWantedSubsystem` reports crimes (traffic/theft/
  assault/property damage/mission heat), decays over time, and exposes a
  suggested fine; `AMHVehiclePawn` reports crashes into other actors. **Still
  needed:** actual cop-car pursuit AI/spawning (no AI pawn exists yet).
- Reputation tracks standing with local crews, police, businesses, and community
  contacts. **C++ done:** `UMHReputationSubsystem` is now read/written by
  mission steps and `AMHShopActor` discounts.
- Safehouse supports saving, vehicle storage, mission planning, and money stash.
  **C++ done:** `AMHSafehouseActor` saves + sets next-session spawn + clears
  wanted state. **Still needed:** vehicle storage and a money stash (a
  separate balance from carried cash) are not modeled.
- Shops/services include garage repair and at least one purchase interaction.
  **C++ done:** `AMHShopActor` (`Garage` repairs the nearest damaged vehicle;
  `GeneralStore` buys a linked business).
- Side content includes at least one optional activity or collectible loop.
  **C++ done:** `UMHCollectibleSubsystem` + `AMHCollectibleActor`, 8 scrimshaw
  items in `Data/Collectibles/vertical_slice.json`.
- Dialogue supports speaker names, subtitles, skippable lines, and mission barks.
  Done via `UMHDialogueSubsystem`/`AMHDialogueNpcActor` (speaker + subtitles +
  `AdvanceConversation` to skip).
- World simulation includes time-of-day or weather if feasible. Weather done
  (`AMHWeatherDirectorActor`, mission-driven via `weatherOnStart`); no
  time-of-day/day-night cycle yet (see Godot/Web tracks' `TimeOfDayClock` for
  reference if this is prioritized next).
- A radio system with a real station/DJ/song roster
  (`UMHRadioSubsystem` + `Data/Radio/stations.json`) — station cycling wired
  to player input (`R` while driving) and the HUD; actual audio playback needs
  editor-side `USoundWave` import (see `IMPROVEMENT_PLAN.md`).
- Performance is stable enough for a smooth first-player experience.
