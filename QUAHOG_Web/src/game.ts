import { create } from "zustand";

// Core gameplay stats (§15): wallet, health, and the dual-axis Heat system —
// Axis A = police (0..5 badges), Axis B = faction aggro (0..5). Persisted to
// localStorage.

const KEY = "mounthope.save.v1";

interface Stats {
  cash: number;
  health: number;
  police: number; // 0..5
  faction: number; // 0..5
  addCash: (n: number) => void;
  setHealth: (h: number) => void;
  heat: (police: number, faction: number) => void;
  decay: (dt: number) => void;
  save: () => void;
  load: () => void;
  reset: () => void;
}

const clamp5 = (n: number) => Math.max(0, Math.min(5, n));

export const useStats = create<Stats>((set, get) => ({
  cash: 250,
  health: 100,
  police: 0,
  faction: 0,
  addCash: (n) => set((s) => ({ cash: Math.max(0, s.cash + n) })),
  setHealth: (h) => set({ health: Math.max(0, Math.min(100, h)) }),
  heat: (p, f) => set((s) => ({ police: clamp5(s.police + p), faction: clamp5(s.faction + f) })),
  decay: (dt) =>
    set((s) =>
      s.police === 0 && s.faction === 0
        ? s
        : { police: clamp5(s.police - dt * 0.05), faction: clamp5(s.faction - dt * 0.05) },
    ),
  save: () => {
    const { cash, health, police, faction } = get();
    try { localStorage.setItem(KEY, JSON.stringify({ cash, health, police, faction })); } catch { /* ignore */ }
  },
  load: () => {
    try {
      const raw = localStorage.getItem(KEY);
      if (raw) set(JSON.parse(raw));
    } catch { /* ignore */ }
  },
  reset: () => set({ cash: 250, health: 100, police: 0, faction: 0 }),
}));
