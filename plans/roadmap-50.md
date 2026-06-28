# Mount Hope — next 50 tasks

Curated, prioritized roadmap after the driving/water/graphics fixes. Worked top
to bottom; each batch is verified with a clean `--export-release "Web"` before
commit. Checkboxes flip as they land.

## A. Driving & vehicles
1. [ ] Water is non-drivable — cars/player can't cross the harbor (collision or slow/stop zone).
2. [x] Car model faces its travel direction (no rear-first driving).
3. [x] Camera collision — chase cam doesn't clip through buildings.
4. [x] Brake vs reverse feel + handbrake.
5. [x] Flip/stuck recovery (right the car if overturned or wedged).
6. [ ] Horn (button + SFX).
7. [x] Headlights on at night.
8. [x] Speedometer correctness (km/h) + needle.
9. [x] Per-model handling spread (mass/grip/top speed).
10. [x] Minimap shows player heading + nearby cars.

## B. World realism
11. [ ] Open-ocean water beyond the rivers (coastline → Buzzards/Mount Hope Bay).
12. [ ] Stop signs / traffic signals at major intersections (visual).
13. [x] Street lights along roads (geometry + night emission).
14. [x] Trees / greenery instanced in parks & wooded overlays.
15. [ ] Sidewalk coverage refinement (curbs, crosswalks).
16. [ ] Bridges over water (Braga, Coggeshall) drive correctly.
17. [ ] Rooftop variation (AC units, parapets) on big buildings.
18. [x] In-world landmark signage / labels.
19. [ ] Beaches: sand + waterline blend.
20. [ ] Rail lines visual + level crossings.

## C. Graphics & lighting
21. [ ] Night window emission on buildings.
22. [ ] Smooth day/night sky transition.
23. [ ] Animated water ripples (shader) + sun glint.
24. [ ] Façade UV scale = one window row per floor.
25. [ ] Distance fade / LOD for far tiles.
26. [x] Directional shadow cascade + bias tuning.
27. [ ] Baked-ish vertex AO on buildings (compat-safe).
28. [ ] Rain: puddle sheen + wet roads.
29. [x] Car headlights/taillights geometry.
30. [x] Per-time-of-day colour grade.

## D. Audio
31. [ ] Ambient city soundscape (gulls near water, traffic hum).
32. [ ] Radio station IDs between tracks.
33. [ ] Surface-aware footsteps.
34. [ ] Weapon/impact audio polish.
35. [ ] Ocean/wave ambient near the waterfront.

## E. Gameplay & systems
36. [ ] Job/mission flow polish (markers, objectives, completion).
37. [ ] Police/wanted system re-enable + tuning (off by cheat now).
38. [ ] Pedestrian NPCs on sidewalks.
39. [ ] A few enterable interiors (shop/diner).
40. [ ] Save/load slots + settings persistence.
41. [ ] Economy loop (earn/spend).
42. [ ] Big-map markers for missions/shops.
43. [ ] Weapon wheel / inventory UI.
44. [ ] Health/armor pickups in the world.
45. [ ] Time-of-day affects traffic/ped density.

## F. Performance & tech
46. [ ] Streaming radius + per-frame build budget tuning.
47. [ ] 200-car pool perf pass (dormancy/instancing).
48. [ ] Web VRAM/texture-compression tuning.
49. [ ] On-screen error/telemetry overlay for web debugging.
50. [ ] Loading-screen progress + faster first paint.
