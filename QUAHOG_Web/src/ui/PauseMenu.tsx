import { useGame } from "../store";
import { useStats } from "../game";
import { useMission } from "../mission";

// Pause / settings overlay (§26). Opens on Esc/P (handled in GameSystems).
// Freezes the sim loops and exposes quick settings + a save reset.

const btn: React.CSSProperties = {
  display: "block",
  width: "100%",
  margin: "6px 0",
  padding: "10px 14px",
  background: "rgba(40,30,70,.9)",
  border: "1px solid #5a4a8e",
  borderRadius: 8,
  color: "#e7e0ff",
  fontFamily: "'Courier New', monospace",
  fontSize: 14,
  letterSpacing: 1,
  cursor: "pointer",
};

export function PauseMenu() {
  const paused = useGame((s) => s.paused);
  const view = useGame((s) => s.view);
  const weather = useGame((s) => s.weather);
  if (!paused) return null;

  return (
    <div
      style={{
        position: "fixed", inset: 0, zIndex: 20,
        display: "flex", alignItems: "center", justifyContent: "center",
        background: "rgba(6,8,16,.66)", backdropFilter: "blur(2px)",
      }}
    >
      <div
        style={{
          width: 320, padding: 22,
          background: "rgba(12,15,26,.95)", border: "1px solid #3a2a5e", borderRadius: 14,
          textAlign: "center",
        }}
      >
        <div style={{ color: "#ff7ad9", fontWeight: 700, letterSpacing: 3, fontFamily: "'Courier New', monospace", fontSize: 20 }}>
          PAUSED
        </div>
        <div style={{ color: "#9a93b8", fontSize: 11, marginBottom: 14, fontFamily: "'Courier New', monospace" }}>
          MOUNT HOPE
        </div>

        <button style={btn} onClick={() => useGame.getState().setPaused(false)}>▶ Resume</button>
        <button style={btn} onClick={() => useGame.getState().toggleView()}>
          View: {view === "first" ? "First-person" : "Third-person"}
        </button>
        <button style={btn} onClick={() => useGame.getState().toggleWeather()}>
          Weather: {weather === "rain" ? "Rain" : "Clear"}
        </button>
        <button
          style={{ ...btn, borderColor: "#8e3a3a", color: "#ffb0b0" }}
          onClick={() => {
            useStats.getState().reset();
            useMission.getState().reset();
            useGame.getState().setPaused(false);
          }}
        >
          ⟲ Reset progress
        </button>

        <div style={{ color: "#6a6486", fontSize: 10, marginTop: 12, fontFamily: "'Courier New', monospace" }}>
          Esc / P to resume · R toggles rain
        </div>
      </div>
    </div>
  );
}
