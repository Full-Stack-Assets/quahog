import { create } from "zustand";
import type { Slice } from "./slice";

export type Mode = "foot" | "car";
export type View = "third" | "first";
export type Weather = "clear" | "rain";

interface GameState {
  mode: Mode;
  view: View;
  nearCar: boolean;
  weather: Weather;
  paused: boolean;
  slice: Slice | null;
  setMode: (m: Mode) => void;
  setView: (v: View) => void;
  toggleView: () => void;
  setNearCar: (v: boolean) => void;
  toggleWeather: () => void;
  togglePause: () => void;
  setPaused: (p: boolean) => void;
  setSlice: (s: Slice) => void;
}

export const useGame = create<GameState>((set) => ({
  mode: "foot",
  view: "third",
  nearCar: false,
  weather: "clear",
  paused: false,
  slice: null,
  setMode: (mode) => set({ mode }),
  setView: (view) => set({ view }),
  toggleView: () => set((s) => ({ view: s.view === "third" ? "first" : "third" })),
  setNearCar: (nearCar) => set((s) => (s.nearCar === nearCar ? s : { nearCar })),
  toggleWeather: () => set((s) => ({ weather: s.weather === "clear" ? "rain" : "clear" })),
  togglePause: () => set((s) => ({ paused: !s.paused })),
  setPaused: (paused) => set({ paused }),
  setSlice: (slice) => set({ slice }),
}));
