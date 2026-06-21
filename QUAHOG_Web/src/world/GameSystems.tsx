import { useEffect, useRef } from "react";
import { useFrame } from "@react-three/fiber";
import { useStats } from "../game";
import { useGame } from "../store";
import { useEconomy } from "../economy";
import { consumeTap } from "../input";
import { shared } from "../shared";
import { sfx } from "../audio/sfx";

const DAY_SECONDS = 600; // matches DayNight's cycle length

// Runs the always-on gameplay loops (§15): heat decay + periodic autosave, and
// loads the saved game on mount. Also handles global hotkeys (weather, pause).
export function GameSystems() {
  const acc = useRef(0);
  useEffect(() => { useStats.getState().load(); useEconomy.getState().load(); sfx.startAmbience(); }, []);
  useFrame((_, dt) => {
    // global hotkeys
    if (consumeTap("KeyR")) useGame.getState().toggleWeather();
    if (consumeTap("KeyP") || consumeTap("Escape")) useGame.getState().togglePause();
    if (consumeTap("KeyC")) useGame.getState().toggleChar();
    if (consumeTap("KeyM")) useGame.getState().toggleMap();
    if (consumeTap("KeyG")) useGame.getState().toggleArmed();
    if (consumeTap("Digit1") && useGame.getState().armed) useGame.getState().toggleArmed(); // fists
    if (consumeTap("Digit2")) useGame.getState().setWeapon("pistol");
    if (consumeTap("Digit3")) useGame.getState().setWeapon("shotgun");

    if (useGame.getState().paused) return; // freeze sim while paused
    if (shared.alarm.t > 0) shared.alarm.t = Math.max(0, shared.alarm.t - dt);
    // passive business revenue (§15 RevenueManager)
    const income = useEconomy.getState().incomePerSec(DAY_SECONDS);
    if (income > 0) useStats.getState().addCash(income * dt);
    useStats.getState().decay(dt);
    acc.current += dt;
    if (acc.current > 20) { acc.current = 0; useStats.getState().save(); }
  });
  return null;
}
