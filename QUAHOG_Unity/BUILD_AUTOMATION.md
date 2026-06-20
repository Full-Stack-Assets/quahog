# QUAHOG Unity — Build Automation Setup (Unity 6 + URP)

A minimal **buildable Unity 6 project** for
[Unity Build Automation](https://docs.unity.com/devops/en/manual/build-automation)
(UBA), so you can produce a downloadable build from your phone with no local editor.

> **Project is nested.** It lives in `QUAHOG_Unity/`, not the repo root (the repo
> also holds the Godot project and prototypes). In the UBA target, set the
> **project subdirectory** to `QUAHOG_Unity`.

## What's committed here

```
QUAHOG_Unity/
├── ProjectSettings/
│   ├── ProjectVersion.txt        # ★ Unity 6000.0.23f1 — match UBA's dropdown
│   └── EditorBuildSettings.asset  # ★ builds Assets/Scenes/Bootstrap.unity
├── Packages/manifest.json         # ★ lists URP (com.unity.render-pipelines.universal) + uGUI
├── Assets/
│   ├── Scenes/Bootstrap.unity(.meta)   # ★ proof-of-life scene; meta GUID is in the build list
│   └── _Scripts/                       # each .cs has a committed .meta
│       ├── Core/Managers.cs            # Singleton<T> + core manager singletons
│       ├── Core/GameBootstrap.cs       # runtime entry point (see below)
│       ├── SceneBootstrap.cs           # validates singletons, sets prologue state
│       └── TestSceneBootstrap.cs       # builds the minimal HUD (cash + health bar)
└── .gitignore                     # ignores Library/ Temp/ Obj/ Logs/ Build/ *.csproj *.sln
```

`GameBootstrap` runs via `[RuntimeInitializeOnLoadMethod]` — **no scene wiring, no
`UnityEditor` usage**, so it stays in `_Scripts/` (not `Assets/Editor/`) and is safe
in a player build. It spawns the managers, runs `SceneBootstrap`, draws the HUD, and
seeds `$500`. A green build shows a cash counter + health bar and logs:

```
[GameBootstrap] QUAHOG online — managers spawned, HUD up, $500 in the wallet.
[SceneBootstrap] All singletons validated successfully.
```

## What Unity/UBA generates on first import (intentionally NOT committed)

These are machine-generated and risky to hand-author blind, so they're left for
Unity to create on the first build (UBA runs the editor in batch mode):

- `Library/`, `Temp/`, `Obj/`, `*.csproj`, `*.sln` — gitignored (never commit `Library/`; it's multi-GB).
- `Packages/packages-lock.json` — Unity resolves it. Commit it afterward for deterministic resolution.
- Most of `ProjectSettings/*.asset` (PlayerSettings, Graphics, Quality, Tags, Physics, …) — Unity writes defaults.

## URP pipeline assets — decision needed

The proof-of-life HUD is **uGUI (screen-space overlay)**, which renders independent
of the 3D render pipeline — so the **first build shows the HUD whether or not URP is
assigned**. The scene has no 3D meshes yet, so there is nothing to render "pink."

URP is listed in `manifest.json` (so the package is present), but the URP pipeline
**assets** (`Assets/Settings/URP-Quahog.asset`, its Renderer, and the
`GraphicsSettings`/`QualitySettings` assignments) are **not** committed, because a
hand-authored URP `.asset` that's subtly wrong can fail the whole import. They should
be generated once from a Unity editor (Assets → Create → Rendering → URP Asset, then
assign in Project Settings → Graphics/Quality). Until then the project uses the
built-in default pipeline, which is fine for the UI-only proof-of-life.

## Connect Build Automation (web dashboard, phone-friendly)

1. Unity Cloud → **DevOps → Build Automation**.
2. **Link source:** connect this GitHub repo + branch.
3. **Build configuration:**
   - **Project subdirectory:** `QUAHOG_Unity` ← required (project is nested).
   - **Unity version:** match `ProjectVersion.txt` (6000.0.23f1) or change that file
     to a Unity 6 version UBA lists.
   - **Platform:** Android (`.apk`) is easiest to sideload; debug keystore is fine.
   - **Scene:** `EditorBuildSettings` already lists `Bootstrap.unity` (or set a scene override).
4. **Run the build**, read the log, download the artifact / share link.

> This project has not been compiled by a Unity editor in this repo — the first UBA
> run is the verification step. SQLite is **not** referenced by any committed script
> yet (the empire DB is a stub), so no SQLite package is required.
