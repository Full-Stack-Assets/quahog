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

## Getting `UNITY_LICENSE` (free Personal license)

1. Add `UNITY_EMAIL` and `UNITY_PASSWORD` first (above).
2. On GitHub → **Actions** tab → **Acquire Unity Activation File** → **Run workflow**.
3. When it finishes, open the run → download the **Manual Activation File**
   artifact → unzip it. You'll get a file ending in `.alf`.
4. Go to **https://license.unity3d.com/manual**, upload the `.alf`, answer the
   couple of questions (Personal / non-commercial is fine), and download the
   `.ulf` file it gives back.
5. Open the `.ulf` in a text editor, copy **everything**, and paste it as the
   value of a new secret named **`UNITY_LICENSE`**.

> Have a paid Unity Plus/Pro plan instead? Skip the steps above. Add a
> `UNITY_SERIAL` secret with your serial key (plus `UNITY_EMAIL` /
> `UNITY_PASSWORD`) and add `UNITY_SERIAL: ${{ secrets.UNITY_SERIAL }}` to the
> Build step's `env:` in `deploy-webgl.yml`.

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
