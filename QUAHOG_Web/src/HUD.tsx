import { useGame } from "./store";

const wrap: React.CSSProperties = {
  position: "fixed",
  inset: 0,
  pointerEvents: "none",
  fontFamily: "'Courier New', monospace",
  color: "#e7e0ff",
};

export function HUD({ sliceName }: { sliceName: string }) {
  const mode = useGame((s) => s.mode);
  const nearCar = useGame((s) => s.nearCar);

  return (
    <div style={wrap}>
      <div
        style={{
          position: "absolute",
          top: 14,
          left: 16,
          background: "rgba(12,15,26,.7)",
          border: "1px solid #3a2a5e",
          borderRadius: 8,
          padding: "10px 13px",
          maxWidth: 280,
        }}
      >
        <div style={{ color: "#ff7ad9", fontWeight: 700, letterSpacing: 2 }}>
          MOUNT HOPE
        </div>
        <div style={{ fontSize: 12, opacity: 0.75, marginTop: 2 }}>{sliceName}</div>
        <div style={{ fontSize: 12, marginTop: 8, lineHeight: 1.5 }}>
          <b>WASD</b> move &nbsp;·&nbsp; <b>E</b> {mode === "car" ? "exit car" : "enter car"}
          <br />
          mode: <b style={{ color: "#22d3ee" }}>{mode === "car" ? "DRIVING" : "ON FOOT"}</b>
        </div>
      </div>

      {mode === "foot" && nearCar && (
        <div
          style={{
            position: "absolute",
            bottom: "22%",
            left: "50%",
            transform: "translateX(-50%)",
            background: "rgba(255,46,136,.85)",
            color: "#fff",
            padding: "8px 16px",
            borderRadius: 6,
            fontWeight: 700,
            letterSpacing: 1,
          }}
        >
          PRESS E TO STEAL THE CAR
        </div>
      )}

      <div
        style={{
          position: "absolute",
          bottom: 6,
          right: 8,
          fontSize: 10,
          opacity: 0.6,
        }}
      >
        Map data © OpenStreetMap contributors, ODbL
      </div>
    </div>
  );
}
