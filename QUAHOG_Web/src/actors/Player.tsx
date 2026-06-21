import { useEffect, useRef } from "react";
import * as THREE from "three";
import { useFrame } from "@react-three/fiber";
import { CapsuleCollider, RigidBody, type RapierRigidBody } from "@react-three/rapier";
import { ModelCharacter } from "../world/ModelCharacter";
import { consumeTap, isDown, moveAxis } from "../input";
import { shared, addShake, raiseAlarm, addImpact, type TrafficCar, type Body, type Cop } from "../shared";
import { useGame } from "../store";
import { useStats } from "../game";
import { sfx } from "../audio/sfx";

const WALK_SPEED = 6.5;
const ENTER_RADIUS = 4.5;

export function Player() {
  const body = useRef<RapierRigidBody>(null);
  const mesh = useRef<THREE.Group>(null);
  const playerTint = useGame((s) => s.playerTint);
  const armed = useGame((s) => s.armed);

  useEffect(() => {
    shared.player = body.current;
    return () => {
      shared.player = null;
    };
  }, []);

  useFrame((_, dt) => {
    const rb = body.current;
    if (!rb) return;
    const game = useGame.getState();
    // hide the body in first-person, and while driving
    if (mesh.current) mesh.current.visible = game.mode === "foot" && game.view !== "first";
    if (game.paused) return; // frozen in the pause menu
    if (game.mode === "car") return; // disabled while driving

    const ax = moveAxis();
    const yaw = shared.camYaw;
    const fwd = new THREE.Vector3(Math.sin(yaw), 0, Math.cos(yaw));
    const right = new THREE.Vector3(fwd.z, 0, -fwd.x);
    const dir = new THREE.Vector3()
      .addScaledVector(fwd, ax.y)
      .addScaledVector(right, -ax.x); // A/D inverted for on-foot strafing

    const v = rb.linvel();
    const moving = dir.lengthSq() > 1e-4;
    // sprint (Shift) drains stamina; it regens when not sprinting
    const wantSprint = moving && (isDown("ShiftLeft") || isDown("ShiftRight")) && shared.stamina > 1;
    shared.stamina = THREE.MathUtils.clamp(shared.stamina + (wantSprint ? -28 : 18) * dt, 0, 100);
    const speed = wantSprint ? WALK_SPEED * 1.7 : WALK_SPEED;
    if (moving) {
      dir.normalize();
      rb.setLinvel({ x: dir.x * speed, y: v.y, z: dir.z * speed }, true);
      shared.heading = Math.atan2(dir.x, dir.z);
    } else {
      rb.setLinvel({ x: 0, y: v.y, z: 0 }, true);
    }
    if (mesh.current) mesh.current.rotation.y = shared.heading;

    // proximity to a car + enter / carjack
    {
      const p = rb.translation();
      // nearest carjackable traffic car
      let tj: TrafficCar | null = null;
      let tjD = ENTER_RADIUS;
      for (const tc of shared.traffic) {
        if (tc.stolen) continue;
        const d = Math.hypot(tc.pos.x - p.x, tc.pos.z - p.z);
        if (d < tjD) { tjD = d; tj = tc; }
      }
      // distance to the player's own parked car
      const car = shared.car;
      let ownD = Infinity;
      if (car) { const c = car.translation(); ownD = Math.hypot(p.x - c.x, p.z - c.z); }

      const near = !!tj || ownD < ENTER_RADIUS;
      game.setNearCar(near);
      if (near && consumeTap("KeyE")) {
        if (tj && tjD <= ownD) {
          // carjack: drag the driver out, take their ride
          useGame.getState().setPlayerCar(tj.type, tj.color);
          if (car) {
            car.setTranslation({ x: tj.pos.x, y: 1.4, z: tj.pos.z }, true);
            car.setLinvel({ x: 0, y: 0, z: 0 }, true);
            car.setRotation({ x: 0, y: Math.sin(tj.yaw / 2), z: 0, w: Math.cos(tj.yaw / 2) }, true);
          }
          shared.carYaw = tj.yaw;
          tj.stolen = true;
          addShake(0.4);
          useStats.getState().heat(0.8, 0.4); // carjacking draws heat
        } else {
          useStats.getState().heat(0.5, 0); // grand theft auto (own ride)
        }
        rb.setEnabled(false);
        game.setNearCar(false);
        game.setMode("car");
      }
    }

    // melee: punch the nearest pedestrian in front (F)
    if (consumeTap("KeyF")) {
      const p = rb.translation();
      const fx = Math.sin(shared.heading), fz = Math.cos(shared.heading);
      let best: (typeof shared.peds)[number] | null = null;
      let bestD = 2.0;
      for (const ped of shared.peds) {
        const dx = ped.pos.x - p.x, dz = ped.pos.z - p.z;
        const dd = Math.hypot(dx, dz) || 1;
        if (dd < bestD && (dx * fx + dz * fz) / dd > 0.25) { best = ped; bestD = dd; }
      }
      if (best) {
        best.hit += 1;
        const ax = best.pos.x - p.x, az = best.pos.z - p.z;
        const m = Math.hypot(ax, az) || 1;
        best.push.x += ax / m; best.push.z += az / m;
        useStats.getState().heat(0.4, 0.9); // assault draws police + faction heat
        addShake(0.5); // impact juice
        addImpact(new THREE.Vector3(best.pos.x, 1.1, best.pos.z), "#9a2a2a");
        raiseAlarm(p.x, p.z, 5);
      }
      sfx.punch();
    }

    // gunplay: fire the pistol when armed (left-click / Space) along the aim yaw
    if (armed && !game.mapOpen && !game.charOpen && (consumeTap("Mouse0") || consumeTap("Space"))) {
      const p = rb.translation();
      const aim = shared.camYaw;
      const fx = Math.sin(aim), fz = Math.cos(aim);
      const from = new THREE.Vector3(p.x + fx * 0.6, p.y + 0.4, p.z + fz * 0.6);
      const RANGE = 60;
      let bestT = RANGE;
      let bestPed: Body | null = null;
      let bestCop: Cop | null = null;
      for (const ped of shared.peds) {
        const dx = ped.pos.x - p.x, dz = ped.pos.z - p.z;
        const along = dx * fx + dz * fz;
        if (along <= 0 || along > RANGE) continue;
        if (Math.abs(dx * fz - dz * fx) < 1.4 && along < bestT) { bestT = along; bestPed = ped; bestCop = null; }
      }
      for (const cop of shared.cops) {
        if (cop.dead) continue;
        const dx = cop.pos.x - p.x, dz = cop.pos.z - p.z;
        const along = dx * fx + dz * fz;
        if (along <= 0 || along > RANGE) continue;
        if (Math.abs(dx * fz - dz * fx) < 2.2 && along < bestT) { bestT = along; bestCop = cop; bestPed = null; }
      }
      const to = new THREE.Vector3();
      if (bestPed) { bestPed.hit += 2; to.set(bestPed.pos.x, p.y + 0.4, bestPed.pos.z); addImpact(to, "#8a1414"); }
      else if (bestCop) { bestCop.dmg += 1; to.set(bestCop.pos.x, p.y + 0.4, bestCop.pos.z); addImpact(to, "#8a1414"); }
      else to.set(p.x + fx * bestT, p.y + 0.4, p.z + fz * bestT);
      shared.shots.push({ from, to, life: 0.06 });
      addShake(0.3);
      useStats.getState().heat(0.7, 0.6);
      raiseAlarm(p.x, p.z, 6); // gunfire scatters the crowd
      sfx.gun();
    }
  });

  return (
    <RigidBody
      ref={body}
      colliders={false}
      enabledRotations={[false, false, false]}
      position={[-256.2, 3, 106.5]}
      friction={0.6}
      linearDamping={0.2}
      mass={1}
    >
      <CapsuleCollider args={[0.5, 0.4]} />
      <group ref={mesh}>
        {/* rigged human; feet at local 0, so drop by the capsule half-height */}
        <group position={[0, -0.9, 0]}>
          <ModelCharacter
            tint={playerTint}
            moving={() => {
              const v = body.current?.linvel();
              return !!v && Math.hypot(v.x, v.z) > 0.6;
            }}
          />
          {/* pistol in hand when armed */}
          {armed && (
            <group position={[0.28, 1.0, 0.25]}>
              <mesh castShadow>
                <boxGeometry args={[0.08, 0.12, 0.28]} />
                <meshStandardMaterial color="#1a1a1d" roughness={0.5} metalness={0.6} />
              </mesh>
            </group>
          )}
        </group>
      </group>
    </RigidBody>
  );
}
