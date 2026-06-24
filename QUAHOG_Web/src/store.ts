import { create } from "zustand";
import type { Slice } from "./slice";

export type Mode = "foot" | "car" | "boat";
export type View = "third" | "first";
export type Weather = "clear" | "rain" | "fog";
export type Down = null | "busted" | "wasted";
export type Weapon = "pistol" | "shotgun";
export type Melee = "fists" | "bat";

interface GameState {
  mode: Mode;
  view: View;
  nearCar: boolean;
  nearLabel: string;
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
  weapon: Weapon;
  melee: Melee;
  down: Down;
  started: boolean;
  fxOn: boolean;
  reduceShake: boolean;
  photo: boolean;
  scrimshaw: number; // collectibles found (for the HUD counter)
  waypoint: { x: number; z: number } | null; // player-placed map waypoint
  gameId: number; // bumped on New Game so per-game components can remount
  setMode: (m: Mode) => void;
  setView: (v: View) => void;
  toggleView: () => void;
  setNearCar: (v: boolean) => void;
  setNearLabel: (s: string) => void;
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
  setWeapon: (w: Weapon, drawn?: boolean) => void;
  setMelee: (m: Melee) => void;
  setDown: (d: Down) => void;
  setStarted: (v: boolean) => void;
  toggleFx: () => void;
  toggleReduceShake: () => void;
  togglePhoto: () => void;
  setScrimshaw: (n: number) => void;
  setWaypoint: (w: { x: number; z: number } | null) => void;
  resetSession: () => void; // wipe in-session gameplay flags for a fresh New Game
}

export const useGame = create<GameState>((set) => ({
  mode: "foot",
  view: "third",
  nearCar: false,
  nearLabel: "",
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
  weapon: "pistol",
  melee: "fists",
  down: null,
  started: false,
  fxOn: true,
  reduceShake: false,
  photo: false,
  scrimshaw: 0,
  waypoint: null,
  gameId: 0,
  setMode: (mode) => set({ mode }),
  setView: (view) => set({ view }),
  toggleView: () => set((s) => ({ view: s.view === "third" ? "first" : "third" })),
  setNearCar: (nearCar) => set((s) => (s.nearCar === nearCar ? s : { nearCar })),
  setNearLabel: (nearLabel) => set((s) => (s.nearLabel === nearLabel ? s : { nearLabel })),
  // Fog removed entirely (open view reads better) — cycle clear ↔ rain only.
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
  setWeapon: (weapon, drawn = true) => set({ weapon, armed: drawn }),
  setMelee: (melee) => set({ melee }),
  setDown: (down) => set({ down }),
  setStarted: (started) => set({ started }),
  toggleFx: () => set((s) => ({ fxOn: !s.fxOn })),
  toggleReduceShake: () => set((s) => ({ reduceShake: !s.reduceShake })),
  togglePhoto: () => set((s) => ({ photo: !s.photo })),
  setScrimshaw: (scrimshaw) => set({ scrimshaw }),
  setWaypoint: (waypoint) => set({ waypoint }),
  resetSession: () => set((s) => ({
    mode: "foot", armed: false, weapon: "pistol", melee: "fists", down: null,
    photo: false, weather: "clear", waypoint: null, scrimshaw: 0, gameId: s.gameId + 1,
  })),
}));

// Lightweight toast notifications (§21).
export interface Toast { id: number; text: string; color: string }
interface ToastState { items: Toast[]; push: (text: string, color?: string) => void }
let toastId = 0;
export const useToasts = create<ToastState>((set) => ({
  items: [],
  push: (text, color = "#ffcf4a") => {
    const t = { id: toastId++, text, color };
    set((s) => ({ items: [...s.items, t].slice(-4) }));
    setTimeout(() => set((s) => ({ items: s.items.filter((x) => x.id !== t.id) })), 3200);
  },
}));
