#!/usr/bin/env node
// Scan public/music/<station>/ and write a manifest.json into each station
// folder listing its audio files. Zero dependencies. Run it after dropping in
// new MP3s (or let `prebuild`/`predev` run it automatically — see package.json).
//
//   node scripts/gen_manifests.mjs
//
// Output per station, e.g. public/music/whale/manifest.json:
//   { "station": "whale", "tracks": ["track1.mp3","track2.mp3"], "generatedAt": "…" }
//
// The radio (src/audio/radioEngine.ts) reads music/<station>/manifest.json and
// plays the listed tracks, falling back to the procedural synth when none exist.

import { readdirSync, writeFileSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const HERE = dirname(fileURLToPath(import.meta.url));
const MUSIC_DIR = join(HERE, "..", "public", "music");
const AUDIO = /\.(mp3|m4a|aac|ogg|wav)$/i;

function main() {
  let entries;
  try {
    entries = readdirSync(MUSIC_DIR, { withFileTypes: true });
  } catch {
    console.log(`(no ${MUSIC_DIR} yet — create public/music/<station>/ and drop MP3s in)`);
    process.exit(0); // not an error: nothing to do
  }

  const stations = entries.filter((e) => e.isDirectory());
  let total = 0;

  for (const s of stations) {
    const dir = join(MUSIC_DIR, s.name);
    const tracks = readdirSync(dir)
      .filter((f) => AUDIO.test(f))
      // natural sort so track2 comes before track10
      .sort((a, b) => a.localeCompare(b, undefined, { numeric: true, sensitivity: "base" }))
      // URL-encode so spaces/accents in filenames fetch correctly
      .map((f) => encodeURIComponent(f));

    const manifest = { station: s.name, tracks, generatedAt: new Date().toISOString() };
    writeFileSync(join(dir, "manifest.json"), JSON.stringify(manifest, null, 2) + "\n");
    console.log(`  [${s.name}] ${tracks.length} track(s) → manifest.json`);
    total += tracks.length;
  }

  console.log(`✓ ${total} track(s) across ${stations.length} station(s).`);
}

main();
