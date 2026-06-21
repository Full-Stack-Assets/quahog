import { useRef } from "react";
import { useFrame } from "@react-three/fiber";
import { shared } from "../shared";
import { useStats } from "../game";
import { useGame } from "../store";

// Busted / Wasted loop (§15): health at zero = WASTED; cornered by police on
// foot = BUSTED. Either way the player blacks out, loses some cash + all heat,
// and respawns at a safe location with restored health.

const RESPAWN: [number, number, number] = [-256.2, 3, 106.5]; // near the Bethel
const DELAY = 2.8; // seconds blacked out before respawn

export function Consequence() {
  const timer = useRef(0);

  useFrame((_, dt) => {
    const game = useGame.getState();
    const stats = useStats.getState();

    // trigger wasted when health is gone
    if (!game.down && stats.health <= 0) {
      useGame.getState().setDown("wasted");
      timer.current = 0;
    }
    if (!game.down) return;

    timer.current += dt;
    if (timer.current < DELAY) return;

    // respawn
    const penalty = game.down === "wasted" ? 200 : 150;
    stats.addCash(-Math.min(stats.cash, penalty));
    stats.setHealth(100);
    stats.heat(-9, -9); // clamp both axes to 0

    const pl = shared.player;
    if (pl) {
      pl.setEnabled(true);
      pl.setTranslation({ x: RESPAWN[0], y: RESPAWN[1], z: RESPAWN[2] }, true);
      pl.setLinvel({ x: 0, y: 0, z: 0 }, true);
    }
    useGame.getState().setMode("foot");
    useGame.getState().setDown(null);
    timer.current = 0;
  });

  return null;
}
