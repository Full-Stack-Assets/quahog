import { create } from "zustand";

// Mission engine (§16). Missions are ordered lists of steps; each step completes
// on reaching a world target and/or being in a car, and may pay a reward.
// Missions chain: finishing one starts the next.

export interface MissionStep {
  text: string;
  target?: [number, number, number]; // world position to reach
  radius?: number;
  needCar?: boolean; // also requires being in a vehicle
  noHeat?: boolean;  // also requires police heat cleared (lose the cops first)
  reward?: number;   // cash on completing this step
}
interface Mission { title: string; steps: MissionStep[] }

// World coords: x = east, z = -north (slice-local).
const MISSIONS: Mission[] = [
  // --- Opener -------------------------------------------------------------
  {
    title: "Off the Boat",
    steps: [
      { text: "Meet Deacon Mealy at Seamen's Bethel", target: [-272.23, 0, 106.5], radius: 10 },
      { text: "The auction soured — steal a car at Reggie's signal", needCar: true, reward: 100 },
      { text: "Shake the cops and lie low at the safehouse", target: [-188, 0, 40], radius: 12, noHeat: true, reward: 500 },
    ],
  },
  // --- Act I — The Whaling City (New Bedford) ------------------------------
  {
    title: "Auction Rules",
    steps: [
      { text: "Grab a car — Sully's collectors are working the docks", needCar: true },
      { text: "Lean on the collectors at the Quohog Republic", target: [-240, 0, 122], radius: 16, needCar: true },
      { text: "Cool the car at Reggie's Anvil Garage", target: [-320, 0, 60], radius: 14, noHeat: true, reward: 700 },
    ],
  },
  {
    title: "The Linguiça Run",
    steps: [
      { text: "Grab a car", needCar: true },
      { text: "Pick up the package at Off the Hook (Long Island)", target: [6092, 0, 4485], radius: 16, needCar: true },
      { text: "Run it downtown to the Quohog Republic", target: [-240, 0, 122], radius: 16, reward: 900 },
    ],
  },
  {
    title: "Harbor Heat",
    steps: [
      { text: "Hit Sully's count house — grab a fast car", needCar: true },
      { text: "Lose the cops, then go to ground at the safehouse", target: [-188, 0, 40], radius: 12, noHeat: true, reward: 1200 },
    ],
  },
  // --- Act II — Spindle City (Fall River) ---------------------------------
  {
    title: "Spindle City",
    steps: [
      { text: "Take I-195 west over the Braga Bridge", target: [-19000, 0, -7000], radius: 60, needCar: true },
      { text: "Case Battleship Cove for Lady Borden's people", target: [-20000, 0, -7400], radius: 40, reward: 1500 },
    ],
  },
  {
    title: "Acquitted",
    steps: [
      { text: "Meet the Lady's man at the Borden House on Second St", target: [-19599, 0, -7080], radius: 18, needCar: true },
      { text: "Run the ledger to Battleship Cove — and lose the tail", target: [-20000, 0, -7400], radius: 40, noHeat: true, reward: 2000 },
    ],
  },
];

interface MissionState {
  mi: number;
  steps: MissionStep[];
  step: number;
  done: boolean;
  title: string;
  objective: string;
  advance: () => void;
  reset: () => void;
}

export const useMission = create<MissionState>((set, get) => ({
  mi: 0,
  steps: MISSIONS[0].steps,
  step: 0,
  done: false,
  title: MISSIONS[0].title,
  objective: MISSIONS[0].steps[0].text,
  advance: () => {
    const { mi, step, steps } = get();
    const next = step + 1;
    if (next < steps.length) { set({ step: next, objective: steps[next].text }); return; }
    // mission finished — chain to the next, or end the campaign
    const nm = mi + 1;
    if (nm < MISSIONS.length) {
      set({ mi: nm, steps: MISSIONS[nm].steps, step: 0, title: MISSIONS[nm].title, objective: MISSIONS[nm].steps[0].text });
    } else {
      set({ step: next, done: true, objective: "Campaign complete — Mount Hope is yours." });
    }
  },
  reset: () => set({ mi: 0, steps: MISSIONS[0].steps, step: 0, done: false, title: MISSIONS[0].title, objective: MISSIONS[0].steps[0].text }),
}));
