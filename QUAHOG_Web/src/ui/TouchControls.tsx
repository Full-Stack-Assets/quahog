import { useEffect, useRef, useState } from "react";
import { setVirtualMove, virtualTap } from "../input";
import { useGame } from "../store";

// On-screen controls for phones/tablets (§25 touch): a left thumb-stick that
// feeds the movement axis and right-side action buttons that inject taps.
// Rendered only on coarse-pointer (touch) devices.

const KNOB = 54;
const BASE = 130;

export function TouchControls() {
  const [touch, setTouch] = useState(false);
  const mode = useGame((s) => s.mode);
  const nearCar = useGame((s) => s.nearCar);
  const baseRef = useRef<HTMLDivElement>(null);
  const [knob, setKnob] = useState({ x: 0, y: 0 });
  const active = useRef<number | null>(null);

  useEffect(() => {
    const coarse = typeof window !== "undefined" &&
      (window.matchMedia?.("(pointer: coarse)").matches || "ontouchstart" in window);
    setTouch(!!coarse);
  }, []);

  if (!touch) return null;

  const onMove = (clientX: number, clientY: number) => {
    const el = baseRef.current;
    if (!el) return;
    const r = el.getBoundingClientRect();
    const cx = r.left + r.width / 2;
    const cy = r.top + r.height / 2;
    let dx = (clientX - cx) / (BASE / 2);
    let dy = (clientY - cy) / (BASE / 2);
    const m = Math.hypot(dx, dy);
    if (m > 1) { dx /= m; dy /= m; }
    setKnob({ x: dx * (BASE / 2 - KNOB / 2), y: dy * (BASE / 2 - KNOB / 2) });
    setVirtualMove(dx, -dy); // screen-down is negative forward
  };
  const reset = () => { active.current = null; setKnob({ x: 0, y: 0 }); setVirtualMove(0, 0); };

  return (
    <>
      {/* movement thumb-stick */}
      <div
        ref={baseRef}
        onPointerDown={(e) => { active.current = e.pointerId; (e.target as HTMLElement).setPointerCapture(e.pointerId); onMove(e.clientX, e.clientY); }}
        onPointerMove={(e) => { if (active.current === e.pointerId) onMove(e.clientX, e.clientY); }}
        onPointerUp={reset}
        onPointerCancel={reset}
        style={{
          position: "fixed", left: 24, bottom: 24, width: BASE, height: BASE, borderRadius: "50%",
          background: "rgba(12,15,26,.4)", border: "2px solid rgba(120,110,170,.5)", zIndex: 16,
          touchAction: "none",
        }}
      >
        <div style={{
          position: "absolute", left: BASE / 2 - KNOB / 2 + knob.x, top: BASE / 2 - KNOB / 2 + knob.y,
          width: KNOB, height: KNOB, borderRadius: "50%",
          background: "rgba(255,122,217,.6)", border: "2px solid rgba(255,255,255,.5)",
        }} />
      </div>

      {/* action buttons */}
      <div style={{ position: "fixed", right: 22, bottom: 28, display: "flex", flexDirection: "column", alignItems: "flex-end", gap: 12, zIndex: 16 }}>
        <div style={{ display: "flex", gap: 12 }}>
          <Btn label="V" sub="view" onTap={() => virtualTap("KeyV")} />
          <Btn label={mode === "car" ? "⎋" : "👊"} sub={mode === "car" ? "exit" : "punch"} onTap={() => virtualTap("KeyF")} />
        </div>
        <Btn
          label="E"
          sub={mode === "car" ? "exit" : nearCar ? "steal" : "enter"}
          big
          highlight={nearCar}
          onTap={() => virtualTap("KeyE")}
        />
      </div>
    </>
  );
}

function Btn({ label, sub, onTap, big, highlight }: { label: string; sub: string; onTap: () => void; big?: boolean; highlight?: boolean }) {
  const d = big ? 76 : 60;
  return (
    <button
      onPointerDown={(e) => { e.preventDefault(); onTap(); }}
      style={{
        width: d, height: d, borderRadius: "50%", touchAction: "none",
        background: highlight ? "rgba(255,46,136,.85)" : "rgba(12,15,26,.7)",
        border: "2px solid rgba(120,110,170,.6)", color: "#fff",
        fontFamily: "'Courier New', monospace", fontWeight: 700, lineHeight: 1,
        display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 2,
      }}
    >
      <span style={{ fontSize: big ? 22 : 18 }}>{label}</span>
      <span style={{ fontSize: 9, opacity: 0.8 }}>{sub}</span>
    </button>
  );
}
