import { useEffect, useRef } from "react";
import { useFrame } from "@react-three/fiber";
import { useStats } from "../game";
import { useGame } from "../store";
import { useEconomy } from "../economy";
import { useToasts } from "../store";
import { consumeTap } from "../input";
import { shared } from "../shared";
import { sfx } from "../audio/sfx";

const DAY_SECONDS = 600; // matches DayNight's cycle length

// Runs the always-on gameplay loops (§15): heat decay + periodic autosave, and
// loads the saved game on mount. Also handles global hotkeys (weather, pause).
export function GameSystems() {
  const acc = useRef(0);
  const prevStars = useRef(0);
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
    const st = useStats.getState();
    // passive business revenue (§15 RevenueManager)
    const income = useEconomy.getState().incomePerSec(DAY_SECONDS);
    if (income > 0) st.addCash(income * dt);
    // slow health regen out of combat (§11)
    if (st.health > 0 && st.health < 100 && useGame.getState().mode === "foot") st.setHealth(st.health + dt * 2.2);
    // wanted-up sting (§23): toast + chirp when police stars rise
    const stars = Math.floor(st.police);
    if (stars > prevStars.current) { useToasts.getState().push(`WANTED ${"★".repeat(stars)}`, "#6cb6ff"); sfx.bust(); }
    prevStars.current = stars;
    st.decay(dt);
    acc.current += dt;
    if (acc.current > 20) { acc.current = 0; st.save(); }
  });
  return null;
}
