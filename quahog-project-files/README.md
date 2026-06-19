# GRAND THEFT AUTO: SOUTH COAST — Pitch Site

An unofficial fan concept and satire: *Grand Theft Auto: Vice City*, relocated to the **South Coast of Massachusetts** in 1986 — Fall River, New Bedford, Cape Cod, and Brockton.

This repo is a **static, deploy-ready website**. No build step, no dependencies.

## What's in here

```
gta-south-coast/
├── index.html                 # The hosted one-pager (Coastal Neon showpiece, interactive radio dial)
├── gta-south-coast-pitch.pdf  # The 4-page pitch sheet (linked from the page footer)
├── vercel.json                # Static config + sensible headers
├── .gitignore
├── README.md
└── docs/
    └── GAME-DESIGN-DOC.md      # The full Game Design Document
```

## Deploy to Vercel

### Option A — GitHub → Vercel (easiest on mobile)
1. Create a new repository on **github.com** (or the GitHub mobile app).
2. Upload everything in this folder (**Add file → Upload files**, then drag the contents in).
3. Go to **vercel.com → Add New → Project → Import** your repo.
4. Framework Preset: **Other**. Leave build/output empty. Click **Deploy**.

That's it — Vercel serves `index.html` at the root automatically, and every push to the repo redeploys.

### Option B — Vercel CLI (fastest with a terminal)
```bash
npm i -g vercel
cd gta-south-coast
vercel          # creates a preview deployment
vercel --prod   # promotes to production
```

### Option C — Deploy Button
Once the repo is on GitHub, paste your repo URL into this button and drop it at the top of the README:

```md
[![Deploy with Vercel](https://vercel.com/button)](https://vercel.com/new/clone?repository-url=YOUR_GITHUB_REPO_URL)
```

## Local preview
```bash
npx serve .
# or just open index.html in a browser
```

## Notes
- **Static only** — Vercel auto-detects this; there is no build command.
- Display fonts (Anton, Barlow, Space Mono) load from the Google Fonts CDN at runtime, so the live page matches the design exactly. The **PDF** has those fonts embedded, so it's fully self-contained.
- The PDF is linked from the footer of the page and served inline via `vercel.json`.

---

**Unofficial fan parody.** Not affiliated with, endorsed by, or connected to Rockstar Games or Take-Two Interactive. All studio names, locations, characters, factions, and stations are fictional. The Marchegiano storyline is an affectionate tribute to a real undefeated champion's legacy.
