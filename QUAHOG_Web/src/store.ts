import { create } from "zustand";

export type Mode = "foot" | "car";

interface GameState {
  mode: Mode;
  nearCar: boolean;
  setMode: (m: Mode) => void;
  setNearCar: (v: boolean) => void;
}

export const useGame = create<GameState>((set) => ({
  mode: "foot",
  nearCar: false,
  setMode: (mode) => set({ mode }),
  setNearCar: (nearCar) => set((s) => (s.nearCar === nearCar ? s : { nearCar })),
}));
