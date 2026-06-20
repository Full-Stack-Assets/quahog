# WebGL CI/CD — auto-build & auto-publish

Goal: every push to `claude/extract-into-repo-b738b0` builds the Unity WebGL
player on GitHub's servers and publishes it to the live URL automatically — no
UBA, no zips, no manual steps.

Live URL: **https://full-stack-assets.github.io/quahog/**

There are two workflows:
- `.github/workflows/deploy-webgl.yml` — the build + deploy pipeline.
- `.github/workflows/unity-activation.yml` — a one-time helper to get a license file.

You only have to do the setup below **once**.

---

## What you need to add: 3 repository secrets

Go to the repo on GitHub → **Settings → Secrets and variables → Actions →
New repository secret**, and add:

| Secret name      | Value                                              |
|------------------|----------------------------------------------------|
| `UNITY_EMAIL`    | The email you log into Unity with                  |
| `UNITY_PASSWORD` | Your Unity account password                        |
| `UNITY_LICENSE`  | The **contents** of your `.ulf` license file (steps below) |

> These are encrypted and only exposed to the build job. No one (including me)
> can read them back.

---

## Getting `UNITY_LICENSE` (free Personal license — via Unity Hub)

Unity now requires **Personal** licenses to be activated through **Unity Hub**.
The old web-based `.alf → .ulf` activation flow is closed, so this is a one-time
local step. (You need Hub on *some* computer once; you can uninstall it after.)

1. Install **Unity Hub**: https://unity.com/download
2. Open Hub and **sign in** with your Unity account. Hub activates a free
   Personal license automatically (you do **not** need to install an editor).
3. Find the activated license file `Unity_lic.ulf`:
   - **Windows:** `C:\ProgramData\Unity\Unity_lic.ulf`
   - **macOS:** `/Library/Application Support/Unity/Unity_lic.ulf`
   - **Linux:** `~/.local/share/unity3d/Unity/Unity_lic.ulf`
4. Open it in a text editor, copy **everything**, and paste it as the value of a
   new secret named **`UNITY_LICENSE`**.

> **Paid Unity Plus/Pro plan?** Easier — skip Hub. Add a `UNITY_SERIAL` secret
> with your serial key (plus `UNITY_EMAIL` / `UNITY_PASSWORD`) and add
> `UNITY_SERIAL: ${{ secrets.UNITY_SERIAL }}` to the Build step's `env:` in
> `deploy-webgl.yml`.

---

## Make sure Pages points at the right place (one-time)

Repo → **Settings → Pages**:
- **Source:** Deploy from a branch
- **Branch:** `gh-pages` · **/(root)** · Save

(The pipeline pushes the built player to `gh-pages` on every run, so Pages just
serves whatever the latest build produced.)

---

## That's it

Once the three secrets exist:
- **Push to the branch → it builds → it deploys.** Check progress under the
  **Actions** tab. First build is ~20–30 min (no cache); later builds are faster.
- You can also trigger a build by hand: **Actions → Build & Deploy WebGL →
  Run workflow**.

### Notes
- The build runs the project's pre-build hook, which sets WebGL **Decompression
  Fallback** so the player loads on Pages without special server headers.
- The Unity version comes from `QUAHOG_Unity/ProjectSettings/ProjectVersion.txt`.
  If GitHub can't find a matching editor image, bump that file to a published
  Unity 6 version and push again.
- Private repos consume Actions minutes (WebGL builds are long). Public repos
  build for free.
