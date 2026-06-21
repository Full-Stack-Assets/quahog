import { useRef } from "react";
import * as THREE from "three";
import { useFrame } from "@react-three/fiber";
import { shared } from "../shared";
import { useStats } from "../game";
import { useGame } from "../store";

// Safehouse (§15): a marked spot that bleeds off police + faction heat while the
// player is inside its radius, and saves the game. Mirrors the mission safehouse.

const POS: [number, number, number] = [-188, 0, 40];
const RADIUS = 9;

export function Safehouse() {
  const ring = useRef<THREE.Mesh>(null);
  const inside = useRef(false);
  const saveAcc = useRef(0);

  useFrame((_, dt) => {
    const game = useGame.getState();
    if (game.paused) return;
    const body = game.mode === "car" ? shared.car : shared.player;
    const t = body?.translation();
    const here = !!t && Math.hypot(t.x - POS[0], t.z - POS[2]) < RADIUS;
    inside.current = here;

    if (here) {
      const stats = useStats.getState();
      if (stats.police > 0 || stats.faction > 0) stats.heat(-dt * 1.2, -dt * 1.2);
      saveAcc.current += dt;
      if (saveAcc.current > 3) { saveAcc.current = 0; stats.save(); }
    }
    if (ring.current) {
      const m = ring.current.material as THREE.MeshBasicMaterial;
      m.opacity = here ? 0.75 : 0.4;
    }
  });

  return (
    <group position={POS}>
      <mesh position={[0, 2, 0]} castShadow>
        <boxGeometry args={[8, 4, 8]} />
        <meshStandardMaterial color="#3a4a6a" roughness={0.8} />
      </mesh>
      <mesh position={[0, 4.4, 0]} castShadow>
        <coneGeometry args={[6.2, 2.4, 4]} />
        <meshStandardMaterial color="#5a3a2a" roughness={0.9} />
      </mesh>
      <mesh ref={ring} rotation-x={-Math.PI / 2} position={[0, 0.15, 0]}>
        <ringGeometry args={[RADIUS - 0.6, RADIUS, 36]} />
        <meshBasicMaterial color="#4ad66d" transparent opacity={0.4} depthWrite={false} />
      </mesh>
    </group>
  );
}
