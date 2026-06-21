import { useEffect, useRef } from "react";
import { useFrame } from "@react-three/fiber";
import { useStats } from "../game";
import { useGame } from "../store";
import { useEconomy } from "../economy";
import { useToasts } from "../store";
import { consumeTap } from "../input";
import { shared } from "../shared";
import { sfx } from "../audio/sfx";
import { radio } from "../audio/radioEngine";

const DAY_SECONDS = 600; // matches DayNight's cycle length

// Runs the always-on gameplay loops (§15): heat decay + periodic autosave, and
// loads the saved game on mount. Also handles global hotkeys (weather, pause).
export function GameSystems() {
  const acc = useRef(0);
  const prevStars = useRef(0);
  useEffect(() => {
    useStats.getState().load();
    useEconomy.getState().load();
    sfx.startAmbience();
    // restore settings (§26)
    try {
      const s = JSON.parse(localStorage.getItem("mounthope.settings.v1") || "{}");
      const g = useGame.getState();
      if (typeof s.fxOn === "boolean" && s.fxOn !== g.fxOn) g.toggleFx();
      if (typeof s.reduceShake === "boolean" && s.reduceShake !== g.reduceShake) g.toggleReduceShake();
      if (s.weather) useGame.setState({ weather: s.weather });
    } catch { /* ignore */ }
  }, []);
  useFrame((_, dt) => {
    // global hotkeys
    if (consumeTap("KeyR")) { useGame.getState().toggleWeather(); sfx.ui(); }
    if (consumeTap("KeyP") || consumeTap("Escape")) { useGame.getState().togglePause(); sfx.ui(); }
    if (consumeTap("KeyC")) { useGame.getState().toggleChar(); sfx.ui(); }
    if (consumeTap("KeyM")) { useGame.getState().toggleMap(); sfx.ui(); }
    if (consumeTap("KeyO")) { useGame.getState().togglePhoto(); sfx.ui(); }
    if (consumeTap("KeyG")) useGame.getState().toggleArmed();
    if (consumeTap("Digit1")) { const g = useGame.getState(); g.setMelee("fists"); if (g.armed) g.toggleArmed(); } // bare fists
    if (consumeTap("Digit2")) useGame.getState().setWeapon("pistol");
    if (consumeTap("Digit3")) useGame.getState().setWeapon("shotgun");
    if (consumeTap("Digit4")) { const g = useGame.getState(); g.setMelee("bat"); if (g.armed) g.toggleArmed(); } // baseball bat

    if (useGame.getState().paused) return; // freeze sim while paused
    if (shared.alarm.t > 0) shared.alarm.t = Math.max(0, shared.alarm.t - dt);
    // arrive at a player-placed waypoint → clear it (§21)
    if (shared.waypoint) {
      const b = (useGame.getState().mode === "car" ? shared.car : shared.player)?.translation();
      if (b && Math.hypot(b.x - shared.waypoint.x, b.z - shared.waypoint.z) < 9) {
        shared.waypoint = null;
        useToasts.getState().push("Waypoint reached", "#ff7ad9"); sfx.ui();
      }
    }
    const st = useStats.getState();
    // passive business revenue (§15 RevenueManager)
    const income = useEconomy.getState().incomePerSec(DAY_SECONDS);
    if (income > 0) st.addCash(income * dt);
    // slow health regen out of combat (§11)
    if (st.health > 0 && st.health < 100 && useGame.getState().mode === "foot") st.setHealth(st.health + dt * 2.2);
    // wanted-up sting (§23): toast + chirp when police stars rise
    const stars = Math.floor(st.police);
    if (stars > prevStars.current) { useToasts.getState().push(`WANTED ${"★".repeat(stars)}`, "#6cb6ff"); sfx.bust(); }
    if (stars !== prevStars.current) radio.setDuck(stars >= 3 ? 0.4 : 1); // adaptive chase mix (§19)
    prevStars.current = stars;
    st.decay(dt);
    acc.current += dt;
    if (acc.current > 20) {
      acc.current = 0;
      st.save();
      const g = useGame.getState();
      try { localStorage.setItem("mounthope.settings.v1", JSON.stringify({ fxOn: g.fxOn, reduceShake: g.reduceShake, weather: g.weather })); } catch { /* ignore */ }
    }
  });
  return null;
}
