import { useState } from "react";
import { useGame } from "../store";
import { sfx } from "../audio/sfx";

// Title / start screen (§22). Shown over the loading world until the player
// presses Play; doubles as the first user gesture that unlocks audio.

const TIPS = [
  "WASD to move · Shift to sprint · E to grab a car.",
  "G draws your pistol — click to fire. F throws hands.",
  "Heat climbs when you cause trouble. Lay low at the safehouse.",
  "Ram a car to stop it, then jack it on foot with E.",
  "Press M for the map, C for your character, ⚙ to lay out touch controls.",
  "Buy fronts around the city (B) — they pay out every day.",
];

export function StartMenu({ sliceName }: { sliceName: string }) {
  const started = useGame((s) => s.started);
  const [tip] = useState(() => TIPS[Math.floor(Math.random() * TIPS.length)]);
  const loaded = sliceName !== "loading…";
  if (started) return null;

  return (
    <div style={{
      position: "fixed", inset: 0, zIndex: 30, display: "flex", flexDirection: "column",
      alignItems: "center", justifyContent: "center", textAlign: "center",
      background: "radial-gradient(ellipse at 50% 40%, rgba(30,20,55,.7), rgba(4,5,12,.94))",
      fontFamily: "'Courier New', monospace", color: "#e7e0ff",
    }}>
      <div style={{ fontSize: 13, letterSpacing: 8, color: "#ff7ad9", opacity: 0.9 }}>SOUTH COAST · 1986</div>
      <div style={{ fontSize: 76, fontWeight: 900, letterSpacing: 6, color: "#fff", textShadow: "0 4px 30px rgba(255,80,180,.5)", lineHeight: 1 }}>
        MOUNT HOPE
      </div>
      <div style={{ fontSize: 14, opacity: 0.7, marginTop: 8 }}>New Bedford · the Whaling City</div>

      <button
        disabled={!loaded}
        onClick={() => { sfx.setVolume(0.5); useGame.getState().setStarted(true); }}
        style={{
          marginTop: 34, padding: "14px 46px", fontFamily: "'Courier New', monospace",
          fontSize: 20, fontWeight: 700, letterSpacing: 3, cursor: loaded ? "pointer" : "wait",
          color: loaded ? "#1a1304" : "#888", background: loaded ? "#ffcf4a" : "#3a3a44",
          border: "none", borderRadius: 10,
        }}
      >{loaded ? "▶ PLAY" : "LOADING…"}</button>

      <div style={{ marginTop: 26, fontSize: 12, opacity: 0.6, maxWidth: 420 }}>TIP: {tip}</div>
      <div style={{ position: "absolute", bottom: 12, fontSize: 10, opacity: 0.5 }}>
        Map data © OpenStreetMap contributors, ODbL · An original work
      </div>
    </div>
  );
}
