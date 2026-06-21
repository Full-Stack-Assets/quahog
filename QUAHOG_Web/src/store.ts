import { create } from "zustand";
import type { Slice } from "./slice";

export type Mode = "foot" | "car";
export type View = "third" | "first";
export type Weather = "clear" | "rain";
export type Down = null | "busted" | "wasted";

interface GameState {
  mode: Mode;
  view: View;
  nearCar: boolean;
  weather: Weather;
  paused: boolean;
  slice: Slice | null;
  radioOpen: boolean;
  charOpen: boolean;
  mapOpen: boolean;
  playerTint: string;
  playerCarType: string;
  playerCarColor: string;
  armed: boolean;
  down: Down;
  setMode: (m: Mode) => void;
  setView: (v: View) => void;
  toggleView: () => void;
  setNearCar: (v: boolean) => void;
  toggleWeather: () => void;
  togglePause: () => void;
  setPaused: (p: boolean) => void;
  setSlice: (s: Slice) => void;
  toggleRadio: () => void;
  toggleChar: () => void;
  toggleMap: () => void;
  setPlayerTint: (c: string) => void;
  setPlayerCar: (type: string, color: string) => void;
  toggleArmed: () => void;
  setDown: (d: Down) => void;
}

export const useGame = create<GameState>((set) => ({
  mode: "foot",
  view: "third",
  nearCar: false,
  weather: "clear",
  paused: false,
  slice: null,
  radioOpen: true,
  charOpen: false,
  mapOpen: false,
  playerTint: "#ffffff",
  playerCarType: "mustang",
  playerCarColor: "#b81d24",
  armed: false,
  down: null,
  setMode: (mode) => set({ mode }),
  setView: (view) => set({ view }),
  toggleView: () => set((s) => ({ view: s.view === "third" ? "first" : "third" })),
  setNearCar: (nearCar) => set((s) => (s.nearCar === nearCar ? s : { nearCar })),
  toggleWeather: () => set((s) => ({ weather: s.weather === "clear" ? "rain" : "clear" })),
  togglePause: () => set((s) => ({ paused: !s.paused })),
  setPaused: (paused) => set({ paused }),
  setSlice: (slice) => set({ slice }),
  toggleRadio: () => set((s) => ({ radioOpen: !s.radioOpen })),
  toggleChar: () => set((s) => ({ charOpen: !s.charOpen })),
  toggleMap: () => set((s) => ({ mapOpen: !s.mapOpen })),
  setPlayerTint: (playerTint) => set({ playerTint }),
  setPlayerCar: (playerCarType, playerCarColor) => set({ playerCarType, playerCarColor }),
  toggleArmed: () => set((s) => ({ armed: !s.armed })),
  setDown: (down) => set({ down }),
}));
