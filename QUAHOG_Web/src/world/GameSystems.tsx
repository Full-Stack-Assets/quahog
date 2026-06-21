import { useEffect, useRef } from "react";
import { useFrame } from "@react-three/fiber";
import { useStats } from "../game";
import { useGame } from "../store";
import { consumeTap } from "../input";
import { shared } from "../shared";

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
    if (consumeTap("KeyG")) useGame.getState().toggleArmed();

    if (useGame.getState().paused) return; // freeze sim while paused
    if (shared.alarm.t > 0) shared.alarm.t = Math.max(0, shared.alarm.t - dt);
    useStats.getState().decay(dt);
    acc.current += dt;
    if (acc.current > 20) { acc.current = 0; useStats.getState().save(); }
  });
  return null;
}
