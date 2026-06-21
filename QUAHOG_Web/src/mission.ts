import { create } from "zustand";

// Minimal mission engine (§16). A mission is an ordered list of steps; each step
// completes on reaching a world target and/or being in a car. The runner advances
// steps and the HUD shows the current objective.

export interface MissionStep {
  text: string;
  target?: [number, number, number]; // world position to reach
  radius?: number;
  needCar?: boolean; // also requires being in a vehicle
  reward?: number; // cash on completing this step
}

interface MissionState {
  steps: MissionStep[];
  step: number;
  done: boolean;
  title: string;
  objective: string;
  advance: () => void;
  reset: () => void;
}

// World coords: x = east, z = -north (slice-local). Bethel ≈ (-272, 0, 106).
const OFF_THE_BOAT: MissionStep[] = [
  { text: "Meet Deacon Mealy at Seamen's Bethel", target: [-272.23, 0, 106.5], radius: 10 },
  { text: "The deal soured — steal a car", needCar: true, reward: 100 },
  { text: "Shake the heat — reach the safehouse", target: [-188, 0, 40], radius: 12, reward: 500 },
];

export const useMission = create<MissionState>((set, get) => ({
  steps: OFF_THE_BOAT,
  step: 0,
  done: false,
  title: "Off the Boat",
  objective: OFF_THE_BOAT[0].text,
  advance: () => {
    const { step, steps } = get();
    const next = step + 1;
    if (next >= steps.length) {
      set({ step: next, done: true, objective: "Mission complete — welcome to Mount Hope." });
    } else {
      set({ step: next, objective: steps[next].text });
    }
  },
  reset: () => set({ step: 0, done: false, objective: OFF_THE_BOAT[0].text }),
}));
