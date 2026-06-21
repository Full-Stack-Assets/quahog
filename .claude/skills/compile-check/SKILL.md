---
name: compile-check
description: Compile-check and unit-test the Unity C# gameplay scripts headlessly in this sandbox (no Unity needed). Use after editing any script under QUAHOG_Unity/Assets/Scripts, before committing or shipping a zip, to catch syntax/type/signature errors and logic regressions. Also use when asked to "compile", "build", "type-check", "verify", or "test" the C#/Unity code.
---

# Compile-check the Unity scripts

The gameplay scripts can't be built by Unity here, but they CAN be type-checked
and partially run via a Roslyn + `UnityEngine` shim toolchain in `tools/csharp/`.

## Steps

1. **Type-check everything** (installs the .NET SDK on first run in a session):
   ```bash
   tools/csharp/compile-check.sh
   ```
   - On `=== Compile check OK ===`, the code compiles.
   - On errors, read each `error CSxxxx`. There are two kinds:
     - **A real bug in the gameplay script** → fix the script under
       `QUAHOG_Unity/Assets/Scripts/`.
     - **A missing `UnityEngine` member** the project legitimately uses (the shim
       just doesn't declare it yet) → add a minimal stub to
       `tools/csharp/shim/UnityEngineShim.cs` (a property/method returning a
       default, an enum value, etc.), then re-run. Match the real Unity signature.
   - Re-run until green.

2. **Run the logic tests** (GeoJSON parsing, ear-clipping, GIS city build):
   ```bash
   tools/csharp/run-tests.sh
   ```
   Must end with `N passed, 0 failed`. If you changed GIS / parsing / geometry
   code, add or update assertions in `tools/csharp/tests/Program.cs`.

## Rules
- This is a **type + logic** gate, not a runtime/visual one. A green result does
  NOT prove physics/rendering/input behaviour — say so when reporting.
- Keep the C# language version at 9 (Unity 6). Don't raise it to make code pass.
- Never put the shim or `tools/csharp/` inside `QUAHOG_Unity/Assets` — Unity
  would try to compile it and collide with the real engine types.
- Always run this before committing script changes or sending the user a build zip.
