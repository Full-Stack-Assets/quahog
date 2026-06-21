import { useEffect, useRef } from "react";
import { useFrame } from "@react-three/fiber";
import { useStats } from "../game";

// Runs the always-on gameplay loops (§15): heat decay + periodic autosave, and
// loads the saved game on mount.
export function GameSystems() {
  const acc = useRef(0);
  useEffect(() => { useStats.getState().load(); }, []);
  useFrame((_, dt) => {
    useStats.getState().decay(dt);
    acc.current += dt;
    if (acc.current > 20) { acc.current = 0; useStats.getState().save(); }
  });
  return null;
}
