import { useEffect, useState } from "react";
import { useGame } from "./store";
import { useStats } from "./game";
import { useMission } from "./mission";
import { useEconomy, BUSINESSES } from "./economy";
import { shared } from "./shared";

const wrap: React.CSSProperties = {
  position: "fixed",
  inset: 0,
  pointerEvents: "none",
  fontFamily: "'Courier New', monospace",
  color: "#e7e0ff",
};

const stars = (n: number) => "★".repeat(Math.round(n)) + "☆".repeat(Math.max(0, 5 - Math.round(n)));

export function HUD({ sliceName }: { sliceName: string }) {
  const mode = useGame((s) => s.mode);
  const nearCar = useGame((s) => s.nearCar);
  const cash = useStats((s) => s.cash);
  const health = useStats((s) => s.health);
  const police = useStats((s) => s.police);
  const faction = useStats((s) => s.faction);
  const objective = useMission((s) => s.objective);
  const missionTitle = useMission((s) => s.title);
  const missionDone = useMission((s) => s.done);
  const armed = useGame((s) => s.armed);
  const weapon = useGame((s) => s.weapon);
  const down = useGame((s) => s.down);
  const near = useEconomy((s) => s.near);
  const owned = useEconomy((s) => s.owned);
  const ownedCount = Object.keys(owned).length;
  const [hhmm, setHhmm] = useState("09:00");
  const [stamina, setStamina] = useState(100);
  const [dist, setDist] = useState<number | null>(null);
  useEffect(() => {
    const id = setInterval(() => {
      const h = Math.floor(shared.hour);
      const m = Math.floor((shared.hour - h) * 60);
      setHhmm(`${String(h).padStart(2, "0")}:${String(m).padStart(2, "0")}`);
      setStamina(shared.stamina);
      // distance to the active objective
      const ms = useMission.getState();
      const step = ms.done ? null : ms.steps[ms.step];
      const body = useGame.getState().mode === "car" ? shared.car : shared.player;
      const t = body?.translation();
      if (step?.target && t) setDist(Math.round(Math.hypot(t.x - step.target[0], t.z - step.target[2])));
      else setDist(null);
    }, 200);
    return () => clearInterval(id);
  }, []);

  const hurt = Math.max(0, (40 - health) / 40); // 0 healthy → 1 near-death

  return (
    <div style={wrap}>
      {/* busted / wasted overlay (§15) */}
      {down && (
        <div
          style={{
            position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center",
            background: down === "wasted" ? "rgba(60,0,0,.62)" : "rgba(0,10,40,.62)",
          }}
        >
          <div style={{
            fontSize: 64, fontWeight: 900, letterSpacing: 6,
            color: down === "wasted" ? "#ff5c5c" : "#6cb6ff",
            textShadow: "0 2px 18px rgba(0,0,0,.8)",
          }}>
            {down === "wasted" ? "WASTED" : "BUSTED"}
          </div>
        </div>
      )}

      {/* aiming reticle when armed on foot */}
      {armed && !down && (
        <div style={{ position: "absolute", left: "50%", top: "50%", transform: "translate(-50%,-50%)", width: 22, height: 22 }}>
          <div style={{ position: "absolute", left: 10, top: 0, width: 2, height: 22, background: "rgba(255,207,74,.85)" }} />
          <div style={{ position: "absolute", top: 10, left: 0, width: 22, height: 2, background: "rgba(255,207,74,.85)" }} />
        </div>
      )}

      {/* low-health damage vignette (§23) */}
      {hurt > 0 && (
        <div
          style={{
            position: "absolute", inset: 0, pointerEvents: "none",
            boxShadow: `inset 0 0 ${120 + hurt * 140}px rgba(170,10,10,${0.25 + hurt * 0.45})`,
            transition: "box-shadow .2s linear",
          }}
        />
      )}

      {/* status panel (top-right under the radio is fine; use top-center-right) */}
      <div
        style={{
          position: "absolute", top: 14, right: 240,
          background: "rgba(12,15,26,.7)", border: "1px solid #3a2a5e",
          borderRadius: 8, padding: "8px 12px", textAlign: "right", minWidth: 150,
        }}
      >
        <div style={{ color: "#7CFC00", fontWeight: 700, fontSize: 15 }}>${Math.floor(cash).toLocaleString()}</div>
        {ownedCount > 0 && <div style={{ fontSize: 10, opacity: 0.8 }}>🏠 {ownedCount}/{BUSINESSES.length} fronts</div>}
        <div style={{ fontSize: 11, opacity: 0.85, marginTop: 2 }}>🕑 {hhmm}</div>
        <div style={{ fontSize: 12, marginTop: 4 }}>
          <span title="police" style={{ color: "#6cb6ff" }}>{stars(police)}</span>
        </div>
        <div style={{ fontSize: 12 }}>
          <span title="faction heat" style={{ color: "#ff5c5c" }}>{stars(faction)}</span>
        </div>
        <div style={{ marginTop: 4, height: 6, background: "#3a2a3a", borderRadius: 3, overflow: "hidden" }}>
          <div style={{ width: `${health}%`, height: "100%", background: health > 30 ? "#4ad66d" : "#e23b3b" }} />
        </div>
        {armed && <div style={{ fontSize: 11, marginTop: 4, color: "#ffcf4a" }}>🔫 {weapon.toUpperCase()}</div>}
        {stamina < 99.5 && (
          <div style={{ marginTop: 4, height: 4, background: "#2a2a3a", borderRadius: 2, overflow: "hidden" }}>
            <div style={{ width: `${stamina}%`, height: "100%", background: "#5ad0ff" }} />
          </div>
        )}
      </div>

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
          <b>WASD</b> move &nbsp;·&nbsp; {mode === "car" ? <><b>Space</b> handbrake</> : <><b>Shift</b> sprint</>} &nbsp;·&nbsp; <b>E</b> {mode === "car" ? "exit car" : "enter car"}
          <br />
          <b>F</b> punch &nbsp;·&nbsp; <b>V</b> view &nbsp;·&nbsp; <b>[ ]</b> radio
          <br />
          <b>R</b> weather &nbsp;·&nbsp; <b>P</b>/<b>Esc</b> pause
          <br />
          <b>C</b> character &nbsp;·&nbsp; <b>M</b> map
          <br />
          <b>G</b> draw &nbsp;·&nbsp; <b>1/2/3</b> fists/pistol/shotgun &nbsp;·&nbsp; <b>click</b> fire &nbsp;·&nbsp; <b>H</b> horn
          <br />
          mode: <b style={{ color: "#22d3ee" }}>{mode === "car" ? "DRIVING" : "ON FOOT"}</b>
        </div>
      </div>

      {/* mission objective */}
      <div
        style={{
          position: "absolute", bottom: 16, left: "50%", transform: "translateX(-50%)",
          background: "rgba(12,15,26,.72)", border: "1px solid #3a2a5e", borderRadius: 8,
          padding: "8px 16px", textAlign: "center", maxWidth: 520,
        }}
      >
        <div style={{ fontSize: 10, letterSpacing: 1, color: "#ffcf4a", opacity: 0.9 }}>
          {missionDone ? "MISSION" : missionTitle.toUpperCase()}
        </div>
        <div style={{ fontSize: 13, marginTop: 2, color: missionDone ? "#7CFC00" : "#e7e0ff" }}>
          {missionDone ? "✓ " : "► "}{objective}
          {!missionDone && dist != null && <span style={{ opacity: 0.7 }}> — {dist} m</span>}
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

      {near && (
        <div
          style={{
            position: "absolute", bottom: "27%", left: "50%", transform: "translateX(-50%)",
            background: cash >= near.cost ? "rgba(74,214,109,.9)" : "rgba(80,80,90,.9)",
            color: cash >= near.cost ? "#06210d" : "#fff",
            padding: "8px 16px", borderRadius: 6, fontWeight: 700, letterSpacing: 1, textAlign: "center",
          }}
        >
          PRESS B TO BUY {near.name.toUpperCase()} — ${near.cost.toLocaleString()}
          <div style={{ fontSize: 10, fontWeight: 400, opacity: 0.85 }}>{near.blurb} · +${near.perDay}/day</div>
        </div>
      )}

      {/* menu launchers */}
      <div style={{ position: "absolute", right: 12, bottom: 30, display: "flex", flexDirection: "column", gap: 8 }}>
        <button style={launcher} onClick={() => useGame.getState().toggleMap()} title="Map (M)">🗺</button>
        <button style={launcher} onClick={() => useGame.getState().toggleChar()} title="Character (C)">🧍</button>
        <button style={launcher} onClick={() => useGame.getState().toggleRadio()} title="Radio">📻</button>
      </div>

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

const launcher: React.CSSProperties = {
  pointerEvents: "auto", cursor: "pointer", width: 40, height: 40,
  border: "1px solid #3a2a5e", background: "rgba(12,15,26,.82)", color: "#e7e0ff",
  borderRadius: 10, fontSize: 18,
};
