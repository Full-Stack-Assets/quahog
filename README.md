# QUAHOG

Project QUAHOG — **Grand Theft Auto: South Coast**, an unofficial fan concept and satire of *GTA: Vice City* relocated to the South Coast of Massachusetts (Fall River, New Bedford, Cape Cod, Brockton) in 1986.

This repository holds the design/pitch materials plus two engine builds of the game:
the original Unity codebase and the in-progress Godot port.

## Contents

### `QUAHOG_Godot/`
The Godot game project (GDScript). Contains autoloads, gameplay scripts (player, vehicle,
world, traffic, AI, combat, audio, events), UI/HUD widgets, and core systems. See
[`QUAHOG_Godot/GODOT_SETUP.md`](QUAHOG_Godot/GODOT_SETUP.md) for setup instructions.

### `QUAHOG_Unity/`
The Unity engine project (C#, namespace `Quahog.SouthCoast`). A minimal buildable project
set up for [Unity Build Automation](QUAHOG_Unity/BUILD_AUTOMATION.md): a code-driven
`GameBootstrap` spawns the manager singletons and a minimal HUD with no scene wiring.
Engine development plans live in [`QUAHOG_Unity/plans/`](QUAHOG_Unity/plans/).

### `prototypes/`
Standalone runnable prototypes. `Quahog3D.html` is a self-contained offline 3D prototype
(Three.js/WebGL) you can open directly in a phone or desktop browser.

### `quahog-project-files/`
Design and pitch materials:
- `gta-south-coast_2.html` — the static pitch one-pager (deploy-ready, no build step)
- `GTA-South-Coast-GDD.md` — the full Game Design Document
- `vercel.json` — static hosting config
- PDFs — pitch sheet, master plan, technical blueprints, and system design docs

See [`quahog-project-files/README.md`](quahog-project-files/README.md) for deployment details.

---

**Unofficial fan parody.** Not affiliated with, endorsed by, or connected to Rockstar Games or Take-Two Interactive. All studio names, locations, characters, factions, and stations are fictional.
