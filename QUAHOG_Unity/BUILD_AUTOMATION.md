# QUAHOG Unity — Build Automation Setup (Unity 6 + URP)

A minimal **buildable Unity 6 project** for
[Unity Build Automation](https://docs.unity.com/devops/en/manual/build-automation)
(UBA), so you can produce a downloadable build from your phone with no local editor.

> **Project is nested.** It lives in `QUAHOG_Unity/`, not the repo root (the repo
> also holds the Godot project and prototypes). In the UBA target, set the
> **project subdirectory** to `QUAHOG_Unity`.

## Layout

```
QUAHOG_Unity/
├── ProjectSettings/
│   ├── ProjectVersion.txt        # ★ Unity 6000.0.23f1 — match UBA's dropdown
│   └── EditorBuildSettings.asset  # ★ builds Assets/Scenes/Bootstrap.unity
├── Packages/manifest.json         # ★ lists URP + uGUI + core modules
├── Assets/
│   ├── Scenes/Bootstrap.unity(.meta)   # ★ proof-of-life scene; meta GUID is in the build list
│   ├── Editor/
│   │   └── QuahogBootstrap.cs(.meta)   # editor-only: configures URP + identity (see below)
│   └── Scripts/                        # each .cs has a committed .meta
│       ├── Core/Managers.cs            # Singleton<T> + core manager singletons
│       ├── Core/GameBootstrap.cs       # runtime entry point ([RuntimeInitializeOnLoadMethod])
│       ├── SceneBootstrap.cs           # validates singletons, sets prologue state
│       └── TestSceneBootstrap.cs       # builds the minimal HUD (cash + health bar)
└── .gitignore                     # ignores Library/ Temp/ Obj/ Logs/ Build/ *.csproj *.sln
```

## Render pipeline — built-in now, URP later (#7)

The first build ships on the **built-in** render pipeline. URP is in the manifest
(package present) but **not assigned** — the proof-of-life HUD is uGUI screen-overlay,
which renders regardless of pipeline, and there's no 3D content yet to go "pink". This
keeps the first UBA run low-risk.

`Assets/Editor/QuahogBootstrap.cs` is an **editor-only** script (`#if UNITY_EDITOR`,
under `Assets/Editor/`, so it never enters a player build). On load and as an
`IPreprocessBuildWithReport` pre-build step it stamps **product identity only**
(name / company / Android bundle id `com.rockwharf.quahog`) — no pipeline changes.

When you're ready to move to URP, open the project in a Unity 6 editor and run
**`QUAHOG ▸ Enable URP`**: it creates `Assets/Settings/URP-Quahog.asset` + its renderer
via URP's API and assigns them in Graphics/Quality settings. Then commit
`Assets/Settings/` and the updated `ProjectSettings/*.asset`.

## Runtime entry point

`GameBootstrap` runs via `[RuntimeInitializeOnLoadMethod]` (no scene wiring, no
`UnityEditor`), spawns the managers, runs `SceneBootstrap`, draws the HUD, seeds `$500`.
A green build logs:

```
[GameBootstrap] QUAHOG online — managers spawned, HUD up, $500 in the wallet.
[SceneBootstrap] All singletons validated successfully.
```

## Generated on first import (intentionally NOT committed)

- `Library/`, `Temp/`, `Obj/`, `*.csproj`, `*.sln` — gitignored (never commit `Library/`; it's multi-GB).
- `Packages/packages-lock.json` — let UBA resolve it on the first build, then commit the
  generated file for deterministic resolution (hand-guessing transitive versions is worse than none).
- Most of `ProjectSettings/*.asset` (Graphics, Quality, Player, Tags, Physics, …) — Unity
  writes defaults; `QuahogBootstrap` then overlays URP + identity.

## Connect Build Automation (web dashboard, phone-friendly)

1. Unity Cloud → **DevOps → Build Automation**.
2. **Link source:** connect this GitHub repo + branch.
3. **Build configuration:**
   - **Project subdirectory:** `QUAHOG_Unity` ← required (project is nested).
   - **Unity version:** match `ProjectVersion.txt` (`6000.0.23f1`) or change that file to a Unity 6 version UBA lists.
   - **Platform:** Android (`.apk`) is easiest to sideload; debug keystore is fine.
4. **Run the build**, read the log, download the artifact / share link.
5. **After the first green build:** pull the generated `Packages/packages-lock.json`
   (and, if you opened the editor, the `ProjectSettings/*.asset` + `Assets/Settings/URP-*`)
   and commit them for fully deterministic rebuilds.

## Scope note

This is a **4-script proof-of-life**, not the full game. The actual QUAHOG systems live
as **GDScript** in `QUAHOG_Godot/`; only a handful of C# files were ever provided. Porting
the real systems back to C# (the "144 .cs files, subfoldered by system") is a separate,
large effort. SQLite is **not** referenced by any committed script (the empire DB is a stub),
so no SQLite package is needed yet.
