import { create } from "zustand";

// Property / business empire (§15 AcquisitionEngine + RevenueManager, §17 economy).
// Buy fronts around the city; owned fronts trickle income into the wallet.

export interface Business {
  id: string;
  name: string;
  blurb: string;
  pos: [number, number, number];
  cost: number;
  perDay: number; // income per in-game day
}

// Original SouthCoast fronts (parody flavour, original names).
export const BUSINESSES: Business[] = [
  { id: "anvil", name: "The Anvil Garage", blurb: "chop shop", pos: [-320, 0, 60], cost: 500, perDay: 220 },
  { id: "quohog", name: "Quohog Republic", blurb: "dockside bar", pos: [-240, 0, 122], cost: 800, perDay: 320 },
  { id: "linq", name: "Linguiça Linq", blurb: "all-night diner", pos: [-300, 0, 92], cost: 650, perDay: 260 },
  { id: "marealta", name: "Maré Alta Records", blurb: "record shop", pos: [-262, 0, 60], cost: 700, perDay: 280 },
  { id: "whalingcab", name: "Whaling City Cab", blurb: "taxi depot", pos: [-220, 0, 176], cost: 900, perDay: 360 },
];

const KEY = "mounthope.economy.v1";

interface EconomyState {
  owned: Record<string, true>;
  near: Business | null;
  buy: (b: Business) => void; // assumes affordability checked by caller
  setNear: (b: Business | null) => void;
  incomePerSec: (daySeconds: number) => number;
  save: () => void;
  load: () => void;
}

export const useEconomy = create<EconomyState>((set, get) => ({
  owned: {},
  near: null,
  buy: (b) => set((s) => ({ owned: { ...s.owned, [b.id]: true } })),
  setNear: (b) => set((s) => (s.near?.id === b?.id ? s : { near: b })),
  incomePerSec: (daySeconds) => {
    const { owned } = get();
    let perDay = 0;
    for (const b of BUSINESSES) if (owned[b.id]) perDay += b.perDay;
    return perDay / daySeconds;
  },
  save: () => { try { localStorage.setItem(KEY, JSON.stringify(get().owned)); } catch { /* ignore */ } },
  load: () => { try { const r = localStorage.getItem(KEY); if (r) set({ owned: JSON.parse(r) }); } catch { /* ignore */ } },
}));
