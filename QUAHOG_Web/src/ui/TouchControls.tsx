import { useEffect, useRef, useState } from "react";
import { setVirtualMove, virtualTap } from "../input";
import { useGame } from "../store";

// On-screen controls for phones/tablets (§25 touch): a left thumb-stick that
// feeds the movement axis + action buttons that inject taps. Every control can
// be dragged (move) and resized in EDIT mode (⚙); the layout persists.

const KEY = "mounthope.touchlayout.v2";

type Ctl = { left: number; top: number; size: number };
type Layout = Record<string, Ctl>;

const MIN = { stick: 90, btn: 44 };
const MAX = { stick: 230, btn: 130 };

function defaults(vw: number, vh: number): Layout {
  const big = 76, sm = 60, stick = 130;
  const ex = vw - 22 - big, ey = vh - 28 - big;
  const firex = ex - 12 - sm;
  return {
    stick: { left: 24, top: vh - 24 - stick, size: stick },
    e: { left: ex, top: ey, size: big },
    fire: { left: firex, top: vh - 28 - sm, size: sm },
    f: { left: ex + (big - sm) / 2, top: ey - 12 - sm, size: sm },
    v: { left: ex + (big - sm) / 2, top: ey - 12 - sm - 12 - sm, size: sm },
    g: { left: firex, top: vh - 28 - sm - 12 - sm, size: sm },
  };
}

const clamp = (n: number, lo: number, hi: number) => Math.max(lo, Math.min(hi, n));

export function TouchControls() {
  const [touch, setTouch] = useState(false);
  const [editing, setEditing] = useState(false);
  const [layout, setLayout] = useState<Layout | null>(null);
  const [knob, setKnob] = useState({ x: 0, y: 0 });
  const mode = useGame((s) => s.mode);
  const nearCar = useGame((s) => s.nearCar);
  const armed = useGame((s) => s.armed);

  // drag state (kept in a ref so moves don't thrash)
  const drag = useRef<{ id: number; key: string; kind: "move" | "resize" | "stick"; sx: number; sy: number; orig: Ctl } | null>(null);

  useEffect(() => {
    const coarse = typeof window !== "undefined" &&
      (window.matchMedia?.("(pointer: coarse)").matches || "ontouchstart" in window);
    setTouch(!!coarse);
    if (!coarse) return;
    let init: Layout;
    try {
      const raw = localStorage.getItem(KEY);
      init = raw ? JSON.parse(raw) : defaults(window.innerWidth, window.innerHeight);
    } catch { init = defaults(window.innerWidth, window.innerHeight); }
    // backfill any missing control with a default (e.g. new buttons)
    const d = defaults(window.innerWidth, window.innerHeight);
    for (const k of Object.keys(d)) if (!init[k]) init[k] = d[k];
    setLayout(init);
  }, []);

  if (!touch || !layout) return null;

  const save = (l: Layout) => { try { localStorage.setItem(KEY, JSON.stringify(l)); } catch { /* ignore */ } };

  const moveStick = (key: string, clientX: number, clientY: number) => {
    const c = layout[key];
    const cx = c.left + c.size / 2, cy = c.top + c.size / 2;
    let dx = (clientX - cx) / (c.size / 2);
    let dy = (clientY - cy) / (c.size / 2);
    const m = Math.hypot(dx, dy);
    if (m > 1) { dx /= m; dy /= m; }
    const knobSize = c.size * 0.42;
    setKnob({ x: dx * (c.size / 2 - knobSize / 2), y: dy * (c.size / 2 - knobSize / 2) });
    setVirtualMove(dx, -dy);
  };

  const onDown = (e: React.PointerEvent, key: string, action?: string) => {
    (e.target as HTMLElement).setPointerCapture(e.pointerId);
    if (editing) {
      drag.current = { id: e.pointerId, key, kind: "move", sx: e.clientX, sy: e.clientY, orig: { ...layout[key] } };
      return;
    }
    if (key === "stick") {
      drag.current = { id: e.pointerId, key, kind: "stick", sx: 0, sy: 0, orig: layout[key] };
      moveStick(key, e.clientX, e.clientY);
    } else if (action) {
      e.preventDefault();
      virtualTap(action);
    }
  };

  const onResizeDown = (e: React.PointerEvent, key: string) => {
    e.stopPropagation();
    (e.target as HTMLElement).setPointerCapture(e.pointerId);
    drag.current = { id: e.pointerId, key, kind: "resize", sx: e.clientX, sy: e.clientY, orig: { ...layout[key] } };
  };

  const onMove = (e: React.PointerEvent) => {
    const d = drag.current;
    if (!d || d.id !== e.pointerId) return;
    if (d.kind === "stick") { moveStick(d.key, e.clientX, e.clientY); return; }
    const vw = window.innerWidth, vh = window.innerHeight;
    setLayout((prev) => {
      if (!prev) return prev;
      const c = { ...prev[d.key] };
      if (d.kind === "move") {
        c.left = clamp(d.orig.left + (e.clientX - d.sx), 0, vw - c.size);
        c.top = clamp(d.orig.top + (e.clientY - d.sy), 0, vh - c.size);
      } else {
        const lim = d.key === "stick" ? MIN.stick : MIN.btn;
        const hi = d.key === "stick" ? MAX.stick : MAX.btn;
        c.size = clamp(d.orig.size + (e.clientX - d.sx + e.clientY - d.sy) / 2, lim, hi);
      }
      return { ...prev, [d.key]: c };
    });
  };

  const onUp = (e: React.PointerEvent) => {
    const d = drag.current;
    if (!d || d.id !== e.pointerId) return;
    if (d.kind === "stick") { setKnob({ x: 0, y: 0 }); setVirtualMove(0, 0); }
    else save(layout);
    drag.current = null;
  };

  const editBox = (k: string): React.CSSProperties =>
    editing ? { outline: "2px dashed #ffcf4a", outlineOffset: 2 } : {};

  const resizeHandle = (k: string) =>
    editing ? (
      <div
        onPointerDown={(e) => onResizeDown(e, k)}
        onPointerMove={onMove}
        onPointerUp={onUp}
        style={{
          position: "absolute", right: -8, bottom: -8, width: 22, height: 22, borderRadius: "50%",
          background: "#ffcf4a", border: "2px solid #1a1304", touchAction: "none",
        }}
      />
    ) : null;

  const button = (k: string, label: string, sub: string, action: string, highlight?: boolean, big?: boolean) => {
    const c = layout[k];
    return (
      <div
        key={k}
        onPointerDown={(e) => onDown(e, k, action)}
        onPointerMove={onMove}
        onPointerUp={onUp}
        onPointerCancel={onUp}
        style={{
          position: "fixed", left: c.left, top: c.top, width: c.size, height: c.size, borderRadius: "50%",
          background: highlight ? "rgba(255,46,136,.85)" : "rgba(12,15,26,.7)",
          border: "2px solid rgba(120,110,170,.6)", color: "#fff", zIndex: 16, touchAction: "none",
          fontFamily: "'Courier New', monospace", fontWeight: 700, lineHeight: 1,
          display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 2,
          ...editBox(k),
        }}
      >
        <span style={{ fontSize: big ? c.size * 0.3 : c.size * 0.32 }}>{label}</span>
        <span style={{ fontSize: Math.max(8, c.size * 0.15), opacity: 0.8 }}>{sub}</span>
        {resizeHandle(k)}
      </div>
    );
  };

  const stick = layout.stick;
  const knobSize = stick.size * 0.42;

  return (
    <>
      {/* movement thumb-stick */}
      <div
        onPointerDown={(e) => onDown(e, "stick")}
        onPointerMove={onMove}
        onPointerUp={onUp}
        onPointerCancel={onUp}
        style={{
          position: "fixed", left: stick.left, top: stick.top, width: stick.size, height: stick.size, borderRadius: "50%",
          background: "rgba(12,15,26,.4)", border: "2px solid rgba(120,110,170,.5)", zIndex: 16, touchAction: "none",
          ...editBox("stick"),
        }}
      >
        <div style={{
          position: "absolute", left: stick.size / 2 - knobSize / 2 + knob.x, top: stick.size / 2 - knobSize / 2 + knob.y,
          width: knobSize, height: knobSize, borderRadius: "50%",
          background: "rgba(255,122,217,.6)", border: "2px solid rgba(255,255,255,.5)",
        }} />
        {resizeHandle("stick")}
      </div>

      {/* action buttons */}
      {button("e", "E", mode === "car" ? "exit" : nearCar ? "steal" : "enter", "KeyE", nearCar, true)}
      {button("f", mode === "car" ? "⎋" : "👊", mode === "car" ? "exit" : "punch", "KeyF")}
      {button("v", "V", "view", "KeyV")}
      {button("g", "G", "gun", "KeyG", armed)}
      {button("fire", "🔫", "fire", "Mouse0", armed)}

      {/* edit toggle */}
      <button
        onClick={() => { setEditing((v) => { if (v) save(layout); return !v; }); }}
        style={{
          position: "fixed", left: 8, top: "50%", transform: "translateY(-50%)", zIndex: 17,
          width: 44, height: 44, borderRadius: "50%", touchAction: "manipulation",
          background: editing ? "rgba(255,207,74,.9)" : "rgba(12,15,26,.7)",
          border: "2px solid rgba(120,110,170,.6)", color: editing ? "#1a1304" : "#fff", fontSize: 18,
        }}
        title="Edit touch layout"
      >{editing ? "✓" : "⚙"}</button>

      {editing && (
        <div style={{
          position: "fixed", top: 12, left: "50%", transform: "translateX(-50%)", zIndex: 17,
          background: "rgba(12,15,26,.9)", border: "1px solid #3a2a5e", borderRadius: 8, padding: "8px 14px",
          color: "#e7e0ff", fontFamily: "'Courier New', monospace", fontSize: 12, textAlign: "center",
        }}>
          Drag controls to move · drag the gold handle to resize · ✓ when done
          <div style={{ marginTop: 6 }}>
            <button
              onClick={() => { const d = defaults(window.innerWidth, window.innerHeight); setLayout(d); save(d); }}
              style={{ cursor: "pointer", background: "rgba(40,30,70,.9)", border: "1px solid #5a4a8e", color: "#e7e0ff", borderRadius: 6, padding: "4px 10px", font: "11px 'Courier New', monospace" }}
            >Reset to default</button>
          </div>
        </div>
      )}
    </>
  );
}
