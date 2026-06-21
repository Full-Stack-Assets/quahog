import { useEffect, useRef } from "react";
import * as THREE from "three";
import { useFrame } from "@react-three/fiber";
import { Vehicle } from "../earth/Vehicles";
import { shared, type Cop } from "../shared";
import { useStats } from "../game";
import { useGame } from "../store";

// Police pursuit (§14): cop cars spawn as the police-heat axis climbs and home
// in on the player. Ram/contact drains health; cornering the player on foot
// makes the arrest (busted). Cops can be shot (gun queues cop.dmg).

const MAX_COPS = 3;
const SPEED = 17;        // m/s pursuit speed
const SPAWN_DIST = 85;   // where new units appear, out of sight
const COP_HP = 3;

interface Unit {
  active: boolean;
  pos: THREE.Vector3;
  yaw: number;
  hp: number;
  deadT: number;
  arrest: number;
  car: Cop;
}

export function Police() {
  const refs = useRef<(THREE.Group | null)[]>([]);
  const lightL = useRef<(THREE.Mesh | null)[]>([]);
  const lightR = useRef<(THREE.Mesh | null)[]>([]);
  const units = useRef<Unit[]>(
    Array.from({ length: MAX_COPS }, () => ({
      active: false,
      pos: new THREE.Vector3(),
      yaw: 0,
      hp: COP_HP,
      deadT: 0,
      arrest: 0,
      car: { pos: new THREE.Vector3(9999, 0, 9999), dmg: 0, dead: true } as Cop,
    })),
  );

  useEffect(() => {
    shared.cops = units.current.map((u) => u.car);
    return () => { shared.cops = []; };
  }, []);

  useFrame((_, dt) => {
    const game = useGame.getState();
    if (game.paused || game.down) return;
    const stats = useStats.getState();
    const police = stats.police;
    const target = (game.mode === "car" ? shared.car : shared.player)?.translation();

    // how many units should be chasing right now
    const desired = police >= 2 ? Math.min(MAX_COPS, Math.floor(police)) : 0;
    let activeCount = units.current.filter((u) => u.active && u.hp > 0).length;

    units.current.forEach((u, i) => {
      const g = refs.current[i];
      if (!g) return;

      // dead → fade out, then free the slot
      if (u.hp <= 0) {
        u.deadT -= dt;
        u.car.dead = true;
        g.visible = u.deadT > 0;
        if (u.deadT <= 0) u.active = false;
        return;
      }

      // (de)spawn to match desired count
      if (!u.active && activeCount < desired && target) {
        const a = Math.random() * Math.PI * 2;
        u.pos.set(target.x + Math.cos(a) * SPAWN_DIST, 0, target.z + Math.sin(a) * SPAWN_DIST);
        u.active = true; u.hp = COP_HP; u.arrest = 0; u.car.dead = false; u.car.dmg = 0;
        activeCount++;
      }
      if (u.active && activeCount > desired && u.arrest < 0.01) {
        // drop the furthest extra unit when heat cools
        u.active = false; u.car.dead = true; g.visible = false; activeCount--;
        return;
      }
      if (!u.active || !target) { g.visible = false; return; }

      // apply queued gun damage
      if (u.car.dmg > 0) { u.hp -= u.car.dmg; u.car.dmg = 0; if (u.hp <= 0) { u.deadT = 1.2; stats.addCash(75); stats.heat(-0.4, 0); } }

      // home toward the player
      const dx = target.x - u.pos.x, dz = target.z - u.pos.z;
      const d = Math.hypot(dx, dz) || 1;
      u.pos.x += (dx / d) * SPEED * dt;
      u.pos.z += (dz / d) * SPEED * dt;
      u.yaw = Math.atan2(dx, dz);
      u.car.pos.copy(u.pos);

      g.visible = true;
      g.position.copy(u.pos);
      g.rotation.y = u.yaw;

      // consequences of being caught
      if (d < 4) stats.setHealth(stats.health - dt * 10); // ram/contact damage
      if (d < 2.8 && game.mode === "foot") {
        u.arrest += dt;
        if (u.arrest > 1.2) useGame.getState().setDown("busted");
      } else {
        u.arrest = Math.max(0, u.arrest - dt);
      }

      // flashing lightbar
      const phase = Math.sin(performance.now() * 0.012 + i) > 0;
      if (lightL.current[i]) (lightL.current[i]!.material as THREE.MeshStandardMaterial).emissiveIntensity = phase ? 3 : 0.1;
      if (lightR.current[i]) (lightR.current[i]!.material as THREE.MeshStandardMaterial).emissiveIntensity = phase ? 0.1 : 3;
    });
  });

  return (
    <group>
      {units.current.map((_, i) => (
        <group key={i} ref={(el) => (refs.current[i] = el)} visible={false}>
          <Vehicle type="infiniti" color="#1a2a55" />
          {/* roof lightbar */}
          <mesh ref={(el) => (lightL.current[i] = el)} position={[-0.28, 1.7, -0.1]}>
            <boxGeometry args={[0.3, 0.14, 0.3]} />
            <meshStandardMaterial color="#ff2a2a" emissive="#ff2a2a" emissiveIntensity={2} />
          </mesh>
          <mesh ref={(el) => (lightR.current[i] = el)} position={[0.28, 1.7, -0.1]}>
            <boxGeometry args={[0.3, 0.14, 0.3]} />
            <meshStandardMaterial color="#2a5aff" emissive="#2a5aff" emissiveIntensity={2} />
          </mesh>
        </group>
      ))}
    </group>
  );
}
