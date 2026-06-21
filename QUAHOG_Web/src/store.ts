import { create } from "zustand";

export type Mode = "foot" | "car";
export type View = "third" | "first";

interface GameState {
  mode: Mode;
  view: View;
  nearCar: boolean;
  setMode: (m: Mode) => void;
  setView: (v: View) => void;
  toggleView: () => void;
  setNearCar: (v: boolean) => void;
}

export const useGame = create<GameState>((set) => ({
  mode: "foot",
  view: "third",
  nearCar: false,
  setMode: (mode) => set({ mode }),
  setView: (view) => set({ view }),
  toggleView: () => set((s) => ({ view: s.view === "third" ? "first" : "third" })),
  setNearCar: (nearCar) => set((s) => (s.nearCar === nearCar ? s : { nearCar })),
}));
