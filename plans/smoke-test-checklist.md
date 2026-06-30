# The Narrows — smoke test checklist (Godot Web)

Run after each meaningful build. Export must pass: `cd QUAHOG_GODOT1 && bash build_web.sh`

## Boot & menu
- [ ] Title screen loads without console errors
- [ ] **NEW GAME** starts the world
- [ ] **CONTINUE** resumes saved position (if save exists)

## On foot
- [ ] Virtual joystick / WASD moves the player
- [ ] Camera look (drag right side / mouse)
- [ ] Sprint, jump, crouch respond
- [ ] Enter a shop and buy ammo (if cash allows)

## Driving
- [ ] Walk to a parked car → **CAR** / `E` enters
- [ ] Stick **up** accelerates forward; **down** reverses
- [ ] Handbrake slows / drifts
- [ ] Horn (`H` / HORN button) sounds
- [ ] Exit car works

## Combat & heat
- [ ] Pick up pistol / shotgun / rifle / bat
- [ ] Fire weapon; ammo decreases; reload works
- [ ] Gunfire raises wanted stars (police not disabled)
- [ ] Cops spawn and chase; arrest = busted fine
- [ ] Wanted decays when hidden

## World systems
- [ ] Driving into harbor water → sink + recover on land
- [ ] Pay-n-Spray clears heat for $200 (with stars, in zone)
- [ ] Delivery job: accept → pickup → dropoff → cash
- [ ] **Off the Boat** opener objectives advance (new game)

## UI & audio
- [ ] Minimap shows streets + blips
- [ ] Big map opens; fast travel works
- [ ] Radio plays and switches stations
- [ ] Speedometer visible while driving

## Persistence
- [ ] Autosave / Continue restores position and cash
- [ ] New Game resets opener mission flag
