# Path C: The Gloria — 5-Phase Hurricane Event + Missions + Polish

## The Gloria Event (5 phases, ~10 minutes)

### Phase 1: Warning (2 min)
- EmergencyBroadcastSystem overrides all radio with EAS tone
- WeatherController transitions to CoastalRain
- DJChatter plays "batten down the hatches" line
- NPCs start walking faster, some head indoors
- LighthouseBeam speeds up rotation

### Phase 2: Peak (5 min)
- WeatherController.ForceState(Noreaster)
- FloodSystem.StartRising() — water rises 0.5 units/sec
- VehicleController.SetWeatherFriction(Noreaster) — 0.45x traction
- BoatSinkSystem.StartSinking() for all boats in water
- NavMeshFloodModifier.CarveFloodArea() — low zones become unwalkable
- EmergencyBroadcastSystem plays "seek higher ground" loop
- Street lights flicker, particles intensify

### Phase 3: Aftermath (3 min)
- FloodSystem.StartReceding() — water recedes 0.2 units/sec
- WeatherController transitions to Clear
- EmergencyBroadcastSystem.BroadcastAllClear()
- NavMeshFloodModifier.RestoreNavMesh()
- NPCs emerge from buildings (Investigating state)
- Property damage assessment (some yields reduced)

### Phase 4: Recovery
- Player can help repair damaged properties
- ChopShopArmsManager restocked (storm scavenging)
- New sideline mission: "Gloria Survivor" (photo document damage)

## Files to Create
1. **GloriaSequence.cs** — Master orchestrator (like PrologueSequence)
2. **GloriaWarningPhase.cs** — EAS + radio override + NPC behavior change
3. **GloriaPeakPhase.cs** — Flood + sink + NavMesh carve + friction
4. **GloriaAftermathPhase.cs** — Recede + all-clear + damage assess

## Files to Modify
5. GloriaEventDirector.cs — Wire to real systems
6. EmergencyBroadcastSystem.cs — Radio override
7. WeatherVisualEffects.cs — Lightning intensity during peak
8. FloodSystem.cs — Integration with scene water plane
9. MissionManager.cs — Add "Gloria Survivor" sideline mission

## Bonus: More Mission Implementations
10. Implement 5 more missions with objectives and triggers
11. Add mission reward system (cash + property unlock)

## Bonus: Polish
12. Screen shake during Gloria peak
13. Wind audio effect
14. Damage decals on buildings post-storm
