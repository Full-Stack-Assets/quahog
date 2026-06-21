import { useEffect, useRef } from "react";
import { useFrame } from "@react-three/fiber";
import { useStats } from "../game";
import { useGame } from "../store";
import { consumeTap } from "../input";

// Runs the always-on gameplay loops (§15): heat decay + periodic autosave, and
// loads the saved game on mount. Also handles global hotkeys (weather, pause).
export function GameSystems() {
  const acc = useRef(0);
  useEffect(() => { useStats.getState().load(); }, []);
  useFrame((_, dt) => {
    // global hotkeys
    if (consumeTap("KeyR")) useGame.getState().toggleWeather();
    if (consumeTap("KeyP") || consumeTap("Escape")) useGame.getState().togglePause();
    if (consumeTap("KeyC")) useGame.getState().toggleChar();
    if (consumeTap("KeyM")) useGame.getState().toggleMap();

    if (useGame.getState().paused) return; // freeze sim while paused
    useStats.getState().decay(dt);
    acc.current += dt;
    if (acc.current > 20) { acc.current = 0; useStats.getState().save(); }
  });
  return null;
}
