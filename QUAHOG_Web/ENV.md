# Environment variables (Vercel → projectsouthcoast → Settings → Environment Variables)

Secrets (API keys) are **never** committed. Voice IDs are public identifiers and
are recorded here for reference.

## Google Static Maps (satellite ground) — `api/staticmap.ts`
| Key | Notes |
|---|---|
| `GOOGLE_MAPS_API_KEY` | required (secret) |
| `GOOGLE_MAPS_URL_SIGNING_SECRET` | URL signing secret for the same key |

## ElevenLabs VO (radio hosts + future dialogue) — `api/tts.ts`
| Key | Value | Character / use |
|---|---|---|
| `ELEVENLABS_API_KEY` | secret | required for any VO audio |
| `ELEVENLABS_MIKE_VOICE` | `nUEpF21E0nXsKMw4L4CS` | **Shaun - Boston** → Iron Mike Fontaine (The Anvil / WBOX) |
| `ELEVENLABS_SULLY_VOICE` | _tbd_ | Sully (WHALE 92.1) |
| `ELEVENLABS_BUDDY_VOICE` | `SA7eD52NRr8WAehitVt1` | Buddy Mello (The Rage 1480) |
| `ELEVENLABS_TIA_VOICE` | _tbd_ | Tia Conceição (Maré Alta 105.3) |
| `ELEVENLABS_DEFAULT_VOICE` | _optional_ | fallback for any unmapped character key |

## ElevenLabs Music (station tracks) — `scripts/gen_music.py`
Generates royalty-free instrumental tracks (uses the same `ELEVENLABS_API_KEY`):
```
ELEVENLABS_API_KEY=sk_... python3 scripts/gen_music.py
```
Writes `public/music/<station>/track*.mp3` + `manifest.json`. The radio plays
them on the matching music station (WHALE=`whale`, Maré Alta=`mare`) and **falls
back to the procedural synth** when no tracks are present. Docs:
https://elevenlabs.io/docs/api-reference/music

## Voice value format
Value may be an ElevenLabs **voice_id** (used directly) or a voice **display name**
(resolved against your account's voice list). Missing key/voice → that host falls
back to the browser Web-Speech voice (nothing breaks).
